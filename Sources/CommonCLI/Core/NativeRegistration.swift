import CommonShell
import Foundation

// Register native handlers with CommonShell for unified execution/instrumentation.
private enum _CommonCLINativeRegistration {
  static func bootstrap() {
    // Native handler registry is disabled in this revision.
  }
}

// Trigger registration on module load.
private let _swiftcli_native_bootstrap: Void = { _CommonCLINativeRegistration.bootstrap() }()
