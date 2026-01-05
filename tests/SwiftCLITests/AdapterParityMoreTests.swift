import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

@Test("Parity: rm -d removes empty dir; non-empty errors")
func rmDirectoryOnlyParity() async throws {
  let fm = FileManager.default
  let base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "rm-d-parity-" + UUID().uuidString)
  try fm.createDirectory(at: base, withIntermediateDirectories: true)
  let emptySub = base.appendingPathComponent("emptySub")
  let emptyNat = base.appendingPathComponent("emptyNat")
  let nonEmpty = base.appendingPathComponent("nonempty")
  try fm.createDirectory(at: emptySub, withIntermediateDirectories: true)
  try fm.createDirectory(at: emptyNat, withIntermediateDirectories: true)
  try fm.createDirectory(at: nonEmpty, withIntermediateDirectories: true)
  try "x".write(to: nonEmpty.appendingPathComponent("f.txt"), atomically: true, encoding: .utf8)

  let rmSub = Rm(shell: CommonShell(executable: .path("/bin/rm")))
  let rmNat = RmNative(shell: CommonShell(executable: .path("/usr/bin/env")))

  // Empty directory removable with -d
  _ = try await rmSub.remove(path: emptySub.path, options: [.directoryOnly])
  _ = try await rmNat.remove(path: emptyNat.path, options: [.directoryOnly])
  #expect(!fm.fileExists(atPath: emptySub.path))
  #expect(!fm.fileExists(atPath: emptyNat.path))

  // Non-empty directory with -d should not remove (error tolerated)
  do { _ = try await rmSub.remove(path: nonEmpty.path, options: [.directoryOnly]) } catch {  // expected
  }
  do { _ = try await rmNat.remove(path: nonEmpty.path, options: [.directoryOnly]) } catch {  // expected
  }
  #expect(fm.fileExists(atPath: nonEmpty.path))

  // Removing directory without -d or -r should fail
  let another = base.appendingPathComponent("another")
  try fm.createDirectory(at: another, withIntermediateDirectories: true)
  do { _ = try await rmSub.remove(path: another.path, options: []) } catch {  // expected
  }
  do { _ = try await rmNat.remove(path: another.path, options: []) } catch {  // expected
  }
  #expect(fm.fileExists(atPath: another.path))
}

@Test("Parity: ls -l/-h basic tolerances")
func lsLongFormatParityTolerance() async throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "ls-long-parity-" + UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  let a = tmp.appendingPathComponent("a.txt")
  try Data(repeating: 0x41, count: 3).write(to: a)
  let b = tmp.appendingPathComponent("b.txt")
  try Data(repeating: 0x42, count: 2048).write(to: b)

  let shell = CommonShell(executable: .path("/usr/bin/env"))
  let lsSub = shell.ls
  let lsNat = shell.lsNative

  func namesFromLong(_ s: String) -> [String] {
    s.split(separator: "\n").compactMap { line in
      let str = String(line)
      if str.hasPrefix("total ") { return nil }
      // naive: filename is after last space
      if let r = str.range(of: " ", options: .backwards) {
        return String(str[r.upperBound...])
      }
      return nil
    }.sorted()
  }

  // -l
  let subL = try await lsSub.list(directory: tmp.path, options: ["-l"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let natL = try await lsNat.list(directory: tmp.path, options: [.longFormat]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  #expect(namesFromLong(subL) == namesFromLong(natL))

  // -lh
  let subLH = try await lsSub.list(directory: tmp.path, options: ["-l", "-h"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let natLH = try await lsNat.list(directory: tmp.path, options: [.longFormat, .humanReadable])
    .trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(namesFromLong(subLH) == namesFromLong(natLH))

  // Check native long lines include owner/group/size tokens (best-effort)
  let longLines = natLH.split(separator: "\n").map(String.init)
  #expect(longLines.allSatisfy { $0.split(whereSeparator: { $0 == " " }).count >= 7 })
}
