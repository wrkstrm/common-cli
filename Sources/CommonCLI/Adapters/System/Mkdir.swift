import CommonProcess
import CommonShell

/// Create directories via the `mkdir` tool with convenient `-p` support.
public struct Mkdir: CLI {
  public static let executable: Executable = .name("mkdir")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let parents = Options(rawValue: 1 << 0)  // -p
  }

  public func createDirectory(at path: String, options: Options = [.parents]) async throws -> String
  {
    var args: [String] = []
    if options.contains(.parents) { args.append("-p") }
    args.append(path)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var mkdir: Mkdir { .init(shell: self) } }
