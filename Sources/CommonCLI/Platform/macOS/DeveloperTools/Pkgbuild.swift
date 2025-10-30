import CommonProcess
import CommonShell

/// Minimal wrapper for `/usr/bin/pkgbuild` (macOS).
public struct Pkgbuild: CLI {
  public static let executable: Executable = .path("/usr/bin/pkgbuild")
  public var shell: CommonShell
  public init(shell: CommonShell) {
    self.shell = Self.mutatedShell(shell: shell)
    // direct mode
  }

  public func build(
    componentPath: String, identifier: String, version: String, installLocation: String,
    output: String, scripts: String? = nil,
  ) async throws -> String {
    var args: [String] = [
      "--root", componentPath,
      "--identifier", identifier,
      "--version", version,
      "--install-location", installLocation,
      "--component-plist", "/dev/null",  // optional; keep minimal
      "--quiet",
      output,
    ]
    if let scripts { args.insert(contentsOf: ["--scripts", scripts], at: 0) }
    return try await shell.run(args)
  }
}

extension CommonShell { public var pkgbuild: Pkgbuild { .init(shell: self) } }
