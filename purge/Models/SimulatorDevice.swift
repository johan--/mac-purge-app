import Foundation

struct SimulatorDevice: Identifiable, Hashable {
    let id: UUID
    let deviceName: String
    let runtimeVersion: String
    let isAvailable: Bool
    let lastBootedAt: Date?
    /// `nil` while folder sizing is still running.
    var sizeOnDisk: Int64?
    let folderURL: URL
    var isSelected: Bool
    let safetyInfo: SafetyInfo

    var formattedSize: String {
        guard let sizeOnDisk else { return "Calculating…" }
        return formatBytes(sizeOnDisk)
    }

    /// Children that are not "Do Not Delete" — parent checkbox toggles these.
    var isDanger: Bool { safetyInfo.level == .danger }

    static func safetyInfo(
        isAvailable: Bool,
        lastBootedAt: Date?,
        deviceName: String,
        runtimeVersion: String
    ) -> SafetyInfo {
        let headline = "\(deviceName) — \(runtimeVersion)"
        if !isAvailable {
            return SafetyInfo(
                level: .safe,
                headline: headline,
                explanation: "This simulator's iOS runtime is no longer installed. It's safe to delete.",
                recoverySteps: "",
                reinstallCommand: nil
            )
        }
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? .distantPast
        let recentlyUsed: Bool
        if let last = lastBootedAt {
            recentlyUsed = last >= sixMonthsAgo
        } else {
            recentlyUsed = false
        }
        if recentlyUsed {
            return SafetyInfo(
                level: .danger,
                headline: headline,
                explanation: "This simulator was used recently. Deleting it will remove any app data installed on it.",
                recoverySteps: "",
                reinstallCommand: nil
            )
        }
        return SafetyInfo(
            level: .medium,
            headline: headline,
            explanation: "You haven't used this simulator recently. Safe to delete, but Xcode will need to recreate it if you use it again.",
            recoverySteps: "",
            reinstallCommand: nil
        )
    }
}
