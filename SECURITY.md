# Security Policy

## Reporting a vulnerability

If you believe you have found a security issue in Stitcher, please report it
privately. Do not open a public issue for security problems.

Email **mihaelamj@gmail.com** with:

- A description of the issue and its impact.
- Steps to reproduce, or a proof of concept.
- The affected version or commit.

You can expect an acknowledgement within a few days. Once the issue is confirmed,
a fix will be prepared and a release cut, after which the issue can be disclosed
publicly with credit to the reporter if desired.

## Supported versions

Security fixes are applied to the `main` branch and shipped in the latest release.
Only the most recent release line is supported.

## Scope

Stitcher resolves external `$ref` references in OpenAPI specs and inlines them
into a single document. It reads files from the local filesystem and fetches
content over the network when a `$ref` resolves to a URL. Reports about how
references are resolved are in scope, for example:

- Path traversal that lets a `$ref` read files outside the intended spec
  directory.
- Server-side request forgery via crafted remote `$ref` URLs.
- Uncaught parsing failures that crash the host process on malformed input.
