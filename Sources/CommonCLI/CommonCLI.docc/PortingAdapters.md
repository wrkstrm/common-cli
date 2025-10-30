# Porting Adapters to CommonShell

CommonCLI adapters now bind tools by configuring a `CommonShell` with the tool’s
`Executable` and preferred host, then invoking `runConfigured` or
`launchConfigured`. This keeps the caller’s shell context (working directory,
logging, instrumentation) intact while making the adapter’s defaults explicit.

## Steps

1. Describe the tool’s identity

```swift
public struct Git: CLI {
  public static let executable: Executable = .name("git")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }
}
```

2. Forward commands through the configured shell

```swift
public extension Git {
  func run(_ args: [String]) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  func status(porcelain: Bool = true) async throws -> String {
    var args = ["status"]
    if porcelain { args.append("--porcelain") }
    return try await run(args)
  }
}
```

### Wrapper/host selection

`runConfigured` automatically picks the preferred host (`.env` for named
tools, `.direct` for absolute paths) via `CommonShell.preferredHost(for:)`. If a
different wrapper is needed, pass the `host:` parameter explicitly.

### Example

```swift
let shell = CommonShell()
let git = Git(shell: shell)
let output = try await git.status()
print(output)
```

This replaces the older `ExecutableSpec`/`CommandRoute` approach; adapters now
own their executable identity directly and call the unified helpers.

## Abstraction levels

- Level 0 — creating a process: use CommonProcess runners and CommandSpec directly.
- Level 1 — creating a shell: use CommonShell for convenience and consistent logging.
- Level 2 — creating native funcs: add tool-specific helpers in CommonCLI.
- Level 3 — enforcing type safety: define typed options/enums for CLI interactions.
- Level 4 — native alternatives that replicate CLI behavior: implement in-process functionality without spawning subprocesses.
