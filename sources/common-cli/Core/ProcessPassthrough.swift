import CommonProcess
import CommonShell
import Foundation

extension CommonShell {
  /// Run an executable and passthrough its stdout/stderr to the current process's stdio.
  /// Returns the raw exit code (or signal code when signalled).
  public func runPassthrough(
    executable: Executable,
    arguments: [String],
    environment: [String: String]? = nil,
    runnerKind: ProcessRunnerKind? = nil,
    workingDirectory: String? = nil
  ) async throws -> Int32 {
    var shell = self
    if let wd = workingDirectory, !wd.isEmpty { shell.workingDirectory = wd }
    let resolvedHost = CommonShell.preferredHost(for: executable)
    shell.executable = executable
    shell.hostKind = resolvedHost

    let (events, _) = shell.stream(
      arguments: arguments,
      environment: environment,
      runnerKind: runnerKind,
      timeout: nil
    )

    var status: Int32 = 0
    for try await event in events {
      switch event {
      case .stdout(let data):
        if !data.isEmpty { FileHandle.standardOutput.write(data) }
      case .stderr(let data):
        if !data.isEmpty { FileHandle.standardError.write(data) }
      case .completed(let exit, _):
        switch exit {
        case .exited(let code): status = Int32(code)
        case .signalled(let sig): status = Int32(sig)
        }
      }
    }
    return status
  }

  /// Launch a command via /bin/sh in detached mode using nohup and backgrounding.
  /// Example: launchDetached(command: "swift run --package-path MyPkg").
  @discardableResult
  public func launchDetached(
    command: String,
    shellPath: String = "/bin/sh",
    workingDirectory: String? = nil
  ) async throws -> String {
    var shell = self
    if let wd = workingDirectory, !wd.isEmpty { shell.workingDirectory = wd }
    let sh = Executable.path(shellPath)
    let cmd = "nohup \(command) >/dev/null 2>&1 &"
    _ = try await shell.run(host: .direct, executable: sh, arguments: ["-lc", cmd])
    return command
  }
}
