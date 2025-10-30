import CommonProcess
import CommonShell

/// Extracts AppleScript terminology (sdef) from applications via `/usr/bin/sdef`.
public struct Sdef: CLI {
  public static let executable: Executable = .path("/usr/bin/sdef")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func extract(from appPath: String) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: [appPath])
  }
}

extension CommonShell { public var sdef: Sdef { .init(shell: self) } }
