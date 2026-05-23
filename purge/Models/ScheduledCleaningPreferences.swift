import Foundation

enum ScheduledCleaningFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Every 3 months"
        }
    }

    /// Seconds between repeats (local notification + graceful activation sweep).
    var repeatIntervalSeconds: TimeInterval {
        switch self {
        case .weekly: return 7 * 24 * 60 * 60
        case .monthly: return 30 * 24 * 60 * 60
        case .quarterly: return 90 * 24 * 60 * 60
        }
    }
}

enum ScheduledCleaningUnusedDaysOption: Int, Codable, CaseIterable, Identifiable {
    case days30 = 30
    case days60 = 60
    case days90 = 90
    case months6 = 180
    case months12 = 365

    /// Minimum staleness for developer artifacts in scheduled cleaning (6× user threshold, floored here).
    static let developerArtifactFloorDays = 180

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .days30: return "30 days"
        case .days60: return "60 days"
        case .days90: return "90 days"
        case .months6: return "6 months"
        case .months12: return "12 months"
        }
    }

    var summaryDurationPhrase: String { label }

    /// User-facing threshold for app caches in scheduled cleaning.
    var cacheStaleDays: Int { rawValue }

    /// Internal threshold for project artifacts and global dev tool folders (6× selection, 6-month floor).
    var developerArtifactStaleDays: Int {
        max(Self.developerArtifactFloorDays, rawValue * 6)
    }

    /// Reads the configured developer-artifact staleness threshold without `@MainActor`.
    nonisolated static func currentDeveloperArtifactStaleDays(userDefaults: UserDefaults = .standard) -> Int {
        let raw = userDefaults.integer(forKey: "scheduledClean.staleDays")
        let days = raw == 0 ? ScheduledCleaningUnusedDaysOption.months6.rawValue : raw
        let option = ScheduledCleaningUnusedDaysOption(rawValue: days) ?? .months6
        return option.developerArtifactStaleDays
    }
}
