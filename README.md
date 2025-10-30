# CommonCLI — typed CLI adapters on CommonShell

[![Swift CI (Linux)](https://github.com/wrkstrm/common-cli/actions/workflows/swift-ci.yml/badge.svg)](https://github.com/wrkstrm/common-cli/actions/workflows/swift-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

CommonCLI provides small, typed adapters for common command‑line tools (git, rsync,
system utilities), built on the CommonShell + CommonProcess execution layer.

- Typed wrappers for frequently used tools (Git, rsync, chmod, etc.)
- Consistent logging, preview, and runner selection via CommonShell
- Cross‑platform support mirroring CommonProcess targets

## Quickstart

Add to your Package.swift dependencies:

```swift
// Prefer released tags
.package(url: "https://github.com/wrkstrm/common-cli.git", from: "0.1.0")

// Or track main during development
// .package(url: "https://github.com/wrkstrm/common-cli.git", branch: "main")
```

Then import and use an adapter:

```swift
import CommonCLI
import CommonShell

// Git example
await {
  var shell = CommonShell(executable: .name("git"))
  let git = Git(shell: shell)
  let log = try await git.log(format: "%h %s", reverse: false)
  print(log)
}()

// System echo example
await {
  var shell = CommonShell(executable: .path("/bin/echo"))
  let echoed = try await shell.run(["hello"]).trimmingCharacters(in: .whitespacesAndNewlines)
  print(echoed) // "hello"
}()
```

## Platforms

- macOS 14+
- iOS 17+
- Mac Catalyst 17+

CommonCLI mirrors platform support from CommonProcess/CommonShell.

## Dependencies

- CommonShell (>= 0.1.0)
- CommonProcess (>= 0.2.0)
- Apple Swift Argument Parser (transitive)

## Docs

- API surface documented via inline comments; DocC workflows mirror CommonProcess/CommonShell

## CI

- Linux CI: swift‑ci (build + test)
- Format lint and DocC Pages workflows included

## Contributing

See CONTRIBUTING.md. Use CommonShell/CommonProcess for all subprocess execution and
prefer typed options/enums over raw strings.

## Security

Report vulnerabilities through GitHub Security Advisories (see SECURITY.md).

## License

MIT — see LICENSE.

## Changelog

See CHANGELOG.md.
