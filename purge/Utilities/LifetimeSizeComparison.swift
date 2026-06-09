import Foundation

enum LifetimeSizeComparison {
  private static let bytesPer4KVideoHour: Int64 = 10_000_000_000
  private static let bytesPerHDVideoHour: Int64 = 3_000_000_000
  private static let bytesPerSong: Int64 = 4_000_000
  private static let bytesPerPhoto: Int64 = 5_000_000

  static func item(for bytes: Int64) -> OnboardingSizeComparisonItem? {
    guard bytes > 0 else { return nil }

    if bytes >= bytesPer4KVideoHour {
      let hours = roundedCount(bytes, perUnit: bytesPer4KVideoHour)
      let hoursLabel = hours == 1 ? "hour of 4K video" : "hours of 4K video"
      return OnboardingSizeComparisonItem(
        symbol: "film.fill",
        label: "\(formatCount(hours)) \(hoursLabel)"
      )
    }

    if bytes >= bytesPerHDVideoHour {
      let hours = roundedCount(bytes, perUnit: bytesPerHDVideoHour)
      let hoursLabel = hours == 1 ? "hour of HD video" : "hours of HD video"
      return OnboardingSizeComparisonItem(
        symbol: "film",
        label: "\(formatCount(hours)) \(hoursLabel)"
      )
    }

    if bytes >= bytesPerSong {
      let songCount = max(1, roundedCount(bytes, perUnit: bytesPerSong))
      let songLabel = songCount == 1 ? "song" : "songs"
      return OnboardingSizeComparisonItem(
        symbol: "music.note",
        label: "\(formatCount(songCount)) \(songLabel)"
      )
    }

    let photoCount = max(1, roundedCount(bytes, perUnit: bytesPerPhoto))
    let photoLabel = photoCount == 1 ? "photo" : "photos"
    return OnboardingSizeComparisonItem(
      symbol: "photo.fill",
      label: "\(formatCount(photoCount)) \(photoLabel)"
    )
  }

  private static func roundedCount(_ bytes: Int64, perUnit: Int64) -> Int {
    Int((Double(bytes) / Double(perUnit)).rounded())
  }

  private static func formatCount(_ count: Int) -> String {
    NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
  }
}
