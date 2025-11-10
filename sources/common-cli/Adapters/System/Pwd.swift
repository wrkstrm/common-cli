import CommonProcess
import CommonShell

/// Print the current working directory via the `pwd` tool.
public struct Pwd: CLI {
  public static let executable: Executable = .name("pwd")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func printWorkingDirectory() async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: [])
  }
}

extension CommonShell { public var pwd: Pwd { .init(shell: self) } }
