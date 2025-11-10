import CommonShell

extension Git {
  public func diff(_ extra: [String] = []) async throws -> String {
    try await run(["diff"] + extra)
  }
}
