import CommonProcess
import CommonShell

/// Query user and group identity via the `id` tool.
public struct Id: CLI {
  public static let executable: Executable = .name("id")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func whoami() async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: [])
  }
  public func user(_ user: String) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: [user])
  }
}

extension CommonShell { public var id: Id { .init(shell: self) } }
