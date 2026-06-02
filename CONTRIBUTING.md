# Contributing to Stitcher

Thanks for your interest in Stitcher. This guide covers how to set up, the
conventions the project follows, and how to land a change.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting started

Stitcher is a single Swift package. You need a recent Swift toolchain
(Swift 6.0+, Xcode 16+ on Apple platforms). The package builds on macOS, iOS,
and Linux.

```sh
swift build
swift test
```

On Linux, the same commands run inside the `swift:6.0-jammy` container, which is
what CI uses.

## Conventions

- Dependencies are injected through initialisers. No force-unwrapping in shipping
  code. Errors carry a reason via `StitcherError`.
- Cross-platform: the core builds on macOS and Linux. Platform-specific imports
  are gated with `#if canImport(...)` (for example `FoundationNetworking`), never
  scattered `#if os(...)` through business logic.
- Tests use the Swift Testing framework and assert behaviour, not implementation.

Read the surrounding files before writing new code and match what is already
there. Consistency with existing code outranks personal preference.

## Commits

Commit messages follow Conventional Commits: `<type>(<scope>): summary`, lowercase
type, imperative mood, no trailing period, first line under 72 characters. Types:
`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`.

## Branches

Branch from the current tip of `main`:

```sh
git fetch origin main && git checkout -b feat/<topic> origin/main
```

Naming: `fix/<issue>-<topic>`, `feat/<topic>`, `chore/<topic>`, `docs/<topic>`,
`refactor/<topic>`.

## Pull requests

- One focused change per PR. If the diff spans two unrelated concerns, split it.
- Add a `CHANGELOG.md` entry under `Unreleased` for any change that touches
  shipping source. Docs, tests, and config changes do not need an entry.
- Run `swift build` and `swift test` and confirm both pass before opening the PR.
- Do a self-review pass on your own diff and fix what a reviewer would flag.

## Issues

For bugs, file an issue first using the bug form, then branch with the issue
number in the name. The issue is the durable record of symptom, reproduction, and
acceptance criteria. For features, an issue is recommended when the scope is
non-trivial.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
