import CommonProcess
import CommonShell

/// A simple CLI wrapping `/bin/echo` for demonstration and testing.
public struct Echo: CLI, Codable, Sendable {
  public static let executable: Executable = .path("/bin/echo")
  public var shell: CommonShell

  /// Initialize with a base shell.
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

  /// Echo the provided string and return standard output.
  @discardableResult
  public func echo(_ string: String) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: [string])
  }
}
