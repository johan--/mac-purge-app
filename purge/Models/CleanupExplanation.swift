import Foundation

extension SafetyInfo {
    /// Local `explanations.json` only (no live AI). Used for dev tool rows.
    /// When `path` is supplied, a manual user override at that exact path
    /// takes priority and is returned instead.
    nonisolated static func fromExplanationDatabase(
        key: String,
        friendlyFallback: String? = nil,
        reinstallCommand: String? = nil,
        path: URL? = nil
    ) -> SafetyInfo {
        let fallback = friendlyFallback ?? key

        if let path,
           let override = UserOverridesStore.read(path: path) {
            let info = UserOverridesStore.safetyInfo(from: override, friendlyHeadline: fallback)
            return SafetyInfo(
                level: info.level,
                headline: info.headline,
                explanation: info.explanation,
                recoverySteps: "",
                reinstallCommand: reinstallCommand
            )
        }

        if let record = ExplanationDatabase.matchBundledDatabase(folderName: key) {
            return SafetyInfo(
                level: record.safetyLevel,
                headline: record.displayName,
                explanation: record.explanation,
                recoverySteps: "",
                reinstallCommand: reinstallCommand
            )
        }
        let unknown = ExplanationDatabase.safetyInfoForUnknownBundledLookup(friendlyFallback: fallback)
        return SafetyInfo(
            level: unknown.level,
            headline: unknown.headline,
            explanation: unknown.explanation,
            recoverySteps: "",
            reinstallCommand: reinstallCommand
        )
    }

    /// Safety for project artifacts shown after staleness filtering — always Safe to Clean unless user-overridden.
    nonisolated static func forStaleProjectArtifact(
        kind: DeletableArtifactKind,
        path: URL,
        reinstallCommand: String? = nil
    ) -> SafetyInfo {
        let base = fromExplanationDatabase(
            key: kind.explanationKey,
            friendlyFallback: kind.rowTag,
            reinstallCommand: reinstallCommand,
            path: path
        )
        if UserOverridesStore.read(path: path) != nil { return base }
        return SafetyInfo(
            level: .safe,
            headline: base.headline,
            explanation: base.explanation,
            recoverySteps: base.recoverySteps,
            reinstallCommand: base.reinstallCommand
        )
    }
}
