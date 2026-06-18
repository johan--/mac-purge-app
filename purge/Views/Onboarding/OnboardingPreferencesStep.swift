import SwiftUI

struct OnboardingPreferencesStep: View {
  @AppStorage("onboarding.autoCleanSafe") private var autoCleanSafe = true

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingStepTitle(text: "Set it and forget it.")

        Text("Purge clears safe junk in the background.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingToggleRow(
          title: "Auto-clean safe items",
          isOn: $autoCleanSafe
        )
        .onboardingBlurIn(index: 0)

        ViewThatFits(in: .horizontal) {
          HStack(spacing: AppStyle.Spacing.small) {
            safetyChips
          }
          VStack(spacing: AppStyle.Spacing.xSmall) {
            safetyChips
          }
        }
        .onboardingBlurIn(index: 1)
      }
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity)
  }

  @ViewBuilder
  private var safetyChips: some View {
    OnboardingSafetyChip(
      symbol: "checkmark.circle.fill",
      iconColor: AppColors.tagSafeText,
      label: "Cleans safe caches and temp files"
    )
    OnboardingSafetyChip(
      symbol: "lock.shield.fill",
      iconColor: AppColors.textSecondary,
      label: "Leaves personal and uncertain files alone"
    )
  }

  static func applyToScheduledPreferences() {
    let prefs = ScheduledCleaningPreferenceStore.shared
    let autoClean = UserDefaults.standard.object(forKey: "onboarding.autoCleanSafe") as? Bool ?? true

    Task {
      await prefs.setEnabled(autoClean)
    }
  }
}
