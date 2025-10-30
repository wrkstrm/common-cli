import CommonProcess
import CommonShell

/// Supported configurations for `swift build`.
public enum SwiftBuildConfiguration: String, Sendable, CaseIterable {
  case debug
  case release

  /// Value forwarded to the `--configuration` flag.
  public var argumentValue: String { rawValue }
}

/// Strongly typed name for `swift build --product`.
public struct SwiftBuildProduct: Sendable, Hashable, ExpressibleByStringLiteral {
  public let name: String

  public init(name: String) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    precondition(!trimmed.isEmpty, "Product name must not be empty")
    self.name = trimmed
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }

  /// Value forwarded to the `--product` flag.
  public var argumentValue: String { name }
}

/// Canonical wrapper for `swift build --package-path`.
public struct SwiftPackagePath: Sendable, Hashable, ExpressibleByStringLiteral {
  public let path: String

  public init(path: String) {
    precondition(!path.isEmpty, "Package path must not be empty")
    self.path = path
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(path: value)
  }

  /// Value forwarded to the `--package-path` flag.
  public var argumentValue: String { path }
}

/// Wrapper for the `swift` tool.
public struct SwiftTool: CLI, Versioned {
  public static let executable: Executable = .name("swift")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  /// Run `swift build` with raw extra arguments.
  public func build(_ extra: [String] = []) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: ["build"] + extra)
  }

  /// Run `swift build` with typed configuration, product, and package path options.
  public func build(
    configuration: SwiftBuildConfiguration? = nil,
    product: SwiftBuildProduct? = nil,
    packagePath: SwiftPackagePath? = nil
  ) async throws -> String {
    let options = SwiftBuildOptions(
      configuration: configuration,
      product: product,
      packagePath: packagePath
    )
    return try await shell.runConfigured(
      executable: Self.executable,
      arguments: options.makeArguments()
    )
  }

  /// Run `swift package describe --type json` and return JSON.
  public func packageDescribeJSON() async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["package", "describe", "--type", "json"])
  }

  /// Run unit tests via `swift test`.
  public func test(
    filter: String? = nil, parallel: Bool = true, enableCodeCoverage: Bool = false,
    extra: [String] = [],
  ) async throws -> String {
    var args = ["test"]
    if enableCodeCoverage { args.append("--enable-code-coverage") }
    if parallel { args.append("--parallel") }
    if let filter { args += ["--filter", filter] }
    args.append(contentsOf: extra)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  /// Run an executable product via `swift run [--configuration <cfg>] <product> [args...]`.
  public func runExecutable(
    product: String? = nil, args: [String] = [], configuration: String? = nil, extra: [String] = [],
  ) async throws -> String {
    var runArgs = ["run"]
    if let configuration { runArgs += ["--configuration", configuration] }
    runArgs.append(contentsOf: extra)
    if let product { runArgs.append(product) }
    runArgs.append(contentsOf: args)
    return try await shell.runConfigured(executable: Self.executable, arguments: runArgs)
  }

  /// Run arbitrary `swift` subcommand.
  public func run(_ args: [String]) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  // MARK: - Package helpers

  /// Run `swift package resolve` with optional extra flags.
  public func packageResolve(extra: [String] = []) async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["package", "resolve"] + extra)
  }

  /// Run `swift package update` (optionally limit to select packages with `--package`).
  public func packageUpdate(packages: [String] = [], extra: [String] = []) async throws -> String {
    var args = ["package", "update"]
    for p in packages {
      args += ["--package", p]
    }
    args.append(contentsOf: extra)
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  /// Initialize a Swift package: type can be 'library' or 'executable'.
  public func packageInit(type: String = "library", name: String? = nil) async throws -> String {
    var args = ["package", "init", "--type", type]
    if let name { args += ["--name", name] }
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  /// Show package dependencies in JSON or text.
  public func packageShowDependencies(format: String? = nil) async throws -> String {
    var args = ["package", "show-dependencies"]
    if let format { args += ["--format", format] }
    return try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  /// Dump the package manifest as JSON.
  public func packageDumpManifest() async throws -> String {
    try await shell.runConfigured(
      executable: Self.executable, arguments: ["package", "dump-package"])
  }
}

extension CommonShell { public var swift: SwiftTool { .init(shell: self) } }

// MARK: - Helpers

struct SwiftBuildOptions: Sendable, Hashable {
  var configuration: SwiftBuildConfiguration?
  var product: SwiftBuildProduct?
  var packagePath: SwiftPackagePath?

  func makeArguments() -> [String] {
    var arguments: [String] = ["build"]
    if let configuration {
      arguments.append(contentsOf: ["--configuration", configuration.argumentValue])
    }
    if let product, !product.argumentValue.isEmpty {
      arguments.append(contentsOf: ["--product", product.argumentValue])
    }
    if let packagePath {
      arguments.append(contentsOf: ["--package-path", packagePath.argumentValue])
    }
    return arguments
  }
}
