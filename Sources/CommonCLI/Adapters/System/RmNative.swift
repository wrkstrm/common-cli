#if false
import CommonShell
import Foundation

public struct RmNativeSpec: ExecutableSpec {
  public let tool: String = "rm-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

public struct RmNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("rm-native")
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
  public func remove(path: String, options: Rm.Options = []) async throws -> String {
    let fm = FileManager.default
    var isDir: ObjCBool = false
    let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
    if !exists {
      if options.contains(.force) { return "" }
      throw NSError(
        domain: "RmNative", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "No such file or directory: \(path)"])
    }
    if isDir.boolValue && !options.contains(.recursive) {
      // Require -d to remove a directory (and it must be empty).
      guard options.contains(.directoryOnly) else {
        throw NSError(
          domain: "RmNative", code: 66,
          userInfo: [NSLocalizedDescriptionKey: "Is a directory: \(path)"])
      }
      if let contents = try? fm.contentsOfDirectory(atPath: path), !contents.isEmpty {
        throw NSError(
          domain: "RmNative", code: 66,
          userInfo: [NSLocalizedDescriptionKey: "Directory not empty: \(path)"])
      }
    }
    do {
      try fm.removeItem(atPath: path)
    } catch {
      if !options.contains(.force) { throw error }
    }
    return ""
  }
}

extension CommonShell { public var rmNative: RmNative { .init(shell: self) } }
#endif
