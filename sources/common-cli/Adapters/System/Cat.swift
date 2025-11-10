import CommonProcess
import CommonShell

/// Concatenate and print file contents via the `cat` tool.
public struct Cat: CLI {
  public static let executable: Executable = .name("cat")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func concatenate(files: [String]) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: files)
  }
}

extension CommonShell { public var cat: Cat { .init(shell: self) } }
