import Foundation
import Logging
import CommonLog

/// Convenience helpers to configure logging for CLIs using CommonShell.
public enum ShellLogging: Sendable {
  /// Set the global exposure level used by CommonLog for this process.
  /// Use this in your CLI entrypoint based on flags like --log-level.
  public static func configureLogging(level: Logger.Level) {
    Log.globalExposureLevel = level
  }

  /// Parse a log level string into a swift-log Level.
  /// Accepts: silent, error, warn, warning, info, debug, verbose.
  public static func parseLogLevel(_ raw: String) -> Logger.Level? {
    switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "silent": .error
    case "error", "err": .error
    case "warn", "warning": .warning
    case "info", "information": .info
    case "debug", "verbose", "trace": .debug
    default: nil
    }
  }

  /// Configure logging from an optional user-provided string.
  /// Falls back to .info when parsing fails.
  public static func configureLogging(from rawLevel: String?) {
    if let rawLevel, let parsedLevel = parseLogLevel(rawLevel) {
      configureLogging(level: parsedLevel)
    } else {
      configureLogging(level: .info)
    }
  }
}
