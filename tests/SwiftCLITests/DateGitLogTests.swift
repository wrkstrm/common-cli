import Foundation
import Testing

@testable import CommonCLI

@Suite("Date git log parsing")
struct DateGitLogTests {
  @Test
  func parsesValidGitLogTimestamp() throws {
    let timestamp = "2025-02-14 09:10:11 +0000"
    let date = try #require(Date(gitLogString: timestamp))
    #expect(DateFormatter.gitLog.string(from: date) == timestamp)
  }

  @Test
  func rejectsInvalidGitLogTimestamp() {
    #expect(Date(gitLogString: "not-a-date") == nil)
  }
}
