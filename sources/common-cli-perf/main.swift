import CommonProcess
import CommonShell
import CommonShellBenchSupport
import CommonShellPerf
import Foundation

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

struct PerfInput: Decodable {
  enum Mode: String, Decodable { case duration, iterations }
  var mode: Mode
  var workingDirectory: String?
  var host: String
  var hostOptions: [String]?  // used for shell/env/npm/npx
  var executable: ExecutableInput
  var arguments: [String]? = []
  var runnerKind: String?  // auto|foundation|tscbasic|subprocess
  var seconds: Double?  // for duration
  var iterations: Int?  // for iterations
  var targetHz: Double?
  // Optional baseline comparison: fail if averageMS > baselineAverageMS * (toleranceFactor or 1.15)
  var baselineAverageMS: Double?
  var toleranceFactor: Double?

  struct ExecutableInput: Decodable {
    enum Kind: String, Decodable { case name, path, none }
    var kind: Kind
    var value: String?
  }
}

struct PerfOutput: Encodable {
  var iterations: Int
  var totalMS: Double
  var averageMS: Double
  var ok: Bool?
  var thresholdMS: Double?
}

func mapHost(_ input: PerfInput) -> ExecutionHostKind {
  let opts = input.hostOptions ?? []
  switch input.host.lowercased() {
  case "direct": return .direct
  case "shell": return .shell(options: opts)
  case "env": return .env(options: opts)
  case "npx": return .npx(options: opts)
  case "npm": return .npm(options: opts)
  default: return .direct
  }
}

func mapExecutable(_ input: PerfInput.ExecutableInput) -> Executable {
  switch input.kind {
  case .name: .name(input.value ?? "")
  case .path: .path(input.value ?? "")
  case .none: .none()
  }
}

func mapRunner(_ s: String?) -> ProcessRunnerKind? {
  guard let t = s?.lowercased() else { return nil }
  switch t {
  case "auto": return .auto
  case "foundation": return .foundation
  case "tscbasic": return .tscbasic
  case "subprocess": return .subprocess
  default: return nil
  }
}

@main
struct CommonCLIPerfTool {
  static func main() async throws {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    let input = try JSONDecoder().decode(PerfInput.self, from: data)
    var shell = CommonShell(executable: .none())
    if let wd = input.workingDirectory, !wd.isEmpty { shell.workingDirectory = wd }
    let host = mapHost(input)
    let exec = mapExecutable(input.executable)
    let args = input.arguments ?? []
    let runner = mapRunner(input.runnerKind)

    let result: ShellBenchmarkResult
    switch input.mode {
    case .duration:
      let seconds = input.seconds ?? 0.3
      result = try await shell.perfForInterval(
        host: host,
        executable: exec,
        arguments: args,
        environment: nil,
        runnerKind: runner,
        durationSeconds: seconds,
        targetHz: input.targetHz,
      )

    case .iterations:
      let iters = max(input.iterations ?? 1, 1)
      result = try await shell.perfIterations(
        host: host,
        executable: exec,
        arguments: args,
        environment: nil,
        runnerKind: runner,
        iterations: iters,
        targetHz: input.targetHz,
      )
    }
    // Baseline comparison (optional)
    var ok: Bool?
    var threshold: Double?
    if let base = input.baselineAverageMS {
      let tol = input.toleranceFactor ?? 1.15
      threshold = base * tol
      ok = (result.averageMS <= (threshold ?? .infinity))
    }

    let out = PerfOutput(
      iterations: result.iterations,
      totalMS: result.totalMS,
      averageMS: result.averageMS,
      ok: ok,
      thresholdMS: threshold,
    )
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    let json = try enc.encode(out)
    FileHandle.standardOutput.write(json)
    FileHandle.standardOutput.write(Data("\n".utf8))

    if let ok, let threshold, ok == false {
      let msg = "Perf FAIL: averageMS=\(result.averageMS) > thresholdMS=\(threshold)\n"
      FileHandle.standardError.write(Data(msg.utf8))
      #if canImport(Darwin)
      Darwin.exit(2)
      #else
      Glibc.exit(2)
      #endif
    }
  }
}
