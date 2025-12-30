import CommonProcess
import CommonShell
import Foundation

/// Wrapper for `swiftc` compiler with a simple compile helper.
public struct Swiftc: CLI {
  public static let executable: Executable = .name("swiftc")
  public var shell: CommonShell
  public init(shell: CommonShell) { self.shell = shell }

  /// Compile a Swift source file to the given output path.
  public func compile(
    source: SwiftcSource,
    output: SwiftcOutput,
    extra: [String] = []
  ) async throws -> String {
    let options = SwiftcCompileOptions(source: source, output: output, extra: extra)
    return try await shell.runConfigured(
      executable: Self.executable,
      arguments: options.makeArguments()
    )
  }

  /// Compile with typed `swiftc` arguments.
  public func compile(options: SwiftcCompileOptions) async throws -> String {
    return try await shell.runConfigured(
      executable: Self.executable,
      arguments: options.makeArguments()
    )
  }
}

extension CommonShell { public var swiftc: Swiftc { .init(shell: self) } }

// MARK: - Typed arguments

public struct SwiftcSource: Sendable, Hashable, ExpressibleByStringLiteral {
  public let path: String

  public init(path: String) {
    precondition(!path.isEmpty, "Source path must not be empty")
    self.path = path
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(path: value)
  }
}

public struct SwiftcOutput: Sendable, Hashable, ExpressibleByStringLiteral {
  public let path: String

  public init(path: String) {
    precondition(!path.isEmpty, "Output path must not be empty")
    self.path = path
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(path: value)
  }
}

public struct SwiftcCompileOptions: Sendable, Hashable {
  public var source: SwiftcSource
  public var output: SwiftcOutput
  public var extra: [String]

  public init(source: SwiftcSource, output: SwiftcOutput, extra: [String] = []) {
    self.source = source
    self.output = output
    self.extra = extra
  }

  public func makeArguments() -> [String] {
    var args = [source.path, "-o", output.path]
    if !extra.isEmpty {
      args.append(contentsOf: extra)
    }
    return args
  }
}
