import CommonProcess
import CommonShell
import Foundation

extension CommonShell {
  /// Preferred default host mapping for a given executable reference.
  public static func preferredHost(for executable: Executable) -> ExecutionHostKind {
    switch executable.ref {
    case .path: return .direct
    case .name: return .env(options: [])
    case .none: return .shell(options: [])
    }
  }
}
