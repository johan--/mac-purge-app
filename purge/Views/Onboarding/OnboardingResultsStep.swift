import SwiftUI

struct OnboardingResultsStep: View {
  @EnvironmentObject private var store: PurgeStore

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.large) {
      VStack(alignment: .center, spacing: AppStyle.Spacing.xSmall) {
        Text(formatBytes(store.safeRecoverableBytes))
          .font(.system(size: 48, weight: .bold, design: .rounded))
          .monospacedDigit()
          .multilineTextAlignment(.center)
          .accessibilityLabel("\(formatBytes(store.safeRecoverableBytes)) safe to clean")

        Text("safe to clean on your Mac")
          .font(.title3.weight(.medium))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingResultsSummaryRow(
          label: "Safe to clean",
          formattedSize: formatBytes(store.safeRecoverableBytes),
          badgeText: "Safe",
          badgeTone: .safe
        )
        OnboardingResultsSummaryRow(
          label: "Check first",
          formattedSize: formatBytes(store.checkFirstRecoverableBytes),
          badgeText: "Review",
          badgeTone: .warning
        )
      }
      .frame(maxWidth: OnboardingLayout.contentMaxWidth)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity, alignment: .center)
  }
}
