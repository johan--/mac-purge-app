import AppKit
@preconcurrency import QuickLookThumbnailing

/// Generates and caches QuickLook thumbnails for the Large Files list.
///
/// Thumbnails are produced off the main thread via `QLThumbnailGenerator` (covering images,
/// video frames, PDFs, and anything else QuickLook supports) and kept in an in-memory
/// `NSCache` keyed by file path + modification date. The cache lets re-scrolling the list — or
/// returning to the screen — reuse work already done this session, while the count limit guards
/// against unbounded growth. Swift task cancellation cancels the underlying QuickLook request,
/// so rows that scroll off-screen before completion don't waste work.
///
/// Scoped to the Large Files feature; nothing else in the app uses this.
final class LargeFileThumbnailService: @unchecked Sendable {
    static let shared = LargeFileThumbnailService()

    private let generator = QLThumbnailGenerator.shared

    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 500
        return cache
    }()

    private init() {}

    /// A stable cache key combining the file path with its last-touched time, so an edited
    /// file regenerates its thumbnail rather than serving a stale one.
    static func cacheKey(path: String, modified: Date) -> String {
        "\(path)|\(modified.timeIntervalSinceReferenceDate)"
    }

    /// Returns an already-generated thumbnail without touching disk, if one is cached.
    func cachedThumbnail(forKey key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    /// Generates a thumbnail off the main thread, returning `nil` when QuickLook can't produce
    /// one (unsupported type, corrupt file, or a generation error). Honors Swift task
    /// cancellation by cancelling the in-flight QuickLook request.
    func thumbnail(for url: URL, key: String, pointSize: CGFloat, scale: CGFloat) async -> NSImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: pointSize, height: pointSize),
            scale: max(scale, 1),
            representationTypes: .thumbnail
        )

        let image: NSImage? = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                generator.generateBestRepresentation(for: request) { representation, _ in
                    continuation.resume(returning: representation?.nsImage)
                }
            }
        } onCancel: {
            generator.cancel(request)
        }

        guard let image else { return nil }
        cache.setObject(image, forKey: key as NSString)
        return image
    }
}
