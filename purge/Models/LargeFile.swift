import Foundation
import SwiftUI

enum LargeFileCategory: String, CaseIterable, Identifiable, Hashable {
    case video
    case audio
    case image
    case pdf
    case archive
    case document
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .video: return "Videos"
        case .audio: return "Audio"
        case .image: return "Images"
        case .pdf: return "PDFs"
        case .archive: return "Archives"
        case .document: return "Documents"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .video: return "film"
        case .audio: return "music.note"
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .archive: return "archivebox"
        case .document: return "doc.text"
        case .other: return "doc"
        }
    }

    static func category(forExtension ext: String) -> LargeFileCategory {
        switch ext.lowercased() {
        case "mov", "mp4", "m4v", "avi", "mkv", "wmv", "flv", "webm", "mpg", "mpeg", "hevc", "prores":
            return .video
        case "mp3", "wav", "aac", "flac", "m4a", "aiff", "aif", "ogg", "wma":
            return .audio
        case "jpg", "jpeg", "png", "gif", "tiff", "tif", "bmp", "heic", "heif", "raw", "psd", "webp", "svg":
            return .image
        case "pdf":
            return .pdf
        case "zip", "rar", "7z", "tar", "gz", "bz2", "dmg", "pkg", "iso", "xip":
            return .archive
        case "doc", "docx", "pages", "xls", "xlsx", "numbers", "ppt", "pptx", "key", "txt", "rtf", "csv", "epub":
            return .document
        default:
            return .other
        }
    }
}

struct LargeFile: Identifiable, Hashable {
    let path: URL
    let sizeBytes: Int64
    /// Most recent of last-accessed and last-modified. The file's last touched time.
    let lastUsed: Date
    let category: LargeFileCategory
    var isSelected: Bool = false

    var id: String { path.standardizedFileURL.path }
    var displayName: String { path.lastPathComponent }
    var formattedSize: String { formatBytes(sizeBytes) }
    var locationLabel: String { path.deletingLastPathComponent().lastPathComponent }
}

enum LargeFileSizeThreshold: Int, CaseIterable, Identifiable {
    case mb100 = 100
    case mb250 = 250
    case mb500 = 500
    case gb1 = 1024
    case gb2 = 2048

    static let userDefaultsKey = "largeFiles.minSizeMB"
    static let defaultOption: LargeFileSizeThreshold = .mb100

    var id: Int { rawValue }
    var bytes: Int64 { Int64(rawValue) * 1024 * 1024 }

    var label: String {
        switch self {
        case .mb100: return "100 MB"
        case .mb250: return "250 MB"
        case .mb500: return "500 MB"
        case .gb1: return "1 GB"
        case .gb2: return "2 GB"
        }
    }

    static func current(userDefaults: UserDefaults = .standard) -> LargeFileSizeThreshold {
        LargeFileSizeThreshold(rawValue: userDefaults.integer(forKey: userDefaultsKey)) ?? defaultOption
    }
}

enum LargeFileAgeThreshold: Int, CaseIterable, Identifiable {
    case months3 = 90
    case months6 = 180
    case year1 = 365
    case years2 = 730

    static let userDefaultsKey = "largeFiles.minAgeDays"
    static let defaultOption: LargeFileAgeThreshold = .months6

    var id: Int { rawValue }
    var days: Int { rawValue }

    var label: String {
        switch self {
        case .months3: return "3 months"
        case .months6: return "6 months"
        case .year1: return "1 year"
        case .years2: return "2 years"
        }
    }

    static func current(userDefaults: UserDefaults = .standard) -> LargeFileAgeThreshold {
        LargeFileAgeThreshold(rawValue: userDefaults.integer(forKey: userDefaultsKey)) ?? defaultOption
    }
}
