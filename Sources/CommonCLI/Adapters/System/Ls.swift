import CommonProcess
import CommonShell

/// List directory contents via the `ls` tool.
public struct Ls: CLI {
  public static let executable: Executable = .name("ls")
  public var shell: CommonShell

  public init(shell: CommonShell) { self.shell = shell }

  public func list(directory: String? = nil, options: [String] = []) async throws -> String {
    var args = options
    if let dir = directory { args.append(dir) }
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var ls: Ls { .init(shell: self) } }
