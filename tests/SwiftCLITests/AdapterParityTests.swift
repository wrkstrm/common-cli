import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

@Test("Parity: Ls vs LsNative for common flags")
func lsParityCommonFlags() async throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "ls-parity-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

  let a = tmp.appendingPathComponent("a.txt")
  try "aa".write(to: a, atomically: true, encoding: .utf8)
  let b = tmp.appendingPathComponent("b.txt")
  try "bbbb".write(to: b, atomically: true, encoding: .utf8)
  let hidden = tmp.appendingPathComponent(".hidden")
  try "x".write(to: hidden, atomically: true, encoding: .utf8)

  // Set modification dates deterministically
  let fm = FileManager.default
  try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 100)], ofItemAtPath: a.path)
  try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 200)], ofItemAtPath: b.path)
  try fm.setAttributes(
    [.modificationDate: Date(timeIntervalSince1970: 150)], ofItemAtPath: hidden.path,
  )

  let shell = CommonShell(executable: .path("/usr/bin/env"))
  let lsSub = shell.ls
  let lsNat = shell.lsNative

  func norm(_ s: String) -> [String] {
    s.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
  }

  // 1) Default (no hidden), one-per-line
  let sub1 = try await lsSub.list(directory: tmp.path, options: ["-1"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let nat1 = try await lsNat.list(directory: tmp.path, options: [.onePerLine]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  #expect(norm(sub1) == norm(nat1))

  // 2) Include hidden
  let sub2 = try await lsSub.list(directory: tmp.path, options: ["-1", "-a"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let nat2 = try await lsNat.list(directory: tmp.path, options: [.onePerLine, .includeHidden])
    .trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(norm(sub2) == norm(nat2))

  // 3) Sort by size desc
  let sub3 = try await lsSub.list(directory: tmp.path, options: ["-1", "-S"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let nat3 = try await lsNat.list(directory: tmp.path, options: [.onePerLine, .sortBySize])
    .trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(norm(sub3) == norm(nat3))

  // 4) Sort by time desc, then reverse
  let sub4 = try await lsSub.list(directory: tmp.path, options: ["-1", "-t"]).trimmingCharacters(
    in: .whitespacesAndNewlines)
  let nat4 = try await lsNat.list(directory: tmp.path, options: [.onePerLine, .sortByTime])
    .trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(norm(sub4) == norm(nat4))

  let sub5 = try await lsSub.list(directory: tmp.path, options: ["-1", "-t", "-r"])
    .trimmingCharacters(in: .whitespacesAndNewlines)
  let nat5 = try await lsNat.list(
    directory: tmp.path, options: [.onePerLine, .sortByTime, .reverse],
  ).trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(norm(sub5) == norm(nat5))
}
