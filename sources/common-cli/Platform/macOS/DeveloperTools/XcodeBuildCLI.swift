import CommonProcess
import CommonShell
import Foundation

public struct XcodeBuild: CLI {
  public static var executable: Executable { .name("xcodebuild") }
  public let shell: CommonShell
  public init(
    shell: CommonShell = CommonShell(
      workingDirectory: FileManager.default.currentDirectoryPath,
      executable: Self.executable
    )
  ) {
    self.shell = Self.mutatedShell(shell: shell)
  }

  // List schemes via JSON; returns raw JSON string.
  public func listWorkspaceJSON(_ workspace: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["-list", "-json", "-workspace", workspace])
  }

  // List schemes via text; returns text output.
  public func listWorkspaceText(_ workspace: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["-list", "-workspace", workspace])
  }

  // Build a scheme for a destination and configuration.
  public func build(
    workspace: String, scheme: String, destination: String, configuration: String = "Debug",
    extra: [String] = [],
  ) async throws -> String {
    var args = [
      "-workspace", workspace, "-scheme", scheme, "-destination", destination, "-configuration",
      configuration, "-quiet", "-skipPackagePluginValidation", "build",
    ]
    args.append(contentsOf: extra)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  // Clean a scheme.
  public func clean(workspace: String, scheme: String) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["-workspace", workspace, "-scheme", scheme, "clean"])
  }
}
