import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

@Suite("Gh adapter compile checks")
struct GhAdapterCompileTests {
  private func makeGh() -> Gh {
    Gh(shell: CommonShell(executable: .none()))
  }

  @Test
  func mutated_shell_sets_executable_and_host() {
    var base = CommonShell(executable: .path("/usr/bin/env"))
    base.hostKind = .direct
    let gh = Gh(shell: base)
    #expect(gh.shell.executable == Gh.executable)
    #expect(gh.shell.hostKind == .env(options: []))
  }

  @Test
  func compile_issueAndLabels_signatures() {
    let gh = makeGh()

    typealias IssueCreate = (Gh) -> (GhIssueCreateOptions, Set<GhIssueField>) async throws ->
      GhIssue
    typealias IssueAddLabels = (Gh) -> (String, [String]) async throws -> String
    typealias IssueRemoveLabels = (Gh) -> (String, [String]) async throws -> String
    typealias IssueAddAssignees = (Gh) -> (String, [String]) async throws -> String
    typealias IssueRemoveAssignees = (Gh) -> (String, [String]) async throws -> String
    typealias IssueClose = (Gh) -> (String, String?) async throws -> String
    typealias IssueReopen = (Gh) -> (String) async throws -> String
    typealias IssueComment = (Gh) -> (String, String) async throws -> String
    typealias IssueView = (Gh) -> (GhIssueIdentifier, Set<GhIssueField>) async throws -> GhIssue
    typealias IssueList = (Gh) -> (GhIssueListOptions, Set<GhIssueField>) async throws -> [GhIssue]

    let create: IssueCreate = Gh.issueCreate
    let addLabels: IssueAddLabels = Gh.issueAddLabels
    let removeLabels: IssueRemoveLabels = Gh.issueRemoveLabels
    let addAssignees: IssueAddAssignees = Gh.issueAddAssignees
    let removeAssignees: IssueRemoveAssignees = Gh.issueRemoveAssignees
    let close: IssueClose = Gh.issueClose
    let reopen: IssueReopen = Gh.issueReopen
    let comment: IssueComment = Gh.issueComment
    let view: IssueView = Gh.issueView
    let list: IssueList = Gh.issueList

    _ = create(gh)
    _ = addLabels(gh)
    _ = removeLabels(gh)
    _ = addAssignees(gh)
    _ = removeAssignees(gh)
    _ = close(gh)
    _ = reopen(gh)
    _ = comment(gh)
    _ = view(gh)
    _ = list(gh)
  }

  @Test
  func compile_repoAndAuth_signatures() {
    let gh = makeGh()

    typealias RepoView = (Gh) -> ([String]?) async throws -> String
    typealias AuthStatus = (Gh) -> () async throws -> String

    let repoView: RepoView = Gh.repoView
    let authStatus: AuthStatus = Gh.authStatus

    _ = repoView(gh)
    _ = authStatus(gh)
  }

  @Test
  func compile_labels_signatures() {
    let gh = makeGh()

    typealias LabelList = (Gh) -> () async throws -> String
    typealias LabelCreate = (Gh) -> (String, String?, String?) async throws -> String
    typealias LabelUpdate = (Gh) -> (String, String?, String?, String?) async throws -> String
    typealias LabelDelete = (Gh) -> (String, Bool) async throws -> String

    let list: LabelList = Gh.labelList
    let create: LabelCreate = Gh.labelCreate
    let update: LabelUpdate = Gh.labelUpdate
    let delete: LabelDelete = Gh.labelDelete

    _ = list(gh)
    _ = create(gh)
    _ = update(gh)
    _ = delete(gh)
  }

  @Test
  func decode_issue_payload_json() throws {
    let json = """
      {
        "number": 42,
        "title": "Stabilize issue sync",
        "body": "Ensure manifest reconciliation is deterministic.",
        "state": "OPEN",
        "stateReason": "REOPENED",
        "url": "https://github.com/example/repo/issues/42",
        "createdAt": "2024-09-21T12:34:56Z",
        "updatedAt": "2024-09-22T01:02:03Z",
        "labels": [
          { "name": "automation", "color": "1ABC9C" }
        ],
        "milestone": {
          "title": "CommonCLI Migration",
          "number": 3,
          "state": "OPEN",
          "dueOn": "2024-10-01T00:00:00Z"
        },
        "author": {
          "login": "wrks-bot",
          "url": "https://github.com/wrks-bot"
        }
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let issue = try decoder.decode(GhIssue.self, from: Data(json.utf8))
    let formatter = ISO8601DateFormatter()
    let expectedDueOn = formatter.date(from: "2024-10-01T00:00:00Z")

    #expect(issue.number == 42)
    #expect(issue.title == "Stabilize issue sync")
    #expect(issue.state == .open)
    #expect(issue.stateReason == "REOPENED")
    #expect(issue.url?.absoluteString == "https://github.com/example/repo/issues/42")
    #expect(issue.labels?.first?.name == "automation")
    #expect(issue.milestone?.title == "CommonCLI Migration")
    #expect(issue.milestone?.dueOn == expectedDueOn)
    #expect(issue.author?.login == "wrks-bot")
  }
}
