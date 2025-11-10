import CommonCLI
import CommonShell
import CommonShellBenchSupport
import Foundation
import Testing

private struct PerfCfg {
  let seconds: Double
  let hz: Double?
  init(env: [String: String] = ProcessInfo.processInfo.environment) {
    if let raw = env["SWIFTSHELL_PERF_SECS"], let s = try? parseDurationSeconds(raw) {
      seconds = s
    } else {
      seconds = 0.3
    }
    if let raw = env["SWIFTSHELL_PERF_HZ"], let f = parseFrequencyHz(raw) {
      hz = f
    } else {
      hz = 144.0
    }
  }
}

@Test("Perf(Native CLI): echo wrappers")
func perf_echo_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let echo = Echo(shell: base)
  let native = echo.native

  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []

  // env (native PATH)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("echo"), arguments: ["bench"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }

  // direct
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/echo"), arguments: ["bench"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }

  // shell
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["echo bench"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }

  // env(echo)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("echo"), arguments: ["bench"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(echo)", iterations: res.iterations, totalMS: res.totalMS,
        avgMS: res.averageMS,
      ))
  }

  // npx transport
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(), arguments: ["-y", "-c", "echo bench"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }

  print("echo wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS)))",
    )
  }
}

@Test("Perf(Native CLI): ls wrappers")
func perf_ls_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "ls-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  for i in 0..<5 {
    try "x\(i)".write(
      to: tmp.appendingPathComponent("f\(i).txt"), atomically: true, encoding: .utf8,
    )
  }
  let ls = Ls(shell: base)
  let native = ls.native
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []

  // env (native PATH)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("ls"), arguments: ["-1", tmp.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  // direct
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/ls"), arguments: ["-1", tmp.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  // shell
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["ls -1 \(tmp.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  // env(ls)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("ls"), arguments: ["-1", tmp.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(ls)", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  // npx
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(), arguments: ["-y", "-c", "ls -1 \(tmp.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("ls wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS)))",
    )
  }
}

@Test("Perf(Native CLI): cp wrappers")
func perf_cp_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "cp-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let src = tmp.appendingPathComponent("src.txt")
  try "hello".write(to: src, atomically: true, encoding: .utf8)
  let dest = tmp.appendingPathComponent("dest.txt")
  let cp = Cp(shell: base)
  let native = cp.native
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []

  // env (native PATH)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("cp"), arguments: [src.path, dest.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
    try? FileManager.default.removeItem(at: dest)
  }
  // direct
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/cp"), arguments: [src.path, dest.path],
      durationSeconds: cfg.seconds,
      targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
    try? FileManager.default.removeItem(at: dest)
  }
  // shell
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"),
      arguments: ["cp \(src.path) \(dest.path)"], durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
    try? FileManager.default.removeItem(at: dest)
  }
  // env(cp)
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("cp"), arguments: [src.path, dest.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(cp)", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
    try? FileManager.default.removeItem(at: dest)
  }
  // npx
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(),
      arguments: ["-y", "-c", "cp \(src.path) \(dest.path)"],
      durationSeconds: cfg.seconds,
      targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
    try? FileManager.default.removeItem(at: dest)
  }
  print("cp wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS)))",
    )
  }
}

@Test("Perf(Native CLI): pwd wrappers")
func perf_pwd_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("pwd"), arguments: [],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/pwd"), arguments: [],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["pwd"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("pwd"), arguments: [],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(pwd)", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ),
    )
  }
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(), arguments: ["-y", "-c", "pwd"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("pwd wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS))",
    )
  }
}

@Test("Perf(Native CLI): cat wrappers")
func perf_cat_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "cat-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let src = tmp.appendingPathComponent("src.txt")
  try String(repeating: "A", count: 4096).write(to: src, atomically: true, encoding: .utf8)
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("cat"), arguments: [src.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/cat"), arguments: [src.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["cat \(src.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("cat"), arguments: [src.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(cat)", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ),
    )
  }
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(), arguments: ["-y", "-c", "cat \(src.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("cat wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS))",
    )
  }
}

@Test("Perf(Native CLI): readlink wrappers")
func perf_readlink_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "readlink-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let target = tmp.appendingPathComponent("t.txt")
  try "t".write(to: target, atomically: true, encoding: .utf8)
  let link = tmp.appendingPathComponent("l.txt")
  try? FileManager.default.removeItem(at: link)
  try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("readlink"), arguments: ["-f", link.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/usr/bin/readlink"), arguments: ["-f", link.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"),
      arguments: ["readlink -f \(link.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("readlink"), arguments: ["-f", link.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(readlink)", iterations: res.iterations, totalMS: res.totalMS,
        avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(),
      arguments: ["-y", "-c", "readlink -f \(link.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("readlink wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS))",
    )
  }
}

@Test("Perf(Native CLI): mkdir wrappers")
func perf_mkdir_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "mkdir-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let dir = tmp.appendingPathComponent("exists")
  try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("mkdir"), arguments: ["-p", dir.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/mkdir"), arguments: ["-p", dir.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["mkdir -p \(dir.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("mkdir"), arguments: ["-p", dir.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(mkdir)", iterations: res.iterations, totalMS: res.totalMS,
        avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(),
      arguments: ["-y", "-c", "mkdir -p \(dir.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("mkdir wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS))",
    )
  }
}

@Test("Perf(Native CLI): rm wrappers")
func perf_rm_wrappers() async throws {
  let cfg = PerfCfg()
  let base = CommonShell(executable: .path("/usr/bin/env"))
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "rm-perf-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  let miss = tmp.appendingPathComponent("missing.txt")
  struct Row {
    let wrapper: String
    let iterations: Int
    let totalMS: Double
    let avgMS: Double
  }
  var rows: [Row] = []
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("rm"), arguments: ["-f", miss.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "native", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .direct, executable: .path("/bin/rm"), arguments: ["-f", miss.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "direct", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .shell(options: []), executable: .path("/bin/sh"), arguments: ["rm -f \(miss.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "shell", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .env(options: []), executable: .name("rm"), arguments: ["-f", miss.path],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(
        wrapper: "env(rm)", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS,
      ))
  }
  do {
    let res = try await base.runForInterval(
      host: .npx(options: []), executable: .none(), arguments: ["-y", "-c", "rm -f \(miss.path)"],
      durationSeconds: cfg.seconds, targetHz: cfg.hz,
    )
    rows.append(
      .init(wrapper: "npx", iterations: res.iterations, totalMS: res.totalMS, avgMS: res.averageMS))
  }
  print("rm wrapper,iterations,total_ms,avg_ms")
  for r in rows {
    print(
      "\(r.wrapper),\(r.iterations),\(String(format: "%.1f", r.totalMS)),\(String(format: "%.3f", r.avgMS))",
    )
  }
}
