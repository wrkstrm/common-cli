import CommonProcess
import CommonShell
import Foundation

/// Wrapper for `swiftc` compiler with a simple compile helper.
public struct Swiftc: CLI {
  public static let executable: Executable = .name("swiftc")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  /// Compile a Swift source file to the given output path.
  public func compile(source: String, output: String, extra: [String] = []) async throws -> String {
    var args = [source, "-o", output]
    args.append(contentsOf: extra)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var swiftc: Swiftc { .init(shell: self) } }
