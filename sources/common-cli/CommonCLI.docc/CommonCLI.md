# `CommonCLI`

CommonCLI is a lightweight set of async wrappers built on top of `CommonShell`.
It exposes a small, composable API for common developer tools (git, swift,
rsync, ls, cp, etc.), plus convenience helpers for logging.

## Overview

- Module: `CommonCLI`
- Depends on: `CommonShell`
- Platforms: macOS + Linux (some adapters like `Pkgbuild` and `Sdef` are macOS‑only)

### Install

Add the package and depend on the `CommonCLI` product.

```swift
// Package.swift
.dependencies: [
  .package(name: "CommonShell", path: "path/to/CommonShell")
],
.targets: [
  .executableTarget(
    name: "my-cli",
    dependencies: [
      .product(name: "CommonCLI", package: "CommonShell"),
      .product(name: "CommonShell", package: "CommonShell"),
    ]
  )
]
```

### Configure Logging (Optional)

```swift
import CommonCLI
// Strings: silent|error|warn|warning|info|debug|verbose
ShellLogging.configureLogging(from: ProcessInfo.processInfo.environment["LOG_LEVEL"]) // or .configureLogging(level:)
```

### Usage Pattern

Every adapter is a tiny wrapper around `CommonShell`. Start from a base shell
and prefer adapter methods for clarity:

```swift
import CommonShell
import CommonCLI

var base = CommonShell(
  executable: Executable.path("/usr/bin/env"),
  logOptions: .init(exposure: .verbose)
)
base.workingDirectory = "/path/to/repo"

// Git example
let log = try await base.git.log(format: "%h %s", reverse: false)
print(log)

// Core utils
let output = try await base.ls.list(directory: ".", options: ["-la"])
_ = try await base.mkdir.createDirectory(at: "Build/Artifacts")
```

All APIs are async and return `String` stdout (they throw on non‑zero exit).

### CLI Protocol (Identity)

CommonCLI adapters declare a static executable that identifies the tool and any default prefixes:

```swift
import CommonProcess
import CommonShell
import CommonCLI

public struct SwiftTool: CLI, Versioned {
  public static let executable: Executable = .name("swift")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = Self.mutatedShell(shell: shell) }
}
```

- Host mapping defaults: `.path` → direct, `.name` → env, `.none` → shell.
- You can override per call with `bind(route:)` or by passing an explicit host to `CommonShell.run`.

### Abstraction Levels

- Level 0 — creating a process: use CommonProcess runners and CommandSpec directly.
- Level 1 — creating a shell: use CommonShell for convenience and consistent logging.
- Level 2 — creating native funcs: add tool-specific helpers in CommonCLI.
- Level 3 — enforcing type safety: define typed options/enums for CLI interactions.
- Level 4 — native alternatives that replicate CLI behavior: implement in-process functionality without spawning subprocesses.

#### Type Safety And Autonomy

- Strongly typed options reduce invalid command surfaces, improving safety for
  automated agents.
- Validations in option types catch conflicts and missing requirements before a
  subprocess is spawned.
- Structured commands are easier to log and audit, supporting policy gates
  for unattended runs.

## Topics

### Git Helpers

- ``Git``

```swift
let shell = CommonShell(
  workingDirectory: "/repo",
  executable: Executable.path("/usr/bin/env"),
  logOptions: .init(exposure: .verbose)
)

// Status + current branch
print(try await shell.git.status())
print(try await shell.git.currentBranch())

// Branch ops
_ = try await shell.git.createBranch("feature/x", checkout: true)
print(try await shell.git.branches(all: true))

// Tag ops
_ = try await shell.git.createTag("v1.2.3", annotated: true, message: "Release 1.2.3")
print(try await shell.git.tags())

// Network
_ = try await shell.git.fetch(prune: true)
_ = try await shell.git.pull(rebase: true)
_ = try await shell.git.push(setUpstream: true)

// Remotes
_ = try await shell.git.remoteAdd(name: "origin", url: "git@github.com:org/repo.git")
print(try await shell.git.remotes(verbose: true))

// History
_ = try await shell.git.merge("main", noFF: true, message: "Merge main")
_ = try await shell.git.cherryPick("abc1234", noCommit: true)
_ = try await shell.git.revert("def5678")

// Stash
print(try await shell.git.stashList())
_ = try await shell.git.stashApply() // latest
```

### SwiftPM Helpers

- ``SwiftTool``

```swift
let swift = shell.swift
_ = try await swift.packageInit(type: "executable", name: "tool")
_ = try await swift.packageResolve()
_ = try await swift.packageUpdate()
print(try await swift.packageShowDependencies(format: "json"))
print(try await swift.packageDumpManifest())

// Build/Test/Run
_ = try await swift.build(["--configuration", "release"])
print(try await swift.test(filter: "MyTests/", enableCodeCoverage: true))
print(try await swift.runExecutable(product: "tool", args: ["--help"]))

// Swift compiler
_ = try await shell.swiftc.compile(source: "main.swift", output: ".build/out")
```

### Core Utils

- ``Ls``
- ``Mkdir``
- ``Cp``
- ``Cat``
- ``Readlink``
- ``Rm``
- ``Rsync``
- ``Du``
- ``Touch``

```swift
_ = try await shell.mkdir.createDirectory(at: "dist", parents: true)
print(try await shell.ls.list(directory: "dist", options: ["-la"]))
_ = try await shell.cp.copy(from: "README.md", to: "dist/README.md", options: [.force])
print(try await shell.readlink.read(path: "/usr/bin/env"))
_ = try await shell.rsync.sync(from: "Resources/", to: "dist/Resources/", archive: true, delete: true)
print(try await shell.du.size(of: "dist"))
```

### GitHub CLI

- ``Gh``

```swift
import CommonCLI
import CommonShell

let gh = Gh(shell: CommonShell(executable: .name("gh")))
let longBody = "…long text…\n\nRefs: …"
// Create an issue without labels (labels can be added later if they don't exist)
_ = try await gh.issueCreate(title: "WrkstrmLog CI: pin tests to 1 worker (temporary)",
                             body: longBody,
                             labels: [])

// Optional label workflow (requires permissions)
_ = try await gh.labelCreate(name: "tests", color: "5319e7", description: "Test-related work")
_ = try await gh.issueAddLabels(number: "80", labels: ["tests"]) // add to issue #80
```

### macOS‑only Helpers

- ``XcodeBuild``
- ``Sdef``
- ``Pkgbuild``

```swift
// Xcode build (via xcodebuild)
print(try await shell.xcodebuild.listWorkspaceJSON("mono.xcworkspace"))

// sdef/pkgbuild
_ = try await shell.sdef.extract(from: "/Applications/Notes.app")
_ = try await shell.pkgbuild.build(
  componentPath: "Payload",
  identifier: "com.example.pkg",
  version: "1.0.0",
  installLocation: "/",
  output: "dist/example.pkg"
)
```

## Error Handling

On non‑zero exit, adapters throw. Surround calls with `do/catch` or use Swift
Testing/XCTest assertions for CI.

## Tips

- Prefer adapter methods for clarity; fall back to `CommonShell/run(arguments:)` when needed
- Use `logOptions.exposure = .verbose` locally to see rich logs; default to `.summary` in CI
- Use `CommonArguments` to parse `--working-directory` and `--verbose` in your CLI

## Roadmap

See AGENDA.md → “CommonCLI next steps” for planned additions (Git commit helpers,
worktree, sparse‑checkout; SwiftPM edit/pin/clean/reset; xcodebuild archive/export; tool shims).
