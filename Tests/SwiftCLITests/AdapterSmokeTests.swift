import CommonProcess
import CommonShell
import Foundation
import Testing

@testable import CommonCLI

@Test("Pwd prints configured working directory")
func pwdPrintsWorkingDirectory() async throws {
  // Create a temporary directory and point the shell there
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let shell = CommonShell(workingDirectory: tmp.path, executable: .path("/usr/bin/env"))
  let out = try await shell.pwd.printWorkingDirectory().trimmingCharacters(
    in: .whitespacesAndNewlines)
  // Normalize both paths to account for /private prefix on macOS temp paths.
  let expected = tmp.standardizedFileURL.resolvingSymlinksInPath().path
  let actual = URL(fileURLWithPath: out).standardizedFileURL.resolvingSymlinksInPath().path
  #expect(actual == expected)
}

@Test("Ls lists contents of directory")
func lsListsDirectory() async throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let fname = "testfile.txt"
  let fpath = tmp.appendingPathComponent(fname)
  try "hello".write(to: fpath, atomically: true, encoding: .utf8)

  let shell = CommonShell(executable: .path("/usr/bin/env"))
  let out = try await shell.ls.list(directory: tmp.path, options: ["-1"])  // one per line
  #expect(out.contains(fname))
}

@Test("shell.rm.native removes file")
func shellRmNativeRemovesFile() async throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let file = tmp.appendingPathComponent("x.txt")
  try "x".write(to: file, atomically: true, encoding: .utf8)
  let shell = CommonShell(executable: .path("/usr/bin/env"))
  _ = try await shell.rm.native.remove(path: file.path, options: [])
  #expect(!FileManager.default.fileExists(atPath: file.path))
}

@Test("PwdNative returns configured working directory")
func pwdNativeWorkingDirectory() async throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let shell = CommonShell(workingDirectory: tmp.path, executable: .path("/usr/bin/env"))
  let out = try await shell.pwdNative.printWorkingDirectory().trimmingCharacters(
    in: .whitespacesAndNewlines)
  let expected = tmp.standardizedFileURL.resolvingSymlinksInPath().path
  let actual = URL(fileURLWithPath: out).standardizedFileURL.resolvingSymlinksInPath().path
  #expect(actual == expected)
}

@Test("LsNative lists directory contents")
func lsNativeListsDirectory() async throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let fname = "native-testfile.txt"
  let fpath = tmp.appendingPathComponent(fname)
  try "hello".write(to: fpath, atomically: true, encoding: .utf8)

  let shell = CommonShell(executable: .path("/usr/bin/env"))
  let out = try await shell.lsNative.list(directory: tmp.path, options: [.onePerLine])
  #expect(out.contains(fname))
}
