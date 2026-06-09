import Foundation

struct OnboardingSizeComparisonItem: Identifiable, Equatable {
  let symbol: String
  let label: String

  var id: String { symbol + label }
}

enum OnboardingSizeComparison {
  private static let oneMegabyte: Int64 = 1024 * 1024

  static func items(for bytes: Int64) -> [OnboardingSizeComparisonItem]? {
    guard bytes >= oneMegabyte else { return nil }

    var comparisons: [OnboardingSizeComparisonItem] = []

    let photoCount = roundedCount(bytes, perUnit: MediaSizeReference.bytesPerPhoto)
    if photoCount >= 100 {
      comparisons.append(
        OnboardingSizeComparisonItem(
          symbol: "photo.fill",
          label: countPhrase(photoCount, singular: "photo", plural: "photos")
        )
      )
    }

    let songCount = roundedCount(bytes, perUnit: MediaSizeReference.bytesPerSong)
    if songCount >= 100 {
      comparisons.append(
        OnboardingSizeComparisonItem(
          symbol: "music.note",
          label: countPhrase(songCount, singular: "song", plural: "songs")
        )
      )
    }

    if comparisons.count < 2 {
      let videoHours = roundedCount(bytes, perUnit: MediaSizeReference.bytesPerHDVideoHour)
      if videoHours >= 1 {
        let hoursLabel = videoHours == 1 ? "hour of HD video" : "hours of HD video"
        comparisons.append(
          OnboardingSizeComparisonItem(
            symbol: "film.fill",
            label: "\(formatCount(videoHours)) \(hoursLabel)"
          )
        )
      }
    }

    if comparisons.count < 2 {
      let pdfCount = roundedCount(bytes, perUnit: MediaSizeReference.bytesPerPDF)
      if pdfCount >= 1 {
        comparisons.append(
          OnboardingSizeComparisonItem(
            symbol: "doc.fill",
            label: countPhrase(pdfCount, singular: "PDF document", plural: "PDF documents")
          )
        )
      }
    }

    guard !comparisons.isEmpty else { return nil }

    return Array(comparisons.prefix(2))
  }

  private static func roundedCount(_ bytes: Int64, perUnit: Int64) -> Int {
    Int((Double(bytes) / Double(perUnit)).rounded())
  }

  private static func countPhrase(_ count: Int, singular: String, plural: String) -> String {
    let label = count == 1 ? singular : plural
    return "\(formatCount(count)) \(label)"
  }

  private static func formatCount(_ count: Int) -> String {
    NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
  }
}
