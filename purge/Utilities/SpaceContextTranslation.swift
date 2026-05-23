import Foundation

enum SpaceContextTranslation {
  /// Rough average photo size for friendly comparisons.
  private static let bytesPerPhoto: Int64 = 5 * 1024 * 1024

  static func phrase(for freedBytes: Int64) -> String {
    guard freedBytes > 0 else {
      return "Your Mac has a little more breathing room."
    }
    let photos = max(1, Int((Double(freedBytes) / Double(bytesPerPhoto)).rounded()))
    let formatted = NumberFormatter.localizedString(from: NSNumber(value: photos), number: .decimal)
    if photos == 1 {
      return "That's about \(formatted) photo worth of space."
    }
    return "That's about \(formatted) photos worth of space."
  }
}
