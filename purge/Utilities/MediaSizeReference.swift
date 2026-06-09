import Foundation

enum MediaSizeReference {
  private static let mb: Int64 = 1024 * 1024
  private static let gb: Int64 = 1024 * 1024 * 1024

  static let bytesPerPhoto: Int64 = 4 * mb
  static let bytesPerSong: Int64 = 8 * mb
  static let bytesPerPDF: Int64 = 2 * mb
  static let bytesPerHDVideoHour: Int64 = 1_500 * mb
  static let bytesPer4KVideoHour: Int64 = 7 * gb
}
