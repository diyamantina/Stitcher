// Stitcher - Multi-file OpenAPI $ref resolution

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import PureYAML

/// Stitches multi-file OpenAPI specs into a single document.
/// Resolves external $refs from local files and network URLs.
public actor Stitcher {
    private var cache: [String: PureYAML.Model.Value] = [:]
    private var resolving: Set<String> = []

    public init() {}

    /// Stitch a spec from a file path
    public func stitch(from path: String) async throws -> String {
        let url = URL(fileURLWithPath: path)
        return try await stitch(from: url)
    }

    /// Stitch a spec from a URL (file or network)
    public func stitch(from url: URL) async throws -> String {
        let content = try await fetchContent(from: url)
        let resolved = try await resolveDocument(content: content, baseURL: url)
        return serializeToYAML(resolved)
    }

    /// Stitch a spec from raw YAML/JSON content
    public func stitch(content: String, baseURL: URL? = nil) async throws -> String {
        let base = baseURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let resolved = try await resolveDocument(content: content, baseURL: base)
        return serializeToYAML(resolved)
    }

    /// Clear the resolution cache
    public func clearCache() {
        cache.removeAll()
        resolving.removeAll()
    }

    // MARK: - Document Resolution

    private func resolveDocument(content: String, baseURL: URL) async throws -> PureYAML.Model.Value {
        let parsed = try parse(content, failureMessage: "Failed to parse YAML")
        return try await resolveValue(parsed, baseURL: baseURL)
    }

    private func resolveValue(_ value: PureYAML.Model.Value, baseURL: URL) async throws -> PureYAML.Model.Value {
        // Extract the associated value through a non-async accessor before
        // suspending. Binding an enum payload across the `await` in a
        // `switch` trips a coroutine-splitting codegen crash in the Swift
        // 6.2 compiler; this if-let form avoids it.
        if let mapping = value.asMapping {
            return try await resolveMapping(mapping, baseURL: baseURL)
        }
        if let values = value.asSequence {
            return try await resolveSequence(values, baseURL: baseURL)
        }
        return value
    }

    private func resolveMapping(_ mapping: PureYAML.Model.Mapping, baseURL: URL) async throws -> PureYAML.Model.Value {
        if case let .string(ref)? = mapping["$ref"] {
            // Internal ref (same document) - keep as is
            if ref.hasPrefix("#") {
                return .mapping(mapping)
            }
            // External ref - resolve it
            return try await resolveExternalRef(ref, baseURL: baseURL, originalMapping: mapping)
        }

        // Not a $ref - recursively resolve all values, preserving order
        var pairs: [PureYAML.Model.Pair] = []
        for pair in mapping.pairs {
            let resolved = try await resolveValue(pair.value, baseURL: baseURL)
            pairs.append(PureYAML.Model.Pair(keyNode: pair.keyNode, value: resolved))
        }
        return .mapping(PureYAML.Model.Mapping(pairs))
    }

    private func resolveSequence(_ values: [PureYAML.Model.Value], baseURL: URL) async throws -> PureYAML.Model.Value {
        var result: [PureYAML.Model.Value] = []
        for item in values {
            result.append(try await resolveValue(item, baseURL: baseURL))
        }
        return .sequence(result)
    }

    private func resolveExternalRef(
        _ ref: String,
        baseURL: URL,
        originalMapping: PureYAML.Model.Mapping
    ) async throws -> PureYAML.Model.Value {
        let parts = ref.components(separatedBy: "#")
        let filePath = parts[0]
        let jsonPointer = parts.count > 1 ? "#" + parts[1] : nil

        let resolvedURL = resolveURL(filePath, relativeTo: baseURL)
        let cacheKey = resolvedURL.absoluteString

        // Check for circular references
        if resolving.contains(cacheKey) {
            throw StitcherError.circularReference(ref)
        }

        // Check cache
        if let cached = cache[cacheKey] {
            return try extractWithPointer(from: cached, pointer: jsonPointer, originalMapping: originalMapping)
        }

        // Mark as resolving
        resolving.insert(cacheKey)
        defer { resolving.remove(cacheKey) }

        // Fetch and parse the referenced file
        let content = try await fetchContent(from: resolvedURL)
        let parsed = try parse(content, failureMessage: "Failed to parse: \(resolvedURL)")

        // Recursively resolve refs in the fetched content
        let resolved = try await resolveValue(parsed, baseURL: resolvedURL)

        // Cache the resolved content
        cache[cacheKey] = resolved

        return try extractWithPointer(from: resolved, pointer: jsonPointer, originalMapping: originalMapping)
    }

    private func extractWithPointer(
        from value: PureYAML.Model.Value,
        pointer: String?,
        originalMapping: PureYAML.Model.Mapping
    ) throws -> PureYAML.Model.Value {
        var result = value

        if let pointer, pointer != "#" {
            result = try navigateJSONPointer(value, pointer: pointer)
        }

        // If the result is anything but a mapping, return as-is
        guard case let .mapping(mapping) = result else {
            return result
        }

        // Merge any additional properties from the original mapping (except $ref)
        var pairs = mapping.pairs
        let presentKeys = Set(mapping.pairs.compactMap(\.keyNode.stringValue))
        for pair in originalMapping.pairs {
            guard let key = pair.keyNode.stringValue, key != "$ref" else { continue }
            if !presentKeys.contains(key) {
                pairs.append(pair)
            }
        }

        return .mapping(PureYAML.Model.Mapping(pairs))
    }

    private func navigateJSONPointer(_ value: PureYAML.Model.Value, pointer: String) throws -> PureYAML.Model.Value {
        var path = pointer
        if path.hasPrefix("#") {
            path = String(path.dropFirst())
        }
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }

        if path.isEmpty {
            return value
        }

        // Split and decode JSON pointer escapes
        let components = path.components(separatedBy: "/").map { component in
            component
                .replacingOccurrences(of: "~1", with: "/")
                .replacingOccurrences(of: "~0", with: "~")
        }

        var current = value
        for component in components {
            switch current {
            case let .mapping(mapping):
                guard let next = mapping[component] else {
                    throw StitcherError.refNotFound(pointer)
                }
                current = next
            case let .sequence(values):
                guard let index = Int(component), index >= 0, index < values.count else {
                    throw StitcherError.refNotFound(pointer)
                }
                current = values[index]
            default:
                throw StitcherError.refNotFound(pointer)
            }
        }

        return current
    }

    // MARK: - Fetching

    private func fetchContent(from url: URL) async throws -> String {
        if url.isFileURL {
            return try String(contentsOf: url, encoding: .utf8)
        }
        #if canImport(Darwin) || canImport(FoundationNetworking)
        let (data, response) = try await fetchData(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StitcherError.fetchFailed(url)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw StitcherError.invalidEncoding(url)
        }

        return text
        #else
        // URLSession is unavailable on platforms without FoundationNetworking
        // (notably wasm32-wasi). Remote `$ref` fetching is the embedding host's
        // responsibility there; local file and in-memory stitching still work.
        throw StitcherError.networkingUnavailable(url)
        #endif
    }

    #if canImport(Darwin) || canImport(FoundationNetworking)
    private func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: StitcherError.fetchFailed(url))
                }
            }
            task.resume()
        }
    }
    #endif

    private func resolveURL(_ ref: String, relativeTo base: URL) -> URL {
        if ref.hasPrefix("http://") || ref.hasPrefix("https://") {
            return URL(string: ref)!
        }

        let baseDir = base.deletingLastPathComponent()
        return baseDir.appendingPathComponent(ref).standardized
    }

    // MARK: - Parsing / Serialization

    /// Parse YAML into a value tree, mapping any parser failure to a
    /// ``StitcherError/parseError(_:)`` so callers see a stable error type.
    private func parse(_ content: String, failureMessage: String) throws -> PureYAML.Model.Value {
        do {
            return try PureYAML.parse(content)
        } catch {
            throw StitcherError.parseError(failureMessage)
        }
    }

    /// Emit the resolved document. Plain (unquoted) scalars are used
    /// wherever unambiguous, matching what Yams produced; PureYAML defaults
    /// to fully quoted scalars otherwise. Key order follows the document
    /// rather than being alphabetised.
    private func serializeToYAML(_ value: PureYAML.Model.Value) -> String {
        PureYAML.dump(value, options: PureYAML.Emitting.Options(scalarStyle: .plainWhenSafe))
    }
}

// MARK: - Value accessors

private extension PureYAML.Model.Value {
    var asMapping: PureYAML.Model.Mapping? {
        guard case let .mapping(mapping) = self else { return nil }
        return mapping
    }

    var asSequence: [PureYAML.Model.Value]? {
        guard case let .sequence(values) = self else { return nil }
        return values
    }
}

// MARK: - Errors

public enum StitcherError: Error, LocalizedError {
    case fetchFailed(URL)
    case invalidEncoding(URL)
    case parseError(String)
    case circularReference(String)
    case refNotFound(String)
    case networkingUnavailable(URL)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let url):
            return "Failed to fetch: \(url)"
        case .invalidEncoding(let url):
            return "Invalid encoding: \(url)"
        case .networkingUnavailable(let url):
            return "Remote fetching is unavailable on this platform: \(url)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .circularReference(let path):
            return "Circular reference: \(path)"
        case .refNotFound(let ref):
            return "Reference not found: \(ref)"
        }
    }
}
