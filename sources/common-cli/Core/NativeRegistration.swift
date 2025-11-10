import CommonShell
import Foundation

// Register native handlers with CommonShell for unified execution/instrumentation.
private enum _CommonCLINativeRegistration {
  static func bootstrap() {
    // Native handler registry is disabled in this revision.
  }
}

// Trigger registration on module load.
private let swiftcliNativeBootstrap: Void = { _CommonCLINativeRegistration.bootstrap() }()
