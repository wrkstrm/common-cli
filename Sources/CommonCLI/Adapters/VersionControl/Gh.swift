import CommonProcess
import CommonShell
import Foundation

// MARK: - Issue metadata models

/// Fields that can be requested when emitting GitHub issue JSON via `gh`.
public enum GhIssueField: String, CaseIterable, Codable, Sendable {
  case assignees
  case author
  case body
  case closed
  case closedAt
  case closedByPullRequestsReferences
  case comments
  case createdAt
  case id
  case isPinned
  case labels
  case milestone
  case number
  case projectCards
  case projectItems
  case reactionGroups
  case state
  case stateReason
  case title
  case updatedAt
  case url
}

extension Set where Element == GhIssueField {
  /// Minimal issue details that uniquely identify an issue and support manifest syncing.
  public static let summary: Self = [.number, .title, .state, .url]

  /// Default fields used when inspecting a single issue in detail.
  public static let detail: Self = [
    .number, .title, .body, .state, .stateReason, .url, .labels, .milestone,
  ]
}

/// GitHub issue state wrapper that preserves unknown variants while offering conveniences for common cases.
public enum GhIssueState: Equatable, Sendable, Codable {
  case open
  case closed
  case custom(String)

  public var rawValue: String {
    switch self {
    case .open: return "open"
    case .closed: return "closed"
    case .custom(let value): return value
    }
  }

