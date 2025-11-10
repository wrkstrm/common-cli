#if false
import CommonShell
import Foundation

public struct ReadlinkNativeSpec: ExecutableSpec {
  public let tool: String = "readlink-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

public struct ReadlinkNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("readlink-native")
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

  /// Read a symlink path; when options contains .canonicalize, returns a canonical absolute path.
  public func read(path: String, options: Readlink.Options = [.canonicalize]) async throws -> String
  {
    let url = URL(fileURLWithPath: path)
    let resolved: String
    if options.contains(.canonicalize) {
      resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
    } else {
      // Best-effort: attempt to return symlink destination; fall back to lastPathComponent
      var isDir: ObjCBool = false
      let fm = FileManager.default
      if fm.fileExists(atPath: path, isDirectory: &isDir) {
        if let dest = try? fm.destinationOfSymbolicLink(atPath: path) {
          if dest.hasPrefix("/") {
            resolved = dest
          } else {
            resolved = url.deletingLastPathComponent().appendingPathComponent(dest).path
          }
        } else {
          resolved = url.path
        }
      } else {
        resolved = url.path
      }
    }
    return resolved + "\n"
  }
}

extension CommonShell { public var readlinkNative: ReadlinkNative { .init(shell: self) } }
#endif
