import CommonProcess
import CommonShell

public struct Rsync: CLI {
  public static let executable: Executable = .name("rsync")
  public var shell: CommonShell

  public init(shell: CommonShell) { self.shell = shell }

  public func sync(
    from: String, to: String, archive: Bool = true, delete: Bool = false, extra: [String] = [],
  ) async throws -> String {
    var args: [String] = []
    if archive { args.append("-a") }
    if delete { args.append("--delete") }
    args.append(contentsOf: extra)
    args.append(contentsOf: [from, to])
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }
}

extension CommonShell { public var rsync: Rsync { .init(shell: self) } }
