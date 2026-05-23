import SwiftUI

struct OnboardingPreferencesStep: View {
  @AppStorage("onboarding.autoCleanSafe") private var autoCleanSafe = true
  @AppStorage("onboarding.smartNotifications") private var smartNotifications = true
  @AppStorage("onboarding.monthlyDigest") private var monthlyDigest = true

  var body: some View {
    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
      Text("Set it and forget it.")
        .font(.system(size: 28, weight: .bold, design: .rounded))

      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingToggleRow(
          title: "Auto-clean safe items",
          subtitle: "Periodically remove caches marked safe to clean.",
          isOn: $autoCleanSafe
        )
        OnboardingToggleRow(
          title: "Smart notifications",
          subtitle: "Get a heads-up when Purge finds something worth your attention.",
          isOn: $smartNotifications
        )
        OnboardingToggleRow(
          title: "Monthly digest",
          subtitle: "A once-a-month summary of what Purge cleaned for you.",
          isOn: $monthlyDigest
        )
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity, alignment: .top)
  }

  static func applyToScheduledPreferences() {
    let prefs = ScheduledCleaningPreferenceStore.shared
    let autoClean = UserDefaults.standard.object(forKey: "onboarding.autoCleanSafe") as? Bool ?? true
    let smartNotif = UserDefaults.standard.object(forKey: "onboarding.smartNotifications") as? Bool ?? true
    let digest = UserDefaults.standard.object(forKey: "onboarding.monthlyDigest") as? Bool ?? true

    Task {
      await prefs.setEnabled(autoClean)
      if digest {
        prefs.updateFrequencyWithoutSideEffects(.monthly)
      }
      if smartNotif && autoClean {
        _ = await ScheduledCleanupNotifier.requestAuthorizationIfNeeded()
      }
      if autoClean {
        await ScheduledCleaningRegistrar.shared.applyScheduleFromPrefs()
      }
    }
  }
}
