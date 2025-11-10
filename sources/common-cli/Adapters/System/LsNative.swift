#if false
import CommonShell
import Foundation

public struct LsNativeSpec: ExecutableSpec {
  public let tool: String = "ls-native"
  public var prefixFlags: [String] = []
  public var prefixArguments: [String] = []
  public var wrapper: InvokationWrapper? = nil
  public var workingDirectory: String? = nil
  public init() {}
}

/// Native ls that lists directory contents using FileManager (no subprocess).
public struct LsNative: CLI, Codable, Sendable {
  public static let boot: CLIBoot = .name("ls-native")
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

  /// Typed ls options (subset) to ensure type-safe native usage.
  public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    // Output layout
    public static let onePerLine = Options(rawValue: 1 << 0)  // -1
    public static let longFormat = Options(rawValue: 1 << 6)  // -l (basic parity)
    public static let humanReadable = Options(rawValue: 1 << 7)  // -h (sizes)
    // Visibility
    public static let includeHidden = Options(rawValue: 1 << 1)  // -a (includes . and ..)
    public static let includeHiddenExceptDots = Options(rawValue: 1 << 2)  // -A (excludes . and ..)
    // Sorting
    public static let sortByTime = Options(rawValue: 1 << 3)  // -t
    public static let sortBySize = Options(rawValue: 1 << 4)  // -S
    public static let reverse = Options(rawValue: 1 << 5)  // -r
  }

  /// List a directory and return entries. Type-safe subset of flags:
  /// - onePerLine: output one entry per line (default behavior; we do not emulate columns)
  /// - includeHidden/includeHiddenExceptDots: control hidden entries
  /// - sortByTime/sortBySize + reverse: sorting behavior
  public func list(directory: String? = nil, options: Options = []) async throws -> String {
    let path = directory ?? shell.workingDirectory
    let fm = FileManager.default
    var entries = try fm.contentsOfDirectory(atPath: path)
    let includeHidden =
      options.contains(.includeHidden) || options.contains(.includeHiddenExceptDots)
    if !includeHidden {
      entries.removeAll { $0.hasPrefix(".") }
    }
    // For -a (but not -A), include . and .. which contentsOfDirectory omits.
    if options.contains(.includeHidden) && !options.contains(.includeHiddenExceptDots) {
      entries.append(".")
      entries.append("..")
    }
    let sortByTime = options.contains(.sortByTime)
    let sortBySize = options.contains(.sortBySize)
    let reverse = options.contains(.reverse)
    if sortByTime || sortBySize {
      entries.sort { a, b in
        let ap = (path as NSString).appendingPathComponent(a)
        let bp = (path as NSString).appendingPathComponent(b)
        let aa = (try? fm.attributesOfItem(atPath: ap)) ?? [:]
        let bb = (try? fm.attributesOfItem(atPath: bp)) ?? [:]
        guard sortByTime else {
          let asz = (aa[.size] as? NSNumber)?.int64Value ?? 0
          let bsz = (bb[.size] as? NSNumber)?.int64Value ?? 0
          return reverse ? asz < bsz : asz > bsz
        }
        let ad = (aa[.modificationDate] as? Date) ?? .distantPast
        let bd = (bb[.modificationDate] as? Date) ?? .distantPast
        return reverse ? ad < bd : ad > bd
      }
    } else {
      entries.sort(by: { reverse ? $0 > $1 : $0 < $1 })
    }
    guard options.contains(.longFormat) else {
      let sep = "\n"
      return entries.joined(separator: sep) + "\n"
    }
    // Emit a basic long format: mode links owner group size(or human) date name
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "MMM dd HH:mm"
    func modeString(_ attrs: [FileAttributeKey: Any]) -> String {
      let isDir = (attrs[.type] as? FileAttributeType) == .typeDirectory
      let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0o644
      func bit(_ p: Int) -> Character { ((perms & p) != 0) ? "r" : "-" }
      func wbit(_ p: Int) -> Character { ((perms & p) != 0) ? "w" : "-" }
      func xbit(_ p: Int) -> Character { ((perms & p) != 0) ? "x" : "-" }
      let s: [Character] = [
        isDir ? "d" : "-",
        bit(0o400), wbit(0o200), xbit(0o100),
        bit(0o040), wbit(0o020), xbit(0o010),
        bit(0o004), wbit(0o002), xbit(0o001),
      ]
      return String(s)
    }
    func human(_ size: Int64) -> String {
      let units = ["B", "K", "M", "G", "T"]
      var val = Double(size)
      var idx = 0
      while val >= 1024.0 && idx < units.count - 1 {
        val /= 1024.0
        idx += 1
      }
      return String(format: "%.1f%@", val, units[idx])
    }
    var lines: [String] = []
    for name in entries {
      let p = (path as NSString).appendingPathComponent(name)
      let a = (try? fm.attributesOfItem(atPath: p)) ?? [:]
      let mod = (a[.modificationDate] as? Date) ?? .distantPast
      let size = (a[.size] as? NSNumber)?.int64Value ?? 0
      let owner = (a[.ownerAccountName] as? String) ?? "-"
      let group = (a[.groupOwnerAccountName] as? String) ?? "-"
      let mode = modeString(a)
      let sizeStr = options.contains(.humanReadable) ? human(size) : String(size)
      lines.append("\(mode) 1 \(owner) \(group) \(sizeStr) \(df.string(from: mod)) \(name)")
    }
    return lines.joined(separator: "\n") + "\n"
  }
}

extension CommonShell { public var lsNative: LsNative { .init(shell: self) } }
#endif
