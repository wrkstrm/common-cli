import CommonProcess
import CommonShell

public struct Swiftlint: CLI, Versioned {
  public static let executable: Executable = .name("swiftlint")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func lint(path: String? = nil) async throws -> String {
    var args: [String] = []
    if let p = path { args.append(p) }
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var swiftlint: Swiftlint { .init(shell: self) } }
