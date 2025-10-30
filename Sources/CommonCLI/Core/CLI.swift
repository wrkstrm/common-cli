import CommonProcess
import CommonShell
import Foundation

/// A protocol for defining command-line interface (CLI) tools.
public protocol CLI {
  /// Identity and default options/arguments for the tool.
  static var executable: Executable { get }

  /// The shell instance used to execute CLI commands.
  var shell: CommonShell { get }

  /// Initializes a new instance of the CLI tool.
  ///
  /// - Parameter shell: The shell instance used for executing CLI commands.
  init(shell: CommonShell)
}

extension CLI {
  /// Bind a shell to this CLI’s executable, picking an appropriate host.
  /// - name → env host; path → direct host; none → shell host
  public static func mutatedShell(shell: CommonShell) -> CommonShell {
    var copy = shell
    copy.executable = Self.executable
    switch Self.executable.ref {
    case .path:
      copy.hostKind = .direct
    case .name:
      copy.hostKind = .env(options: [])
    case .none:
      copy.hostKind = .shell(options: [])
    }
    return copy
  }
}

/// Opt-in protocol for CLIs that support a version flag.
public protocol Versioned {
  func version() async throws -> String
}

/// Default `--version` helper for any CLI adapter that adopts `Versioned`.
extension Versioned where Self: CLI {
  public func version() async throws -> String {
    try await Self.mutatedShell(shell: shell).run(["--version"])
  }
}
