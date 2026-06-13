import Foundation

/// Bounds for the Large & Old Files feature. This is deliberately separate from
/// DeletionSafetyPolicy because these are personal files, not cache files.
enum LargeFileScanPolicy {
    nonisolated static func scanRoots(home: URL) -> [URL] {
        [
            home.appendingPathComponent("Documents", isDirectory: true),
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Downloads", isDirectory: true),
            home.appendingPathComponent("Movies", isDirectory: true),
            home.appendingPathComponent("Music", isDirectory: true),
            home.appendingPathComponent("Pictures", isDirectory: true)
        ]
    }

    /// Managed libraries and bundles we never descend into or offer for deletion.
    nonisolated static let excludedFolderNames: Set<String> = [
        "Photos Library.photoslibrary",
        "Photo Booth Library",
        "iMovie Library.imovielibrary",
        "iMovie Theater.theater",
        "TV Library.tvlibrary",
        "Music Library.musiclibrary",
        "GarageBand"
    ]

    nonisolated static func isExcludedDirectory(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        if name.hasPrefix(".") { return true }
        if excludedFolderNames.contains(name) { return true }
        let ext = url.pathExtension.lowercased()
        return ["app", "photoslibrary", "imovielibrary", "tvlibrary", "musiclibrary", "theater", "bundle"].contains(ext)
    }

    nonisolated static func isInsideExcludedDirectory(_ url: URL) -> Bool {
        let components = url.standardizedFileURL.pathComponents.dropLast()
        for component in components {
            if component.hasPrefix(".") { return true }
            if excludedFolderNames.contains(component) { return true }
            let ext = (component as NSString).pathExtension.lowercased()
            if ["app", "photoslibrary", "imovielibrary", "tvlibrary", "musiclibrary", "theater", "bundle"].contains(ext) {
                return true
            }
        }
        return false
    }

    /// A file may be deleted only if it is a regular file under one of the scan
    /// roots and nowhere near Library or system locations.
    nonisolated static func isEligibleForDeletion(_ url: URL) -> Bool {
        let fm = FileManager.default
        let std = url.standardizedFileURL
        let path = std.path

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else { return false }
        if path.contains("/Library/") { return false }
        if isInsideExcludedDirectory(std) { return false }

        let home = fm.homeDirectoryForCurrentUser
        return scanRoots(home: home).contains { root in
            path.hasPrefix(root.standardizedFileURL.path + "/")
        }
    }
}
