# Changelog

All notable changes to Stitcher are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-06-23

### Changed

- Require PureYAML 0.1.4, which bounds parser nesting depth so a pathologically
  nested document fails with a diagnostic instead of overflowing the stack.

## [2.0.0] - 2026-06-23

### Changed

- Replace the Yams dependency with the pure-Swift
  [PureYAML](https://codeberg.org/Mihaela/PureYAML) parser/emitter. This removes
  the bundled libYaml C sources and lets Stitcher build for WebAssembly
  (`wasm32-wasip1`) in addition to macOS, Linux, and Windows.
- The resolver now operates on PureYAML's ordered value tree, so emitted YAML
  preserves document key order instead of alphabetising keys, and scalars are
  emitted plain where unambiguous.

### Added

- `StitcherError.networkingUnavailable(URL)`, thrown when a remote `$ref` is
  encountered on a platform without `URLSession` (for example `wasm32-wasi`),
  where the embedding host is expected to supply remote documents. Local file
  and in-memory stitching are unaffected.

## [1.1.2] - 2026-06-02

### Changed

- Documentation and changelog housekeeping. No functional changes.

## [1.1.1] - 2026-06-02

### Added

- Community health files: `LICENSE` (MIT), `CODE_OF_CONDUCT.md`,
  `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, a pull request template, and
  issue forms for bug reports and feature requests.

### Changed

- Split CI into separate `macOS` and `Linux` workflows, with per-platform status
  badges in the README. The Linux job runs on the `swift:6.0-jammy` container.

## [1.1.0] - 2026-06-02

### Changed

- Widened the Yams dependency range to `5.0.0 ..< 7.0.0` so the package resolves
  against Yams 6.x as well as 5.x.

## [1.0.0] - 2025-11-28

### Added

- Initial public release.
- Resolve external `$ref` references from local files and URLs.
- Handle nested references across multiple folders (`../core/schemas/`).
- Support JSON pointer syntax (`#/components/schemas/User`).
- Detect circular references and surface them via `StitcherError`.
- Cache resolved files for performance.
- Build and run on macOS, iOS, and Linux (`URLSession` gated behind
  `FoundationNetworking` on Linux).

## [0.1.0] - 2026-05-02

### Added

- README and documentation updates on top of the 1.0.0 feature set. Tagged out
  of semantic order; superseded by 1.1.0.

[1.1.2]: https://github.com/diyamantina/Stitcher/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/diyamantina/Stitcher/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/diyamantina/Stitcher/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/diyamantina/Stitcher/releases/tag/1.0.0
[0.1.0]: https://github.com/diyamantina/Stitcher/releases/tag/0.1.0
