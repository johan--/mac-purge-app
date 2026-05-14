import Foundation

/// Record from bundled `explanations.json`.
struct BundledExplanationRecord: Codable, Sendable {
    let displayName: String
    let tag: String
    let explanation: String
    let bundleIds: [String]?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case tag
        case explanation
        case bundleIds = "bundle_ids"
    }

    nonisolated var safetyLevel: SafetyLevel {
        switch tag.lowercased() {
        case "safe": return .safe
        case "medium": return .medium
        case "danger": return .danger
        case "unknown": return .unknown
        default: return .unknown
        }
    }
}

/// Intermediate type for decoding the JSON array format used by `explanations.json`.
private struct BundledArrayEntry: Codable {
    let key: String
    let displayName: String
    let tag: String
    let explanation: String
    let bundleIds: [String]?
    let aliases: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case displayName = "display_name"
        case tag
        case explanation
        case bundleIds = "bundle_ids"
        case aliases
    }

    var record: BundledExplanationRecord {
        BundledExplanationRecord(
            displayName: displayName,
            tag: tag,
            explanation: explanation,
            bundleIds: bundleIds
        )
    }
}

/// Loads and matches against explicit entries in the local explanation database.
enum ExplanationDatabase {
    private nonisolated(unsafe) static var cachedRecords: [String: BundledExplanationRecord]?
    private nonisolated(unsafe) static var cachedBundleIndex: [String: BundledExplanationRecord]?
    private nonisolated(unsafe) static var cachedAliasIndex: [String: BundledExplanationRecord]?

    private nonisolated static func loadFromBundle() -> [String: BundledExplanationRecord] {
        if let cachedRecords { return cachedRecords }
        guard let url = Bundle.main.url(forResource: "explanations", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            cachedRecords = [:]
            cachedBundleIndex = [:]
            cachedAliasIndex = [:]
            return [:]
        }

        if let array = try? JSONDecoder().decode([BundledArrayEntry].self, from: data) {
            var dict: [String: BundledExplanationRecord] = [:]
            var aliasIndex: [String: BundledExplanationRecord] = [:]
            for entry in array {
                let rec = entry.record
                dict[entry.key] = rec
                if let aliases = entry.aliases {
                    for alias in aliases {
                        aliasIndex[alias.lowercased()] = rec
                    }
                }
            }
            cachedRecords = dict
            cachedAliasIndex = aliasIndex
            return dict
        }

        if let decoded = try? JSONDecoder().decode([String: BundledExplanationRecord].self, from: data) {
            cachedRecords = decoded
            cachedAliasIndex = [:]
            return decoded
        }

        cachedRecords = [:]
        cachedBundleIndex = [:]
        cachedAliasIndex = [:]
        return [:]
    }

    private nonisolated static func aliasIndex() -> [String: BundledExplanationRecord] {
        if let cachedAliasIndex { return cachedAliasIndex }
        _ = loadFromBundle()
        return cachedAliasIndex ?? [:]
    }

    private nonisolated static func bundleIdIndex() -> [String: BundledExplanationRecord] {
        if let cachedBundleIndex { return cachedBundleIndex }
        let dict = loadFromBundle()
        var index: [String: BundledExplanationRecord] = [:]
        for record in dict.values {
            guard let bundleIds = record.bundleIds else { continue }
            for id in bundleIds {
                index[id.lowercased()] = record
            }
        }
        cachedBundleIndex = index
        return index
    }

    /// Keys, aliases, and bundle IDs. All matching is case-insensitive.
    nonisolated static func matchBundledDatabase(folderName: String) -> BundledExplanationRecord? {
        let lower = folderName.lowercased()
        let dict = loadFromBundle()

        if let record = dict.first(where: { $0.key.lowercased() == lower })?.value {
            return record
        }

        if let record = aliasIndex()[lower] {
            return record
        }

        if let record = bundleIdIndex()[lower] {
            return record
        }

        return nil
    }

    nonisolated static func safetyInfo(from record: BundledExplanationRecord, reinstallCommand: String? = nil) -> SafetyInfo {
        SafetyInfo(
            level: record.safetyLevel,
            headline: record.displayName,
            explanation: record.explanation,
            recoverySteps: "",
            reinstallCommand: reinstallCommand
        )
    }

    /// Unknown bundled keys: conservative copy for dev-tool-only local path.
    nonisolated static let unsureExplanation = "We are not sure what this is. We recommend leaving it alone."

    nonisolated static func safetyInfoForUnknownBundledLookup(friendlyFallback: String) -> SafetyInfo {
        SafetyInfo(
            level: .unknown,
            headline: friendlyFallback,
            explanation: unsureExplanation,
            recoverySteps: "",
            reinstallCommand: nil
        )
    }
}
