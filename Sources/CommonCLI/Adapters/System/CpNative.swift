#if false
import CommonShell
import Foundation

public struct CpNativeSpec: ExecutableSpec {
  public let tool: String = "cp-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

public struct CpNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("cp-native")
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
  public func copy(from: String, to: String, options: Cp.Options = []) async throws -> String {
    let fm = FileManager.default
    var isDirSrc: ObjCBool = false
    let existsSrc = fm.fileExists(atPath: from, isDirectory: &isDirSrc)
    guard existsSrc else {
      throw NSError(
        domain: "CpNative", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "No such file or directory: \(from)"])
    }

    var finalDest = to
    var isDirDest: ObjCBool = false
    if fm.fileExists(atPath: to, isDirectory: &isDirDest) {
      if isDirDest.boolValue {
        finalDest = (to as NSString).appendingPathComponent((from as NSString).lastPathComponent)
      } else {
        // BSD cp overwrites existing files by default; mimic by removing first.
        try? fm.removeItem(atPath: to)
      }
    }

    if isDirSrc.boolValue && !options.contains(.recursive) {
      // Tolerate platform differences; do not copy, do not throw.
      return ""
    }

    // Ensure parent directory exists
    let parent = (finalDest as NSString).deletingLastPathComponent
    if !parent.isEmpty && !fm.fileExists(atPath: parent, isDirectory: &isDirDest) {
      try fm.createDirectory(atPath: parent, withIntermediateDirectories: true)
    }
    try fm.copyItem(atPath: from, toPath: finalDest)
    return ""
  }
}

extension CommonShell { public var cpNative: CpNative { .init(shell: self) } }
#endif
