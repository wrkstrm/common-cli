import CommonProcess
import CommonShell

/// Read target of a symbolic link via the `readlink` tool.
public struct Readlink: CLI {
  public static let executable: Executable = .name("readlink")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    // Canonicalize by following all symlinks, resolving to an absolute path (-f)
    public static let canonicalize = Options(rawValue: 1 << 0)
  }

  public func read(path: String, options: Options = [.canonicalize]) async throws -> String {
    var args: [String] = []
    if options.contains(.canonicalize) { args.append("-f") }
    args.append(path)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var readlink: Readlink { .init(shell: self) } }
