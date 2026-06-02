<!-- One focused change per PR. If the diff spans two unrelated concerns, split it. -->

## What

<!-- What does this change do? -->

## Why

<!-- Why is it needed? Link the issue it closes, e.g. Closes #123. -->

## How to verify

<!-- Commands or steps a reviewer can run. -->

```sh
swift build
swift test
```

## Checklist

- [ ] `swift build` and `swift test` pass.
- [ ] Changes build on Linux (`swift:6.0-jammy`) where applicable.
- [ ] `CHANGELOG.md` updated under `Unreleased` (or this change is docs/tests/config only).
- [ ] Commits follow Conventional Commits.
