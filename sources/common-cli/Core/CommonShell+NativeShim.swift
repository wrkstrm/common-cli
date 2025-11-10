import CommonProcess
import CommonShell

// Temporary shim: CommonShell no longer manages a native handler registry.
// Keep a no-op API here so existing registration code compiles without behavior.
extension CommonShell {
  public typealias NativeHandler = (CommonShell, Executable) async throws -> String
  public static func registerNativeHandler(name _: String, handler _: @escaping NativeHandler) {
    // No-op: native handlers are not routed through CommonShell in this revision.
  }
}
