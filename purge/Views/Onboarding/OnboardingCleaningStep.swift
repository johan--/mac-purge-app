import SwiftUI

struct OnboardingCleaningStep: View {
  @EnvironmentObject private var store: PurgeStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Items revealed during the first-scan step; falls back to live safe findings when empty.
  let scanRevealedItems: [OnboardingScanFinding]
  let onFinished: (Int64) -> Void

  @State private var visibleItems: [OnboardingScanFinding] = []
  @State private var cleaningStarted = false
  @State private var initialItemCount = 0

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
      OnboardingStepTitle(text: "Cleaning safe items…")

      OnboardingProgressBar(progress: cleaningProgress)
        .padding(.bottom, AppStyle.Spacing.xSmall)
        .frame(maxWidth: .infinity)

      ScrollView(showsIndicators: false) {
        VStack(spacing: 8) {
          ForEach(visibleItems) { item in
            ScanListRow(
              icon: .symbol("folder.fill"),
              title: item.title,
              subtitle: nil,
              formattedSize: item.formattedSize,
              primaryBadgeText: "Cleared",
              primaryBadgeTone: .safe
            )
            .transition(OnboardingTransitions.listRowRemoval(reduceMotion: reduceMotion))
          }
        }
        .padding(.bottom, AppStyle.Spacing.xSmall)
        .animation(.easeInOut(duration: 0.45), value: visibleItems.count)
      }
      .frame(maxHeight: 300)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity, alignment: .top)
    .onAppear {
      guard !cleaningStarted else { return }
      cleaningStarted = true
      let items = scanRevealedItems.isEmpty ? Self.safeFindings(from: store) : scanRevealedItems
      initialItemCount = items.count
      visibleItems = items
      Task { await runCleaning() }
    }
  }

  private var cleaningProgress: Double {
    guard initialItemCount > 0 else { return store.isDeleting ? 0.5 : 1 }
    let cleared = initialItemCount - visibleItems.count
    return Double(cleared) / Double(initialItemCount)
  }

  private func runCleaning() async {
    let allItems = Self.safeFindings(from: store)

    async let cleanTask = store.performManualSafeCleanNow()

    for _ in allItems.indices {
      try? await Task.sleep(nanoseconds: 380_000_000)
      guard !visibleItems.isEmpty else { continue }
      withAnimation(.easeInOut(duration: 0.4)) {
        visibleItems.removeFirst()
      }
    }

    let summary = await cleanTask
    withAnimation(.easeInOut(duration: 0.3)) {
      visibleItems = []
    }
    try? await Task.sleep(nanoseconds: 300_000_000)
    onFinished(summary.freedBytes)
  }

  static func safeFindings(from store: PurgeStore) -> [OnboardingScanFinding] {
    var results: [OnboardingScanFinding] = []
    for item in store.cacheItems.filter({ $0.safetyInfo.level == .safe }).sorted(by: { $0.sizeBytes > $1.sizeBytes }) {
      results.append(OnboardingScanFinding(title: item.appName, formattedSize: formatBytes(item.sizeBytes)))
    }
    for tool in store.devTools.filter({ $0.isDetected && $0.safetyInfo.level == .safe }).sorted(by: { $0.sizeBytes > $1.sizeBytes }) {
      results.append(OnboardingScanFinding(title: tool.toolName, formattedSize: formatBytes(tool.sizeBytes)))
    }
    for artifact in store.projectGroups.flatMap(\.artifacts).filter({ $0.safetyInfo.level == .safe }).sorted(by: { $0.sizeBytes > $1.sizeBytes }) {
      results.append(OnboardingScanFinding(title: artifact.kind.rowTag, formattedSize: formatBytes(artifact.sizeBytes)))
    }
    return Array(results.prefix(12))
  }
}
