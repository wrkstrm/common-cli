import CommonProcess
import CommonShell

public struct Touch: CLI {
  public static let executable: Executable = .name("touch")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  @discardableResult
  public func create(at path: String, createParents: Bool = false) async throws -> String {
    var args: [String] = []
    // Keep minimal; placeholder for extended options.
    if createParents { args.append("-t") }
    args.append(path)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var touch: Touch { .init(shell: self) } }
