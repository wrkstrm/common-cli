import CommonProcess
import CommonShell

/// Wrapper around the `chmod` executable with symbolic and recursive support.
public struct Chmod: CLI {
  public static let executable: Executable = .name("chmod")
  public var shell: CommonShell

  public init(shell: CommonShell) {
    self.shell = shell
  }

  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    /// Apply changes recursively via `-R`.
    public static let recursive = Options(rawValue: 1 << 0)
  }

  private func arguments(mode: String, paths: [String], options: Options) -> [String] {
    var args: [String] = []
    if options.contains(.recursive) { args.append("-R") }
    args.append(mode)
    args.append(contentsOf: paths)
    return args
  }

  /// Run `chmod` asynchronously using CommonShell defaults.
  @discardableResult
  public func apply(
    mode: String,
    to paths: [String],
    options: Options = [],
    runnerKind: ProcessRunnerKind? = nil
  ) async throws -> String {
    let args = arguments(mode: mode, paths: paths, options: options)
    return try await shell.runConfigured(
      executable: Self.executable, arguments: args, runnerKind: runnerKind)
  }

}

extension CommonShell { public var chmod: Chmod { .init(shell: self) } }

extension Chmod: @unchecked Sendable {}
