import CommonProcess
import CommonShell

/// Wrapper for the npm CLI with typed helpers for common commands.
public struct Npm: CLI, Versioned {
  public static let executable: Executable = .name("npm")
  public var shell: CommonShell

  public init(shell: CommonShell) {
    self.shell = shell
  }

  /// Run an arbitrary npm command.
  public func run(_ arguments: [String]) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable,
      host: .npm(options: []),
      arguments: arguments
    )
  }

  /// Run `npm exec` with typed options.
  public func exec(options: NpmExecOptions) async throws -> String {
    try await run(options.makeArguments())
  }

  /// Run `npm run` with typed options.
  public func runScript(options: NpmRunOptions) async throws -> String {
    try await run(options.makeArguments())
  }
}

public struct NpmExecOptions: Sendable, Hashable {
  public var packageNames: [String]
  public var command: String
  public var arguments: [String]
  public var yes: Bool

  public init(
    packageNames: [String] = [],
    command: String,
    arguments: [String] = [],
    yes: Bool = true
  ) {
    let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
    precondition(!trimmedCommand.isEmpty, "Command must not be empty")
    self.packageNames = packageNames.filter {
      !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    self.command = trimmedCommand
    self.arguments = arguments
    self.yes = yes
  }

  public func makeArguments() -> [String] {
    var output: [String] = ["exec"]
    if yes { output.append("--yes") }
    for packageName in packageNames {
      output.append(contentsOf: ["--package", packageName])
    }
    // Separator ensures subsequent flags go to the package binary, not npm itself.
    output.append("--")
    output.append(command)
    output.append(contentsOf: arguments)
    return output
  }
}

public struct NpmRunOptions: Sendable, Hashable {
  public var scriptName: String
  public var arguments: [String]
  public var ifPresent: Bool
  public var silent: Bool

  public init(
    scriptName: String,
    arguments: [String] = [],
    ifPresent: Bool = false,
    silent: Bool = false
  ) {
    let trimmedScriptName = scriptName.trimmingCharacters(in: .whitespacesAndNewlines)
    precondition(!trimmedScriptName.isEmpty, "Script name must not be empty")
    self.scriptName = trimmedScriptName
    self.arguments = arguments
    self.ifPresent = ifPresent
    self.silent = silent
  }

  public func makeArguments() -> [String] {
    var output: [String] = ["run"]
    if ifPresent { output.append("--if-present") }
    if silent { output.append("--silent") }
    output.append(scriptName)
    if !arguments.isEmpty {
      output.append("--")
      output.append(contentsOf: arguments)
    }
    return output
  }
}

extension CommonShell {
  public var npm: Npm { .init(shell: self) }
}
