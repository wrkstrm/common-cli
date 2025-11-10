import CommonProcess
import CommonShell

public struct Du: CLI {
  public static let executable: Executable = .name("du")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let humanReadable = Options(rawValue: 1 << 0)  // -h
    public static let summarize = Options(rawValue: 1 << 1)  // -s
  }

  public func size(of path: String, options: Options = [.humanReadable, .summarize]) async throws
    -> String
  {
    var args: [String] = []
    if options.contains(.humanReadable) { args.append("-h") }
    if options.contains(.summarize) { args.append("-s") }
    args.append(path)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var du: Du { .init(shell: self) } }
