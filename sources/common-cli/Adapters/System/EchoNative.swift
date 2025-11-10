#if false
import CommonShell
import Foundation

public struct EchoNativeSpec: ExecutableSpec {
  // Marker tool name to indicate native behavior; not executed.
  public let tool: String = "echo-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

/// A native echo that avoids subprocess dispatch and simulates `/bin/echo` output.
public struct EchoNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("echo-native")
  public var shell: CommonShell

  public init(shell: CommonShell) { self.shell = shell }

  private enum CodingKeys: String, CodingKey { case shell }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let s = try c.decode(CommonShell.self, forKey: .shell)
    self.init(shell: s)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(shell, forKey: .shell)
  }

  /// Echo the provided string and return standard output with a trailing newline, matching `/bin/echo`.
  @discardableResult
  public func echo(_ string: String) async throws -> String {
    // Keep behavior simple and predictable: append a single trailing newline.
    return string + "\n"
  }

  /// Echo directly to stdout without capturing, for parity with typical CLI behavior.
  public func echoToStdout(_ string: String) async throws {
    if let data = (string + "\n").data(using: .utf8) {
      try FileHandle.standardOutput.write(contentsOf: data)
    }
  }
}

extension CommonShell { public var echoNative: EchoNative { .init(shell: self) } }
#endif
