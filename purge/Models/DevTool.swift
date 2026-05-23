import Foundation

struct DevTool: Identifiable, Hashable {
    let id = UUID()
    /// Canonical `explanations.json` key used for safety copy and grouping.
    let definitionKey: String
    let toolName: String
    let paths: [URL]
    let sizeBytes: Int64
    var isSelected: Bool
    let isDetected: Bool
    var safetyInfo: SafetyInfo

    /// Path used as the user-override key. Defaults to the first declared path
    /// because a tool entry typically resolves to a single canonical folder.
    var primaryOverridePath: URL? { paths.first }

    var formattedSize: String {
        formatBytes(sizeBytes)
    }
}
