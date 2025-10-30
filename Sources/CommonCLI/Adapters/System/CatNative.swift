#if false
import CommonShell
import Foundation

public struct CatNativeSpec: ExecutableSpec {
  public let tool: String = "cat-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

public struct CatNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("cat-native")
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

  public func concatenate(files: [String]) async throws -> String {
    var out = Data()
    for path in files {
      let d = try Data(contentsOf: URL(fileURLWithPath: path))
      out.append(d)
    }
    return String(data: out, encoding: .utf8) ?? String(decoding: out, as: UTF8.self)
  }
}

extension CommonShell { public var catNative: CatNative { .init(shell: self) } }
#endif
