import CommonProcess
import CommonShell

/// Copy files and directories via the `cp` tool.
///
/// Provides convenience for common flags like `-R` (recursive) and `-f` (force).
public struct Cp: CLI {
  public static let executable: Executable = .name("cp")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let recursive = Options(rawValue: 1 << 0)  // -R
    public static let force = Options(rawValue: 1 << 1)  // -f
  }

  public func copy(from: String, to: String, options: Options = []) async throws -> String {
    var args: [String] = []
    if options.contains(.recursive) { args.append("-R") }
    if options.contains(.force) { args.append("-f") }
    args.append(contentsOf: [from, to])
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var cp: Cp { .init(shell: self) } }
