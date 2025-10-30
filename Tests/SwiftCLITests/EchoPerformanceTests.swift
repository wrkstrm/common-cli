import CommonCLI
import CommonProcess
import CommonShell
import Foundation
import Testing

@Test("Perf: EchoNative vs Echo subprocess (smoke)")
func echoPerformanceComparison() async throws {
  // Keep iteration counts small to avoid slow CI.
  let iterations = 500

  let baseForSubprocess = CommonShell(executable: .path("/bin/echo"))
  let baseForNative = CommonShell(executable: .path("/usr/bin/env"))

  let echoCLI = Echo(shell: baseForSubprocess)
  let echoNativeCLI = EchoNative(shell: baseForNative)

  // Warm-up
  _ = try? await echoCLI.echo("warmup")
  _ = try? await echoNativeCLI.echo("warmup")

  func time(_ block: () async throws -> Void) async rethrows -> TimeInterval {
    let start = Date()
    try await block()
    return Date().timeIntervalSince(start)
  }

  let subprocTime = try await time {
    for index in 0..<iterations {
      _ = try await echoCLI.echo("s_\(index)")
    }
  }

  let nativeTime = try await time {
    for index in 0..<iterations {
      _ = try await echoNativeCLI.echo("n_\(index)")
    }
  }

  // Sanity expectations: both paths execute and report positive durations.
  #expect(subprocTime > 0)
  #expect(nativeTime > 0)

  // Emit a friendly comparison for humans reading test output.
  let ratio = subprocTime / max(nativeTime, 1e-9)
  print(
    String(
      format: "Echo perf (iters=%d): subprocess=%.4fs native=%.4fs ratio=%.2fx", iterations,
      subprocTime, nativeTime, ratio,
    ))
}
