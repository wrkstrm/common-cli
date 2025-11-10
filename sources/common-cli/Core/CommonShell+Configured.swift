import CommonProcess
import CommonShell

extension CommonShell {
  func configured(
    executable: Executable,
    host: ExecutionHostKind? = nil,
    workingDirectory: String? = nil
  ) -> CommonShell {
    var copy = self
    copy.executable = executable
    copy.hostKind = host ?? CommonShell.preferredHost(for: executable)
    if let workingDirectory, !workingDirectory.isEmpty {
      copy.workingDirectory = workingDirectory
    }
    return copy
  }

  func runConfigured(
    executable: Executable,
    host: ExecutionHostKind? = nil,
    workingDirectory: String? = nil,
    argumentPrefix: [String] = [],
    arguments: [String],
    environment: [String: String]? = nil,
    runnerKind: ProcessRunnerKind? = nil
  ) async throws -> String {
    let shell = configured(
      executable: executable,
      host: host,
      workingDirectory: workingDirectory
    )
    let resolvedHost = shell.hostKind ?? CommonShell.preferredHost(for: executable)
    return try await shell.run(
      host: resolvedHost,
      executable: executable,
      arguments: argumentPrefix + arguments,
      environment: environment,
      runnerKind: runnerKind
    )
  }

  @MainActor
  func launchConfigured(
    executable: Executable,
    host _: ExecutionHostKind? = nil,
    workingDirectory: String? = nil,
    argumentPrefix: [String] = [],
    arguments: [String]
  ) async throws -> ProcessOutput {
    let shell = configured(
      executable: executable,
      workingDirectory: workingDirectory
    )
    return try await shell.launch(options: argumentPrefix + arguments)
  }
}
