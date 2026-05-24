import SwiftUI

struct OnboardingResultsCategory: Identifiable {
  let title: String
  let symbol: String
  let bytes: Int64

  var id: String { title }
}

extension PurgeStore {
  var onboardingResultsCategories: [OnboardingResultsCategory] {
    var browserBytes: Int64 = 0
    var appCacheBytes: Int64 = 0
    var systemJunkBytes: Int64 = 0

    for item in cacheItems {
      let size = item.sizeBytes
      guard size > 0 else { continue }

      if Self.isBrowserCacheItem(item) {
        browserBytes += size
      } else if Self.isSystemJunkCacheItem(item) {
        systemJunkBytes += size
      } else {
        appCacheBytes += size
      }
    }

    let devToolBytes = devTools
      .filter(\.isDetected)
      .reduce(Int64(0)) { $0 + $1.sizeBytes }

    let simulatorBytes = simulatorDevices
      .reduce(Int64(0)) { $0 + ($1.sizeOnDisk ?? 0) }

    let projectArtifactBytes = projectGroups
      .flatMap(\.artifacts)
      .reduce(Int64(0)) { $0 + $1.sizeBytes }

    let devArtifactBytes = devToolBytes + simulatorBytes + projectArtifactBytes

    let candidates = [
      OnboardingResultsCategory(title: "App caches", symbol: "internaldrive", bytes: appCacheBytes),
      OnboardingResultsCategory(title: "Dev tool artifacts", symbol: "hammer", bytes: devArtifactBytes),
      OnboardingResultsCategory(title: "Browser caches", symbol: "globe", bytes: browserBytes),
      OnboardingResultsCategory(title: "System junk", symbol: "doc.text", bytes: systemJunkBytes),
    ]

    return candidates
      .filter { $0.bytes > 0 }
      .sorted { $0.bytes > $1.bytes }
      .prefix(4)
      .map { $0 }
  }

  private static let browserDefinitionKeys: Set<String> = [
    "safari", "chrome", "firefox", "brave", "arc-browser", "zen", "opera",
  ]

  private static let browserBundlePrefixes: [String] = [
    "com.google.Chrome",
    "com.apple.Safari",
    "org.mozilla.firefox",
    "com.brave.Browser",
    "company.thebrowser.",
    "com.microsoft.edgemac",
    "com.operasoftware.Opera",
  ]

  private static let systemJunkAppNames: Set<String> = [
    "iPhone Backups",
    "Application Logs",
    "Crash Reports",
    "macOS Installers",
    "Font Cache",
  ]

  private static func isBrowserCacheItem(_ item: CacheItem) -> Bool {
    if let key = item.definitionKey, browserDefinitionKeys.contains(key) {
      return true
    }

    let folder = item.bundleID.lowercased()
    if browserBundlePrefixes.contains(where: { folder.hasPrefix($0.lowercased()) }) {
      return true
    }

    let name = item.appName.lowercased()
    return name.contains("browser")
  }

  private static func isSystemJunkCacheItem(_ item: CacheItem) -> Bool {
    systemJunkAppNames.contains(item.appName)
  }
}

struct OnboardingResultsStep: View {
  @EnvironmentObject private var store: PurgeStore

  private var categories: [OnboardingResultsCategory] {
    store.onboardingResultsCategories
  }

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.large) {
      VStack(alignment: .center, spacing: 32) {
        VStack(alignment: .center, spacing: 0) {
          Text(formatBytes(store.safeRecoverableBytes))
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .accessibilityLabel("\(formatBytes(store.safeRecoverableBytes)) ready to clean")

          Text("ready to clean on your Mac")
            .font(.title2.weight(.medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        if let comparisonItems = OnboardingSizeComparison.items(for: store.safeRecoverableBytes) {
          OnboardingSizeComparisonLine(items: comparisonItems)
        }
      }
      .padding(.bottom, AppStyle.Spacing.medium)

      VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
        ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
          OnboardingResultsCategoryRow(
            symbol: category.symbol,
            title: category.title,
            formattedSize: formatBytes(category.bytes)
          )
          .onboardingBlurIn(index: index)
        }
      }
      .frame(maxWidth: 300)
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity)
  }
}
