import CommonShell

extension Git {
  public enum RebaseOption: String {
    case interactive = "-i"
    case continueRebase = "--continue"
    case abort = "--abort"
  }

  public func rebase(_ options: [RebaseOption] = [], onto: String? = nil) async throws -> String {
    var args = ["rebase"] + options.map(\.rawValue)
    if let onto { args.append(onto) }
    return try await run(args)
  }
}
