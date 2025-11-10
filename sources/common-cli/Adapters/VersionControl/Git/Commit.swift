import Foundation

public struct Commit: Sendable, Hashable, Codable {
  public let hash: String
  public let dateString: String
}

extension Git {
  /// Return commits parsed from `git log --format="%H %ci"` (hash and commit date).
  public func commits(limit: Int? = nil) async throws -> [Commit] {
    var args = ["log", "--format=%H %ci"]
    if let limit { args.append("-n\(limit)") }
    let out = try await run(args)
    return
      out
      .split(separator: "\n")
      .compactMap { line in
        let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        return Commit(hash: String(parts[0]), dateString: String(parts[1]))
      }
  }
}
