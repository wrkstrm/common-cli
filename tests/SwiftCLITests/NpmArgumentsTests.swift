import Testing

@testable import CommonCLI

@Test("Npm exec emits typed arguments")
func npmExecArguments() {
  let options = NpmExecOptions(
    packageNames: ["@mermaid-js/mermaid-cli"],
    command: "mmdc",
    arguments: ["-i", "input.mmd", "-o", "output.svg", "--theme", "neutral"],
    yes: true
  )

  #expect(
    options.makeArguments() == [
      "exec",
      "--yes",
      "--package", "@mermaid-js/mermaid-cli",
      "mmdc",
      "-i", "input.mmd",
      "-o", "output.svg",
      "--theme", "neutral",
    ]
  )
}

@Test("Npm run emits script arguments")
func npmRunArguments() {
  let options = NpmRunOptions(
    scriptName: "lint",
    arguments: ["--fix"],
    ifPresent: true,
    silent: true
  )

  #expect(
    options.makeArguments() == [
      "run",
      "--if-present",
      "--silent",
      "lint",
      "--",
      "--fix",
    ]
  )
}
