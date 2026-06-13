import Foundation

final class LargeFileScanner {
    func scanStream(minBytes: Int64, staleDays: Int) -> AsyncStream<LargeFile> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                await Self.run(minBytes: minBytes, staleDays: staleDays, continuation: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func run(
        minBytes: Int64,
        staleDays: Int,
        continuation: AsyncStream<LargeFile>.Continuation
    ) async {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let now = Date()
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey, .isDirectoryKey, .totalFileAllocatedSizeKey, .fileSizeKey,
            .contentAccessDateKey, .contentModificationDateKey, .isPackageKey
        ]

        for root in LargeFileScanPolicy.scanRoots(home: home) {
            if Task.isCancelled { break }
            guard fm.fileExists(atPath: root.path) else { continue }

            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let next = enumerator.nextObject() {
                if Task.isCancelled { break }
                guard let fileURL = next as? URL else { continue }

                let values = try? fileURL.resourceValues(forKeys: resourceKeys)

                if values?.isDirectory == true || values?.isPackage == true {
                    if LargeFileScanPolicy.isExcludedDirectory(fileURL) {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                guard values?.isRegularFile == true else { continue }

                let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
                guard size >= minBytes else { continue }

                let accessed = values?.contentAccessDate ?? .distantPast
                let modified = values?.contentModificationDate ?? .distantPast
                let lastUsed = max(accessed, modified)
                let days = Calendar.current.dateComponents([.day], from: lastUsed, to: now).day ?? 0
                guard days >= staleDays else { continue }

                continuation.yield(
                    LargeFile(
                        path: fileURL.standardizedFileURL,
                        sizeBytes: size,
                        lastUsed: lastUsed,
                        category: LargeFileCategory.category(forExtension: fileURL.pathExtension)
                    )
                )
            }
        }

        continuation.finish()
    }
}
