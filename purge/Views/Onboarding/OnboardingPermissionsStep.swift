import SwiftUI
import UserNotifications

struct OnboardingPermissionsStep: View {
  @EnvironmentObject private var store: PurgeStore

  @State private var notificationsGranted = false
  @State private var loginItemRegistered = false

  var body: some View {
    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
      Text("A couple of quick permissions.")
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: AppStyle.Spacing.small) {
        OnboardingPermissionRow(
          symbol: "externaldrive.fill.badge.checkmark",
          title: "Full disk access",
          description: "Lets Purge scan caches and junk across your home folder.",
          badgeText: "Required",
          badgeTone: .accent,
          isGranted: store.hasFullDiskAccess
        )
        OnboardingPermissionRow(
          symbol: "bell.fill",
          title: "Notifications",
          description: "Optional alerts when scheduled cleaning frees space or needs attention.",
          badgeText: "Optional",
          badgeTone: .neutral,
          isGranted: notificationsGranted
        )
        OnboardingPermissionRow(
          symbol: "power",
          title: "Login item",
          description: "Optional — keeps Purge ready in the background after you sign in.",
          badgeText: "Optional",
          badgeTone: .neutral,
          isGranted: loginItemRegistered
        )
      }

      if !store.hasFullDiskAccess {
        Text("Full Disk Access is required before your first scan.")
          .font(.caption)
          .foregroundStyle(AppStyle.warning)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity, alignment: .top)
    .onAppear { refreshOptionalStatus() }
  }

  func refreshOptionalStatus() {
    loginItemRegistered = LoginItemRegistrar.isRegistered
    Task {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      await MainActor.run {
        notificationsGranted = settings.authorizationStatus == .authorized
          || settings.authorizationStatus == .provisional
      }
    }
  }

  func grantAllPermissions() {
    if !store.hasFullDiskAccess {
      openFullDiskAccessSettings()
    }
    store.refreshPermission()
    Task {
      let ok = await ScheduledCleanupNotifier.requestAuthorizationIfNeeded()
      await MainActor.run {
        notificationsGranted = ok
      }
    }
    loginItemRegistered = LoginItemRegistrar.register()
  }
}
