#if false
import CommonShell
import Foundation

public struct PwdNativeSpec: ExecutableSpec {
  public let tool: String = "pwd-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

/// Native PWD that returns the CommonShell workingDirectory without spawning a process.
public struct PwdNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("pwd-native")
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

  public func printWorkingDirectory() async throws -> String {
    return shell.workingDirectory + "\n"
  }
}

extension CommonShell { public var pwdNative: PwdNative { .init(shell: self) } }
#endif
