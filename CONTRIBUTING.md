# Contributing to CommonCLI

Thanks for your interest in contributing!

## Development setup

- Swift toolchain: 6.1
- Platforms: Linux (CI) and macOS (local).
- Build: `swift build -c release`
- Test: `swift test --parallel`

## Coding guidelines

- Prefer typed adapters and options; avoid raw stringly APIs when possible.
- Use CommonShell/CommonProcess for process execution; do not use Foundation.Process directly.
- Run `swift format` using the repository configuration when present.
- Prefer explicit, descriptive identifiers.

## Dependencies

- Core: CommonProcess (from 0.2.0)
- Shell: CommonShell (from 0.1.0)

## Opening issues and PRs

- Include a concise summary and reproduction steps for bugs.
- For features, describe the use case and acceptance criteria.
- Keep PRs focused with clear rationale and tests where applicable.

## License and conduct

By contributing, you agree that your contributions will be licensed under the
MIT License (see `LICENSE`) and that you will abide by the `CODE_OF_CONDUCT.md`.

