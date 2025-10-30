# TODO — CommonCLI CommandSpec-first Migration

Owner: dev-tools
Priority: P1
Labels: common-cli, migration

## Tasks

- [ ] Replace `CommonShell.registerNativeHandler` with a CommonCLI-owned adapter/registry, or remove native bindings in favor of wrappers.
- [x] Update `CommonShell+Init` to use `Executable.name(cli)`; remove deprecated `executablePath:` initializer usage.
- [ ] Rename `ShellRunnerKind` → `ProcessRunnerKind`; update APIs and call sites to pass `runnerKind:` only.
- [x] Remove `NativeBoundSwiftShell`; adapters now call `runConfigured` directly (2025-09-19).
- [ ] Update Git adapters to call `BoundCommonShell.run(_:, runnerKind:)`; drop legacy wrapper/backend params.
- [ ] Sweep deprecated CommonShell initializers across cli-kit/clia; adopt ExecutableReference/Executable.
- [ ] Add tests for runConfigured helpers (runnerKind, npm/env).

### Launchctl CLI (macOS‑only)
<!-- id:common-cli-launchctl-exec owner:dev-tools priority:P1 labels:common-cli,launchctl,status:planned epic:system-scheduler estimate:2x7.5m -->
- [ ] Add dedicated `common-cli-launchctl` executable with subcommands:
  - [ ] `bootstrap` / `bootout` (domain + plist)
  - [ ] `kickstart` (domain/label, `--restart`)
  - [ ] `enable` / `disable` (domain/label)
  - [ ] `print` (domain or domain/label)
  - [ ] `version`
- [ ] Wire help text and examples; guard with `#if os(macOS)`.
- [ ] Smoke tests: print system domain; bogus label error; version non‑empty.

## Notes

- Keep wrappers/policy in CommonCLI/CommonShell; CommandSpec + Process* types come from CommonProcess.
- Subprocess bridges live in CommonProcessRunners via extensions.
