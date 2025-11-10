#if os(macOS)
import CommonProcess
import CommonShell
import Darwin

public struct Launchctl: CLI, Versioned {
  public static var executable: Executable { .name("launchctl") }
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  public func version() async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: ["version"])
  }

  // MARK: Deprecated convenience verbs

  @discardableResult
  public func load(plistPath: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["load", "-w", plistPath])
  }

  @discardableResult
  public func unload(plistPath: String) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: ["unload", plistPath])
  }

  // MARK: Modern verbs

  @discardableResult
  public func bootstrapUser(plistPath: String) async throws -> String {
    let uid = getuid()
    return try await shell.runConfigured(
      executable: Self.executable, arguments: ["bootstrap", "gui/\(uid)", plistPath])
  }

  @discardableResult
  public func bootoutUser(plistPath: String) async throws -> String {
    let uid = getuid()
    return try await shell.runConfigured(
      executable: Self.executable, arguments: ["bootout", "gui/\(uid)", plistPath])
  }

  @discardableResult
  public func kickstartUser(label: String) async throws -> String {
    let uid = getuid()
    return try await shell.runConfigured(
      executable: Self.executable, arguments: ["kickstart", "gui/\(uid)/\(label)"])
  }

  @discardableResult
  public func printUser(label: String) async throws -> String {
    let uid = getuid()
    return try await shell.runConfigured(
      executable: Self.executable, arguments: ["print", "gui/\(uid)/\(label)"])
  }

  // MARK: Domain helpers

  public enum Domain: Sendable {
    case system
    case gui(uid: uid_t)
    case user(uid: uid_t)
    case login(uuid: String)

    var raw: String {
      switch self {
      case .system: "system"
      case .gui(let uid): "gui/\(uid)"
      case .user(let uid): "user/\(uid)"
      case .login(let uuid): "login/\(uuid)"
      }
    }

    public static var currentGUI: Domain { .gui(uid: getuid()) }
    public static var currentUser: Domain { .user(uid: getuid()) }
  }

  @discardableResult
  public func bootstrap(_ domain: Domain, plistPath: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["bootstrap", domain.raw, plistPath])
  }

  @discardableResult
  public func bootout(_ domain: Domain, plistPath: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["bootout", domain.raw, plistPath])
  }

  @discardableResult
  public func kickstart(_ domain: Domain, label: String, restart: Bool = false) async throws
    -> String
  {
    var args = ["kickstart"]
    if restart { args.append("-k") }
    args.append("\(domain.raw)/\(label)")
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  @discardableResult
  public func enable(_ domain: Domain, label: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["enable", "\(domain.raw)/\(label)"])
  }

  @discardableResult
  public func disable(_ domain: Domain, label: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["disable", "\(domain.raw)/\(label)"])
  }

  @discardableResult
  public func printDomain(_ domain: Domain) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: ["print", domain.raw])
  }

  @discardableResult
  public func printDomain(_ domain: Domain, label: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["print", "\(domain.raw)/\(label)"])
  }
}
#endif
