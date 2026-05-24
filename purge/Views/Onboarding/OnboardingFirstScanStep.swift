import SwiftUI

struct OnboardingFirstScanStep: View {
  @EnvironmentObject private var store: PurgeStore
  @ObservedObject var revealController: OnboardingScanRevealController

  let onScanComplete: () -> Void

  @State private var scanStarted = false

  private static let rowInsertionTransition: AnyTransition = .asymmetric(
    insertion: .opacity.combined(with: .offset(y: 8)),
    removal: .opacity
  )

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
      OnboardingStepTitle(text: "Running your first scan.")

      OnboardingProgressBar(progress: combinedProgress)
        .padding(.bottom, AppStyle.Spacing.xSmall)
        .frame(maxWidth: .infinity)

      OnboardingFadingScrollView(maxHeight: 280) {
        LazyVStack(spacing: 8) {
          ForEach(revealController.revealedItems) { item in
            ScanListRow(
              icon: .symbol("folder.fill"),
              title: item.title,
              subtitle: nil,
              formattedSize: item.formattedSize,
              primaryBadgeText: nil,
              primaryBadgeTone: .neutral
            )
            .transition(Self.rowInsertionTransition)
          }
        }
        .padding(.bottom, AppStyle.Spacing.xSmall)
        .animation(.easeOut(duration: 0.45), value: revealController.revealedItems.count)
      }
      .accessibilityLabel("Items found, \(revealController.revealedItems.count)")

      Spacer(minLength: 0)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity, alignment: .top)
    .onAppear {
      guard !scanStarted else { return }
      scanStarted = true
      Task { await store.scanAll() }
      revealController.startReveal(
        itemProvider: { Self.findings(from: store) },
        scanFinished: { !store.isScanningAll },
        onReadyForResults: onScanComplete
      )
    }
    .onDisappear {
      revealController.cancel()
    }
  }

  private var combinedProgress: Double {
    let scanProgress: Double = store.isScanningAll ? 0.65 : 1
    return min(1, max(revealController.simulatedProgress, scanProgress * 0.35 + revealController.simulatedProgress * 0.65))
  }

  static func findings(from store: PurgeStore) -> [OnboardingScanFinding] {
    var results: [OnboardingScanFinding] = []

    for item in store.cacheItems.sorted(by: { $0.sizeBytes > $1.sizeBytes }).prefix(5) {
      results.append(OnboardingScanFinding(title: item.appName, formattedSize: formatBytes(item.sizeBytes)))
    }
    for tool in store.devTools.filter(\.isDetected).sorted(by: { $0.sizeBytes > $1.sizeBytes }).prefix(3) {
      results.append(OnboardingScanFinding(title: tool.toolName, formattedSize: formatBytes(tool.sizeBytes)))
    }
    for artifact in store.projectGroups.flatMap(\.artifacts).sorted(by: { $0.sizeBytes > $1.sizeBytes }).prefix(2) {
      results.append(OnboardingScanFinding(title: artifact.kind.rowTag, formattedSize: formatBytes(artifact.sizeBytes)))
    }
    return results
  }
}
