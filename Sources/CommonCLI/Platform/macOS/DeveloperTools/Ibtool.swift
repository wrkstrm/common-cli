import CommonProcess
import CommonShell

/// Interface Builder tool wrapper for extracting strings and other operations.
public struct Ibtool: CLI {
  public static let executable: Executable = .path("/usr/bin/ibtool")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func generateStrings(for assetPath: String, to stringsPath: String) async throws -> String
  {
    try await shell.runConfigured(
      executable: Self.executable, arguments: [assetPath, "--generate-strings-file", stringsPath]
    )
  }
}

extension CommonShell { public var ibtool: Ibtool { .init(shell: self) } }