  public init(rawValue: String) {
    switch rawValue.lowercased() {
    case "open": self = .open
    case "closed": self = .closed
    default: self = .custom(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)
    self = GhIssueState(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Lightweight representation of a GitHub actor (author, assignee, etc.).
public struct GhActor: Codable, Equatable, Sendable {
  public var login: String?
  public var name: String?
  public var url: URL?

  public init(login: String? = nil, name: String? = nil, url: URL? = nil) {
    self.login = login
    self.name = name
    self.url = url
  }
}

/// GitHub label summary used in issue payloads.
public struct GhLabel: Codable, Equatable, Sendable {
  public var name: String?
  public var description: String?
  public var color: String?

  public init(name: String? = nil, description: String? = nil, color: String? = nil) {
    self.name = name
    self.description = description
    self.color = color
  }
}

/// GitHub milestone summary.
public struct GhMilestone: Codable, Equatable, Sendable {
  public var title: String?
  public var number: Int?
  public var description: String?
  public var state: String?
  public var dueOn: Date?
  public var url: URL?

  enum CodingKeys: String, CodingKey {
    case title
    case number
    case description
    case state
    case dueOn
    case url
  }

  public init(
    title: String? = nil,
    number: Int? = nil,
    description: String? = nil,
    state: String? = nil,
    dueOn: Date? = nil,
    url: URL? = nil
  ) {
    self.title = title
    self.number = number
    self.description = description
    self.state = state
    self.dueOn = dueOn
    self.url = url
  }
}

/// Canonical representation used when decoding issue payloads via `gh --json`.
public struct GhIssue: Codable, Equatable, Sendable {
  public var number: Int?
  public var title: String?
  public var body: String?
  public var state: GhIssueState?
  public var stateReason: String?
  public var url: URL?
  public var createdAt: Date?
  public var updatedAt: Date?
  public var closedAt: Date?
  public var closed: Bool?
  public var labels: [GhLabel]?
  public var milestone: GhMilestone?
  public var author: GhActor?
  public var assignees: [GhActor]?

  public init(
    number: Int? = nil,
    title: String? = nil,
    body: String? = nil,
    state: GhIssueState? = nil,
    stateReason: String? = nil,
    url: URL? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil,
    closedAt: Date? = nil,
    closed: Bool? = nil,
    labels: [GhLabel]? = nil,
    milestone: GhMilestone? = nil,
    author: GhActor? = nil,
    assignees: [GhActor]? = nil
  ) {
    self.number = number
    self.title = title
    self.body = body
    self.state = state
    self.stateReason = stateReason
    self.url = url
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.closedAt = closedAt
    self.closed = closed
    self.labels = labels
    self.milestone = milestone
    self.author = author
    self.assignees = assignees
  }
}

/// Identifier wrapper for CLI-friendly issue references.
public struct GhIssueIdentifier: Codable, Equatable, Hashable, Sendable {
  public var rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }

  public static func number(_ number: Int) -> GhIssueIdentifier {
    GhIssueIdentifier(rawValue: String(number))
  }

  public static func url(_ url: URL) -> GhIssueIdentifier {
    GhIssueIdentifier(rawValue: url.absoluteString)
  }
}

/// Options used when creating GitHub issues through the adapter.
public struct GhIssueCreateOptions: Codable, Equatable, Sendable {
  public var title: String
  public var body: String
  public var labels: [String]
  public var milestone: String?
  public var assignees: [String]
  public var projects: [String]

  public init(
    title: String,
    body: String,
    labels: [String] = [],
    milestone: String? = nil,
    assignees: [String] = [],
    projects: [String] = []
  ) {
    self.title = title
    self.body = body
    self.labels = labels
    self.milestone = milestone
    self.assignees = assignees
    self.projects = projects
  }
}

/// Filter set used when listing issues via the GitHub CLI adapter.
public struct GhIssueListOptions: Codable, Equatable, Sendable {
  public var state: GhIssueStateFilter
  public var labels: [String]
  public var author: String?
  public var assignee: String?
  public var milestone: String?
  public var searchQuery: String?
  public var limit: Int?
  public var mention: String?
  public var app: String?

  public init(
    state: GhIssueStateFilter = .open,
    labels: [String] = [],
    author: String? = nil,
    assignee: String? = nil,
    milestone: String? = nil,
    searchQuery: String? = nil,
    limit: Int? = nil,
    mention: String? = nil,
    app: String? = nil
  ) {
    self.state = state
    self.labels = labels
    self.author = author
    self.assignee = assignee
    self.milestone = milestone
    self.searchQuery = searchQuery
    self.limit = limit
    self.mention = mention
    self.app = app
  }
}

/// Known states accepted by `gh issue list --state`.
public enum GhIssueStateFilter: String, Codable, CaseIterable, Sendable {
  case open
  case closed
  case all
}

/// Errors surfaced when decoding `gh --json` payloads.
public struct GhDecodingError: Error, CustomStringConvertible, Sendable {
  public enum Kind: Sendable {
    case empty
    case invalidJSON
  }

  public var kind: Kind
  public var command: [String]
  public var rawOutput: String
  public var underlying: Error?

  public init(kind: Kind, command: [String], rawOutput: String, underlying: Error? = nil) {
    self.kind = kind
    self.command = command
    self.rawOutput = rawOutput
    self.underlying = underlying
  }

  public var description: String {
    switch kind {
    case .empty:
      let joinedCommand = command.joined(separator: " ")
      return "gh output was empty for command: \(joinedCommand)"
    case .invalidJSON:
      let joinedCommand = command.joined(separator: " ")
      return "gh output could not be decoded as JSON for command: \(joinedCommand)"
    }
  }
}

/// Lightweight wrapper around the GitHub CLI (`gh`).
///
/// Notes:
/// - These helpers assume the current working directory resolves to the intended repository
///   (e.g. run inside a package/submodule directory).
/// - Prefer long-form flags and explicit parameters for human readability.
public struct Gh: CLI, Codable, Sendable, Versioned {
  public static let executable: Executable = .name("gh")
  public var shell: CommonShell

  public init(shell: CommonShell) { self.shell = Self.mutatedShell(shell: shell) }

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

  // MARK: - Issues

  /// Create an issue using the provided options. Returns the decoded payload requested via
  /// `fields`, defaulting to `.summary`.
  @discardableResult
  public func issueCreate(
    options: GhIssueCreateOptions,
    fields: Set<GhIssueField> = .summary
  ) async throws -> GhIssue {
    var arguments: [String] = [
      "issue", "create", "--title", options.title,
      "--body", options.body,
    ]

    for label in options.labels where !label.isEmpty {
      arguments += ["--label", label]
    }
    if let milestone = options.milestone, !milestone.isEmpty {
      arguments += ["--milestone", milestone]
    }
    for assignee in options.assignees where !assignee.isEmpty {
      arguments += ["--assignee", assignee]
    }
    for project in options.projects where !project.isEmpty {
      arguments += ["--project", project]
    }

    arguments += jsonFieldArguments(for: fields)
    let output = try await shell.run(arguments)
    return try decodeJSON(GhIssue.self, from: output, command: arguments)
  }

  /// Add one or more labels to an existing issue.
  @discardableResult
  public func issueAddLabels(number: String, labels: [String]) async throws -> String {
    var args: [String] = ["issue", "edit", number]
    for label in labels where !label.isEmpty {
      args += ["--add-label", label]
    }
    return try await shell.run(args)
  }

  /// Remove one or more labels from an existing issue.
  @discardableResult
  public func issueRemoveLabels(number: String, labels: [String]) async throws -> String {
    var args: [String] = ["issue", "edit", number]
    for label in labels where !label.isEmpty {
      args += ["--remove-label", label]
    }
    return try await shell.run(args)
  }

  /// Assign one or more users to an issue.
  @discardableResult
  public func issueAddAssignees(number: String, assignees: [String]) async throws -> String {
    var args: [String] = ["issue", "edit", number]
    for user in assignees where !user.isEmpty {
      args += ["--add-assignee", user]
    }
    return try await shell.run(args)
  }

  /// Remove one or more assignees from an issue.
  @discardableResult
  public func issueRemoveAssignees(number: String, assignees: [String]) async throws -> String {
    var args: [String] = ["issue", "edit", number]
    for user in assignees where !user.isEmpty {
      args += ["--remove-assignee", user]
    }
    return try await shell.run(args)
  }

  /// Close an issue, optionally adding a comment.
  @discardableResult
  public func issueClose(number: String, comment: String? = nil) async throws -> String {
    var args: [String] = ["issue", "close", number]
    if let comment, !comment.isEmpty { args += ["--comment", comment] }
    return try await shell.run(args)
  }

  /// Reopen a previously closed issue.
  @discardableResult
  public func issueReopen(number: String) async throws -> String {
    try await shell.run(["issue", "reopen", number])
  }

  /// Add a new comment to an issue.
  @discardableResult
  public func issueComment(number: String, body: String) async throws -> String {
    try await shell.run(["issue", "comment", number, "--body", body])
  }

  /// View a single issue identified by number or URL and decode the selected fields.
  @discardableResult
  public func issueView(
    identifier: GhIssueIdentifier,
    fields: Set<GhIssueField> = .detail
  ) async throws -> GhIssue {
    var arguments: [String] = ["issue", "view", identifier.rawValue]
    arguments += jsonFieldArguments(for: fields)
    let output = try await shell.run(arguments)
    return try decodeJSON(GhIssue.self, from: output, command: arguments)
  }

  /// List issues in the current repository using typed filters and decode the requested fields.
  @discardableResult
  public func issueList(
    options: GhIssueListOptions = GhIssueListOptions(),
    fields: Set<GhIssueField> = .summary
  ) async throws -> [GhIssue] {
    var arguments: [String] = ["issue", "list", "--state", options.state.rawValue]

    for label in options.labels where !label.isEmpty {
      arguments += ["--label", label]
    }
    if let author = options.author, !author.isEmpty {
      arguments += ["--author", author]
    }
    if let assignee = options.assignee, !assignee.isEmpty {
      arguments += ["--assignee", assignee]
    }
    if let milestone = options.milestone, !milestone.isEmpty {
      arguments += ["--milestone", milestone]
    }
    if let searchQuery = options.searchQuery, !searchQuery.isEmpty {
      arguments += ["--search", searchQuery]
    }
    if let limit = options.limit {
      arguments += ["--limit", String(limit)]
    }
    if let mention = options.mention, !mention.isEmpty {
      arguments += ["--mention", mention]
    }
    if let app = options.app, !app.isEmpty {
      arguments += ["--app", app]
    }

    arguments += jsonFieldArguments(for: fields)
    let output = try await shell.run(arguments)
    return try decodeJSON([GhIssue].self, from: output, command: arguments)
  }

  // MARK: - Labels

  /// List labels in the current repository.
  @discardableResult
  public func labelList() async throws -> String {
    try await shell.run(["label", "list"])  // gh label list
  }

  /// Create a label (requires repo permissions). Color should be a hex string without '#'.
  @discardableResult
  public func labelCreate(
    name: String,
    color: String? = nil,
    description: String? = nil,
  ) async throws -> String {
    var args: [String] = ["label", "create", name]
    if let color, !color.isEmpty { args += ["--color", color] }
    if let description, !description.isEmpty { args += ["--description", description] }
    return try await shell.run(args)
  }

  /// Update a label's name, color, or description.
  @discardableResult
  public func labelUpdate(
    currentName: String,
    newName: String? = nil,
    color: String? = nil,
    description: String? = nil,
  ) async throws -> String {
    var args: [String] = ["label", "edit", currentName]
    if let newName, !newName.isEmpty { args += ["--name", newName] }
    if let color, !color.isEmpty { args += ["--color", color] }
    if let description, !description.isEmpty { args += ["--description", description] }
    return try await shell.run(args)
  }

  /// Delete a label from the repository.
  @discardableResult
  public func labelDelete(name: String, confirm: Bool = true) async throws -> String {
    var args: [String] = ["label", "delete", name]
    if confirm { args.append("--yes") }
    return try await shell.run(args)
  }

  // MARK: - Repo & Auth

  /// Show repo details. When `fields` is provided, returns JSON with those fields.
  @discardableResult
  public func repoView(fields: [String]? = nil) async throws -> String {
    var args: [String] = ["repo", "view"]
    if let fields, !fields.isEmpty { args += ["--json", fields.joined(separator: ",")] }
    return try await shell.run(args)
  }

  /// Show authentication status for the current `gh` configuration.
  @discardableResult
  public func authStatus() async throws -> String {
    try await shell.run(["auth", "status"])  // Avoid --show-token for safety
  }

  // MARK: - Helpers

  private func jsonFieldArguments(for fields: Set<GhIssueField>) -> [String] {
    let requested = fields.isEmpty ? Set<GhIssueField>.summary : fields
    let joined = requested.map(\.rawValue).sorted().joined(separator: ",")
    return ["--json", joined]
  }

  private func decodeJSON<T: Decodable>(
    _ type: T.Type,
    from output: String,
    command: [String]
  ) throws -> T {
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw GhDecodingError(kind: .empty, command: command, rawOutput: output)
    }

    guard let data = trimmed.data(using: .utf8) else {
      throw GhDecodingError(kind: .invalidJSON, command: command, rawOutput: output)
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      return try decoder.decode(type, from: data)
    } catch {
      throw GhDecodingError(
        kind: .invalidJSON, command: command, rawOutput: output, underlying: error)
    }
  }
}
