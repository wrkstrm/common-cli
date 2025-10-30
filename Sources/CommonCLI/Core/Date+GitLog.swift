import Foundation

extension DateFormatter {
  /// Formatter matching the default git log timestamp (e.g. `2024-09-21 12:34:56 +0000`).
  public static let gitLog: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

extension Date {
  /// Initializes a date from the git log timestamp representation.
  /// Returns `nil` when the string cannot be parsed with ``DateFormatter/gitLog``.
  public init?(gitLogString: String) {
    guard let value = DateFormatter.gitLog.date(from: gitLogString) else {
      return nil
    }
    self = value
  }
}
