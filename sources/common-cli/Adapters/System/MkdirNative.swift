#if false
import CommonShell
import Foundation

public struct MkdirNativeSpec: ExecutableSpec {
  public let tool: String = "mkdir-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

public struct MkdirNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("mkdir-native")
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

  @discardableResult
  public func createDirectory(at path: String, options: Mkdir.Options = [.parents]) async throws
    -> String
  {
    let fm = FileManager.default
    var isDir: ObjCBool = false
    if fm.fileExists(atPath: path, isDirectory: &isDir) {
      if options.contains(.parents) && isDir.boolValue { return "" }
      throw NSError(
        domain: "MkdirNative", code: 17,
        userInfo: [NSLocalizedDescriptionKey: "File exists: \(path)"])
    }
    try fm.createDirectory(
      atPath: path, withIntermediateDirectories: options.contains(.parents), attributes: nil)
    return ""
  }
}

extension CommonShell { public var mkdirNative: MkdirNative { .init(shell: self) } }
#endif
