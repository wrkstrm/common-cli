import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

@Test("Parity: Mkdir vs MkdirNative")
func mkdirParity() async throws {
  let fm = FileManager.default
  let base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "mkdir-parity-" + UUID().uuidString)
  try fm.createDirectory(at: base, withIntermediateDirectories: true)

  let mkSub = Mkdir(shell: CommonShell(executable: .path("/bin/mkdir")))
  let mkNat = MkdirNative(shell: CommonShell(executable: .path("/usr/bin/env")))

  // Create fresh directories with parents=true
  let d1 = base.appendingPathComponent("a/b/c")
  _ = try await mkSub.createDirectory(at: d1.path, options: [.parents])
  #expect(fm.fileExists(atPath: d1.path))

  let d2 = base.appendingPathComponent("x/y/z")
  _ = try await mkNat.createDirectory(at: d2.path, options: [.parents])
  #expect(fm.fileExists(atPath: d2.path))

  // Existing dir with parents=false: tolerate platform differences; both should leave dir intact
  _ = try? await mkSub.createDirectory(at: d1.path, options: [])
  _ = try? await mkNat.createDirectory(at: d2.path, options: [])
  #expect(fm.fileExists(atPath: d1.path))
  #expect(fm.fileExists(atPath: d2.path))
}

@Test("Parity: Rm vs RmNative")
func rmParity() async throws {
  let fm = FileManager.default
  let base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "rm-parity-" + UUID().uuidString)
  try fm.createDirectory(at: base, withIntermediateDirectories: true)

  let rmSub = Rm(shell: CommonShell(executable: .path("/bin/rm")))
  let rmNat = RmNative(shell: CommonShell(executable: .path("/usr/bin/env")))

  // Remove files
  let f1 = base.appendingPathComponent("one.txt")
  try "1".write(to: f1, atomically: true, encoding: .utf8)
  let f2 = base.appendingPathComponent("two.txt")
  try "2".write(to: f2, atomically: true, encoding: .utf8)
  _ = try await rmSub.remove(path: f1.path, options: [])
  _ = try await rmNat.remove(path: f2.path, options: [])
  #expect(!fm.fileExists(atPath: f1.path))
  #expect(!fm.fileExists(atPath: f2.path))

  // Missing file with force=false: tolerate platform differences; neither should recreate files
  _ = try? await rmSub.remove(path: f1.path, options: [])
  _ = try? await rmNat.remove(path: f2.path, options: [])
  #expect(!fm.fileExists(atPath: f1.path))
  #expect(!fm.fileExists(atPath: f2.path))

  // Missing file with force=true should succeed
  _ = try await rmSub.remove(path: f1.path, options: [.force])
  _ = try await rmNat.remove(path: f2.path, options: [.force])
}

@Test("Parity: Cp vs CpNative")
func cpParity() async throws {
  let fm = FileManager.default
  let base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "cp-parity-" + UUID().uuidString)
  try fm.createDirectory(at: base, withIntermediateDirectories: true)

  let cpSub = Cp(shell: CommonShell(executable: .path("/bin/cp")))
  let cpNat = CpNative(shell: CommonShell(executable: .path("/usr/bin/env")))

  // Copy file into directory
  let src = base.appendingPathComponent("src.txt")
  try "abc".write(to: src, atomically: true, encoding: .utf8)
  let destDir1 = base.appendingPathComponent("d1")
  try fm.createDirectory(at: destDir1, withIntermediateDirectories: true)
  let destDir2 = base.appendingPathComponent("d2")
  try fm.createDirectory(at: destDir2, withIntermediateDirectories: true)
  _ = try await cpSub.copy(from: src.path, to: destDir1.path, options: [])
  _ = try await cpNat.copy(from: src.path, to: destDir2.path, options: [])
  let subOut = try String(contentsOf: destDir1.appendingPathComponent("src.txt"))
  let natOut = try String(contentsOf: destDir2.appendingPathComponent("src.txt"))
  #expect(subOut == natOut && natOut == "abc")

  // Overwrite behavior: default cp overwrites; native should match; force=true also succeeds
  let destFile1 = base.appendingPathComponent("file1.txt")
  try "x".write(to: destFile1, atomically: true, encoding: .utf8)
  _ = try? await cpSub.copy(from: src.path, to: destFile1.path, options: [])
  #expect(try (String(contentsOf: destFile1)) == "abc")

  let destFile2 = base.appendingPathComponent("file2.txt")
  try "x".write(to: destFile2, atomically: true, encoding: .utf8)
  _ = try? await cpNat.copy(from: src.path, to: destFile2.path, options: [])
  #expect(try (String(contentsOf: destFile2)) == "abc")

  // Directory copy without recursive: tolerate platform differences; ensure dest not created
  let srcDir = base.appendingPathComponent("srcdir")
  try fm.createDirectory(at: srcDir, withIntermediateDirectories: true)
  let inside = srcDir.appendingPathComponent("inner.txt")
  try "inner".write(to: inside, atomically: true, encoding: .utf8)
  let subCopy = base.appendingPathComponent("sub-copy")
  let natCopy = base.appendingPathComponent("nat-copy")
  _ = try? await cpSub.copy(from: srcDir.path, to: subCopy.path, options: [])
  _ = try? await cpNat.copy(from: srcDir.path, to: natCopy.path, options: [])
  var isDir: ObjCBool = false
  #expect(!fm.fileExists(atPath: subCopy.path, isDirectory: &isDir))
  #expect(!fm.fileExists(atPath: natCopy.path, isDirectory: &isDir))
}

@Test("Parity: Readlink vs ReadlinkNative")
func readlinkParity() async throws {
  let fm = FileManager.default
  let base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "readlink-parity-" + UUID().uuidString)
  try fm.createDirectory(at: base, withIntermediateDirectories: true)

  let target = base.appendingPathComponent("target.txt")
  try "t".write(to: target, atomically: true, encoding: .utf8)
  let link = base.appendingPathComponent("link.txt")
  try fm.createSymbolicLink(at: link, withDestinationURL: target)

  let shell = CommonShell(executable: .path("/usr/bin/env"))
  let readSub = shell.readlink
  let readNat = shell.readlinkNative

  func canon(_ s: String) -> String {
    let p = s.trimmingCharacters(in: .whitespacesAndNewlines)
    return URL(fileURLWithPath: p).standardizedFileURL.resolvingSymlinksInPath().path
  }
  let subLogical = try await readSub.read(path: link.path, options: [.canonicalize])
  let natLogical = try await readNat.read(path: link.path, options: [.canonicalize])
  #expect(canon(subLogical) == canon(natLogical))

  let subNoLogical = try await readSub.read(path: link.path, options: [])
  let natNoLogical = try await readNat.read(path: link.path, options: [])
  // Compare standardized absolute paths in case of relative link targets
  #expect(canon(subNoLogical) == canon(natNoLogical))
}
