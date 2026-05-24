import SwiftUI

struct OnboardingPreferencesStep: View {
  @AppStorage("onboarding.autoCleanSafe") private var autoCleanSafe = true

  var body: some View {
    VStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingStepTitle(text: "Set it and forget it.")

        Text(
          "Purge can run quietly in the background and automatically remove safe junk while you work. You'll never have to think about it."
        )
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
      }

      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingToggleRow(
          title: "Auto-clean safe items",
          subtitle: "Silently removes safe caches and temp files. Personal files are never touched.",
          isOn: $autoCleanSafe
        )
        .onboardingBlurIn(index: 0)

        Text(
          "Safe files get cleaned automatically in the background.\nUncertain files are always left alone."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .onboardingBlurIn(index: 1)
      }
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity)
  }

  static func applyToScheduledPreferences() {
    let prefs = ScheduledCleaningPreferenceStore.shared
    let autoClean = UserDefaults.standard.object(forKey: "onboarding.autoCleanSafe") as? Bool ?? true

    Task {
      await prefs.setEnabled(autoClean)
    }
  }
}
