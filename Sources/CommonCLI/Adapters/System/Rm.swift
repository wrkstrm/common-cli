import CommonProcess
import CommonShell

/// Remove files or directories via the `rm` tool.
/// Supports options like recursive (`-r`), force (`-f`), and directory-only (`-d`).
public struct Rm: CLI {
  public static let executable: Executable = .name("rm")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let recursive = Options(rawValue: 1 << 0) // -r
    public static let force = Options(rawValue: 1 << 1) // -f
    // -d remove empty directories
    public static let directoryOnly = Options(rawValue: 1 << 2)
  }

  public func remove(path: String, options: Options = []) async throws -> String {
    var args: [String] = []
    if options.contains(.recursive) { args.append("-r") }
    if options.contains(.force) { args.append("-f") }
    if options.contains(.directoryOnly) { args.append("-d") }
    args.append(path)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var rm: Rm { .init(shell: self) } }

// MARK: - Typed CommandSpec builder

extension Rm {
  public static func rm(
    path: String,
    options: Options = [],
    workingDirectory: String
  ) -> CommandSpec {
    var args: [String] = []
    if options.contains(.recursive) { args.append("-r") }
    if options.contains(.force) { args.append("-f") }
    if options.contains(.directoryOnly) { args.append("-d") }
    args.append(path)
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }
}
