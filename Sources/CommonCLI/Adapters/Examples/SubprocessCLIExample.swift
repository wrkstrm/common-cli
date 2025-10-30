import CommonProcess
import CommonShell

/// Option 1: protocol based wrapper bridging to Subprocess.
public struct SubprocessCLIExample: CLI {
  /// Command and options used when spawning processes.
  public static let executable: Executable = .name("echo")

  /// Shell configured with boot information.
  public var shell: CommonShell

  /// Create a CLI wrapper using a base shell.
  public init(shell: CommonShell) {
    self.shell = Self.mutatedShell(shell: shell)
  }

  /// Run the configured executable with additional arguments.
  @discardableResult
  public func run(_ args: [String]) async throws -> String {
    try await shell.run(args)
  }
}
