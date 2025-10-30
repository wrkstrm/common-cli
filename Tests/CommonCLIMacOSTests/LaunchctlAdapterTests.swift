import CommonShell
import Darwin
import Foundation
import Testing

@testable import CommonCLI

@Suite("Launchctl adapter (macOS)")
struct LaunchctlAdapterTests {
  @Test("version prints something")
  func version_nonEmpty() async throws {
    let lc = Launchctl(shell: CommonShell(executable: .name("launchctl")))
    let v = try await lc.version()
    #expect(!v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  @Test("print system domain succeeds")
  func print_system_domain() async throws {
    let lc = Launchctl(shell: CommonShell(executable: .name("launchctl")))
    let out = try await lc.printDomain(
      .system,
    )
    #expect(!out.isEmpty)
  }

  @Test("print nonexistent label in current GUI domain throws")
  func print_nonexistent_label_throws() async throws {
    let lc = Launchctl(shell: CommonShell(executable: .name("launchctl")))
    let bogus = "com.wrkstrm.nonexistent.\(UUID().uuidString)"
    do {
      _ = try await lc.printDomain(.gui(uid: getuid()), label: bogus)
      Issue.record("Expected throw for nonexistent label, but succeeded")
    } catch {
      // ok
    }
  }
}
