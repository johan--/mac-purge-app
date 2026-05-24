import SwiftUI

struct AppRootView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var isOnboardingExitingToHome = false
  @EnvironmentObject private var store: PurgeStore
  @EnvironmentObject private var diskStore: DiskSummaryStore

  private var showsMainApp: Bool {
    hasCompletedOnboarding || isOnboardingExitingToHome
  }

  var body: some View {
    ZStack {
      if showsMainApp {
        ContentView()
      }
      if !hasCompletedOnboarding {
        OnboardingFlowView(
          hasCompletedOnboarding: $hasCompletedOnboarding,
          isExitingToHome: $isOnboardingExitingToHome
        )
        .allowsHitTesting(!isOnboardingExitingToHome)
      }
    }
    .toolbar(showsMainApp ? .visible : .hidden, for: .windowToolbar)
  }
}
