import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

// Adapter performance suite: easy to grow by adding new cases below.

private struct AdapterPerfConfig {
  let seconds: Double
  let hz: Double?

  init(env: [String: String] = ProcessInfo.processInfo.environment) {
    if let raw = env["SWIFTSHELL_PERF_SECS"], let s = try? parseDurationSeconds(raw) {
      seconds = s
    } else {
      seconds = 0.5
    }
    if let rawHz = env["SWIFTSHELL_PERF_HZ"], let f = parseFrequencyHz(rawHz) {
      hz = f
    } else {
      hz = 144.0
    }
  }
}

private struct AdapterPerfCase {
  let name: String
  let oneIteration: () async throws -> Void
}

@Test("AdapterPerf: selected cases (timed)")
func adapterPerf_selectedCases_timed() async throws {
  let cfg = AdapterPerfConfig()

  // Cases: append new adapters here as they are added.
  let echoSubprocess = Echo(shell: CommonShell(executable: .path("/bin/echo")))
  let baseShell = CommonShell(executable: .path("/usr/bin/env"))
  let echoNative = EchoNative(shell: baseShell)
  let pwdCLI = Pwd(shell: CommonShell(executable: .path("/bin/pwd")))
  let lsCLI = Ls(shell: CommonShell(executable: .path("/bin/ls")))
  let rmCLI = Rm(shell: CommonShell(executable: .path("/bin/rm")))
  let mkdirCLI = Mkdir(shell: CommonShell(executable: .path("/bin/mkdir")))
  let cpCLI = Cp(shell: CommonShell(executable: .path("/bin/cp")))
  let catCLI = Cat(shell: CommonShell(executable: .path("/bin/cat")))
  let readlinkCLI = Readlink(shell: CommonShell(executable: .path("/usr/bin/readlink")))
  let pwdNative = PwdNative(shell: baseShell)
  let lsNative = LsNative(shell: baseShell)
  let rmNative = RmNative(shell: baseShell)
  let mkdirNative = MkdirNative(shell: baseShell)
  let cpNative = CpNative(shell: baseShell)
  let catNative = CatNative(shell: baseShell)
  let readlinkNative = ReadlinkNative(shell: baseShell)

  // Prepare per-run temporary directory and files for FS operations
  let tmpBase = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "swiftshell-adapter-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmpBase, withIntermediateDirectories: true)
  let sourceFile = tmpBase.appendingPathComponent("src.txt")
  try "hello world".data(using: .utf8)!.write(to: sourceFile)
  let symlink = tmpBase.appendingPathComponent("link.txt")
  try? FileManager.default.removeItem(at: symlink)
  try? FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: sourceFile)

  let cases: [AdapterPerfCase] = [
    .init(name: "echo-subprocess") { _ = try await echoSubprocess.echo("bench") },
    .init(name: "echo-native") { _ = try await echoNative.echo("bench") },
    .init(name: "pwd-subprocess") { _ = try await pwdCLI.printWorkingDirectory() },
    .init(name: "ls-subprocess") { _ = try await lsCLI.list(directory: ".", options: ["-1"]) },
    .init(name: "cat-subprocess") { _ = try await catCLI.concatenate(files: [sourceFile.path]) },
    .init(name: "readlink-subprocess") {
      _ = try await readlinkCLI.read(path: symlink.path, options: [.canonicalize])
    },
    .init(name: "mkdir-subprocess") {
      let dir = tmpBase.appendingPathComponent("d_\(UUID().uuidString)")
      _ = try await mkdirCLI.createDirectory(at: dir.path, options: [.parents])
      try? FileManager.default.removeItem(at: dir)
    },
    .init(name: "rm-subprocess") {
      let f = tmpBase.appendingPathComponent("rm_\(UUID().uuidString).txt")
      try "x".write(to: f, atomically: true, encoding: .utf8)
      _ = try await rmCLI.remove(path: f.path, options: [])
    },
    .init(name: "cp-subprocess") {
      let dest = tmpBase.appendingPathComponent("dest_\(UUID().uuidString).txt")
      _ = try await cpCLI.copy(from: sourceFile.path, to: dest.path, options: [.force])
      try? FileManager.default.removeItem(at: dest)
    },
    .init(name: "pwd-native") { _ = try await pwdNative.printWorkingDirectory() },
    .init(name: "ls-native") {
      _ = try await lsNative.list(directory: ".", options: [.onePerLine])
    },
    .init(name: "cat-native") { _ = try await catNative.concatenate(files: [sourceFile.path]) },
    .init(name: "readlink-native") {
      _ = try await readlinkNative.read(path: symlink.path, options: [.canonicalize])
    },
    .init(name: "mkdir-native") {
      let dir = tmpBase.appendingPathComponent("d_\(UUID().uuidString)")
      _ = try await mkdirNative.createDirectory(at: dir.path, options: [.parents])
      try? FileManager.default.removeItem(at: dir)
    },
    .init(name: "rm-native") {
      let f = tmpBase.appendingPathComponent("rm_\(UUID().uuidString).txt")
      try "x".write(to: f, atomically: true, encoding: .utf8)
      _ = try await rmNative.remove(path: f.path, options: [])
    },
    .init(name: "cp-native") {
      let dest = tmpBase.appendingPathComponent("dest_\(UUID().uuidString).txt")
      _ = try await cpNative.copy(from: sourceFile.path, to: dest.path, options: [])
      try? FileManager.default.removeItem(at: dest)
    },
  ]

  struct Row {
    let name: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []

  for perfCase in cases {
    // Use a tiny runner harness to measure time per-iteration over duration.
    let t0 = DispatchTime.now().uptimeNanoseconds
    let deadline = t0 + UInt64(cfg.seconds * 1_000_000_000.0)
    let tick: Double? = cfg.hz.map { 1.0 / max($0, 0.000_001) }
    var iter = 0
    var totalMS: Double = 0
    while DispatchTime.now().uptimeNanoseconds < deadline {
      let it0 = DispatchTime.now()
      try await perfCase.oneIteration()
      let itMS = Double(DispatchTime.now().uptimeNanoseconds - it0.uptimeNanoseconds) / 1_000_000.0
      totalMS += itMS
      iter += 1
      if let tick {
        let sleepS = max(0.0, tick - (itMS / 1000.0))
        if sleepS > 0 { try await Task.sleep(nanoseconds: UInt64(sleepS * 1_000_000_000.0)) }
      }
    }
    let elapsedMS = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000.0
    let avg = iter > 0 ? totalMS / Double(iter) : 0
    #expect(iter > 0)
    rows.append(.init(name: perfCase.name, iterations: iter, totalMS: elapsedMS, avgMS: avg))
  }

  // Emit CSV for human consumption
  print("case,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.name),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS)))",
    )
  }
}
