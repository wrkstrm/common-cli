import CommonShell
import Testing

@testable import CommonCLI

@Test("Echo CLI echoes arguments")
func echoCLI() async throws {
  let cli = Echo(shell: CommonShell(executable: .path("/bin/echo")))
  let output = try await cli.echo("hello")
  #expect(output == "hello\n")
}

@Test("Swift CLI builds command arguments")
func swiftCLIRendersCommands() async throws {
  let swift = SwiftTool(shell: CommonShell(executable: .name("swift")))
  // Run a harmless subcommand (--version) to confirm binding works.
  let out = try await swift.run(["--version"])
  #expect(!out.isEmpty)
}

@Test("Swift build typed options emit expected arguments")
func swiftBuildTypedArguments() {
  let options = SwiftBuildOptions(
    configuration: .release,
    product: SwiftBuildProduct(name: "ChaosShell"),
    packagePath: SwiftPackagePath(path: "/tmp/pkg")
  )
  let arguments = options.makeArguments()
  #expect(
    arguments == [
      "build",
      "--configuration", "release",
      "--product", "ChaosShell",
      "--package-path", "/tmp/pkg",
    ])
}

@Test("Swift build product trims whitespace")
func swiftBuildProductTrimsWhitespace() {
  let product = SwiftBuildProduct(name: "  example  ")
  #expect(product.argumentValue == "example")
}

@Test("Swiftc typed options emit expected arguments")
func swiftcTypedArguments() {
  let options = SwiftcCompileOptions(
    source: SwiftcSource(path: "main.swift"),
    output: SwiftcOutput(path: ".build/out"),
    extra: ["-emit-executable"]
  )
  #expect(
    options.makeArguments() == ["main.swift", "-o", ".build/out", "-emit-executable"]
  )
}
