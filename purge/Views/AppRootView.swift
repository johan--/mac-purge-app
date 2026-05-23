import SwiftUI

struct AppRootView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @EnvironmentObject private var store: PurgeStore
  @EnvironmentObject private var diskStore: DiskSummaryStore

  var body: some View {
    Group {
      if hasCompletedOnboarding {
        ContentView()
      } else {
        OnboardingFlowView(hasCompletedOnboarding: $hasCompletedOnboarding)
      }
    }
    .toolbar(hasCompletedOnboarding ? .visible : .hidden, for: .windowToolbar)
  }
}
