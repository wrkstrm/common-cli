// swift-tools-version:6.1
import Foundation
import PackageDescription

// MARK: - Configuration Service

// Dependency injection hook (local/remote) matches CommonShell/CommonProcess pattern.
// No overrides here; see Inject.local/remote below for definitions.

// MARK: - Package Declaration

let package = Package(
  name: "CommonCLI",
  platforms: [
    .macOS(.v14), .iOS(.v17), .macCatalyst(.v17),
  ],
  products: [
    .library(name: "CommonCLI", targets: ["CommonCLI"]),
    .executable(name: "common-cli-perf", targets: ["CommonCLIPerf"]),
  ],
  dependencies: Package.Inject.shared.dependencies + [],
  targets: [
    .target(
      name: "CommonCLI",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
      ],
      path: "Sources/CommonCLI",
      swiftSettings: Package.Inject.shared.swiftSettings,
    ),
    .testTarget(
      name: "CommonCLIMacOSTests",
      dependencies: ["CommonCLI"],
      path: "Tests/CommonCLIMacOSTests",
    ),
    .executableTarget(
      name: "CommonCLIPerf",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonShellPerf", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
      ],
      path: "Sources/CommonCLIPerf",
      swiftSettings: Package.Inject.shared.swiftSettings,
    ),
  ],
)

// MARK: - Package Service

print("---- Package Inject Deps: Begin ----")
print("Use Local Deps? \(ProcessInfo.useLocalDeps)")
print(Package.Inject.shared.dependencies.map(\.kind))
print("---- Package Inject Deps: End ----")

extension Package {
  @MainActor
  public struct Inject {
    public static let version = "1.0.0"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject = ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Inject = .init(
      swiftSettings: [.local],
      dependencies: [
        .package(path: "../common-shell"),
        .package(path: "../common-process"),
      ]
    )
    static var remote: Inject = .init(
      dependencies: [
        .package(url: "https://github.com/wrkstrm/common-shell.git", from: "0.1.0"),
        .package(url: "https://github.com/wrkstrm/common-process.git", from: "0.2.0"),
      ]
    )
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// PACKAGE_SERVICE_END_V1
