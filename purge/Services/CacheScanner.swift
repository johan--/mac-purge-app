import AppKit
import Foundation

@MainActor
final class CacheScanner {
    private let excludedFromGeneralScan: Set<String> = [
        "com.docker.docker",
        "com.docker.helper",
        "com.docker.backend"
    ]

    func scanCaches() async -> [CacheItem] {
        let cachesURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches", isDirectory: true)

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: cachesURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return []
        }

        var items: [CacheItem] = []
        for directory in contents {
            do {
                let values = try directory.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                guard values.isDirectory == true else { continue }

                let bundleID = directory.lastPathComponent
                guard !excludedFromGeneralScan.contains(bundleID) else { continue }

                let size = FolderSizing.directoryByteSize(at: directory)
                let modified = values.contentModificationDate ?? .distantPast
                let fallbackAppName = appNameFromBundleID(bundleID) ?? bundleID
                let safetyInfo = ExplanationResolver.initialSafetyForCacheFolder(
                    folderName: bundleID,
                    friendlyHeadline: fallbackAppName,
                    path: directory
                )

                items.append(
                    CacheItem(
                        appName: safetyInfo.headline,
                        bundleID: bundleID,
                        path: directory,
                        sizeBytes: size,
                        lastModified: modified,
                        isSelected: false,
                        safetyInfo: safetyInfo,
                        reinstallSafety: .notApplicable,
                        gitStatus: .unknown
                    )
                )
            } catch {
                continue
            }
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    func scanSystemJunk() async -> [CacheItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [CacheItem] = []

        let junkLocations: [(String, String, URL)] = [
            (
                "iPhone Backups",
                "iphone.gen3",
                home.appendingPathComponent(
                    "Library/Application Support/MobileSync/Backup",
                    isDirectory: true
                )
            ),
            (
                "Application Logs",
                "doc.text.fill",
                home.appendingPathComponent("Library/Logs", isDirectory: true)
            ),
            (
                "Crash Reports",
                "exclamationmark.triangle.fill",
                home.appendingPathComponent(
                    "Library/Logs/DiagnosticReports",
                    isDirectory: true
                )
            ),
            (
                "macOS Installers",
                "arrow.down.circle.fill",
                URL(fileURLWithPath: "/Applications/Install macOS", isDirectory: true)
            ),
            (
                "Font Cache",
                "textformat",
                home.appendingPathComponent("Library/Caches/com.apple.ATS", isDirectory: true)
            )
        ]

        for (displayName, _, url) in junkLocations {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let size = FolderSizing.directoryByteSize(at: url)
            guard size > 0 else { continue }

            let modified = FolderSizing.contentModificationDate(at: url)
            let safetyInfo = ExplanationResolver.initialSafetyForCacheFolder(
                folderName: url.lastPathComponent,
                friendlyHeadline: displayName,
                path: url
            )

            items.append(CacheItem(
                appName: displayName,
                bundleID: url.lastPathComponent,
                path: url,
                sizeBytes: size,
                lastModified: modified,
                isSelected: false,
                safetyInfo: safetyInfo,
                reinstallSafety: .notApplicable,
                gitStatus: .unknown
            ))
        }

        return items
    }

    func calculateFolderSize(at url: URL) -> Int64 {
        FolderSizing.directoryByteSize(at: url)
    }

    private func appNameFromBundleID(_ bundleID: String) -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return FileManager.default.displayName(atPath: appURL.path)
    }
}
