import SwiftUI

struct AppRootView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var isOnboardingExitingToHome = false
  @State private var isMainAppRevealed = false
  @EnvironmentObject private var store: PurgeStore
  @EnvironmentObject private var diskStore: DiskSummaryStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var showsAppChrome: Bool {
    hasCompletedOnboarding || isOnboardingExitingToHome
  }

  private var showsMainApp: Bool {
    hasCompletedOnboarding || isMainAppRevealed || reduceMotion
  }

  var body: some View {
    ZStack {
      ContentView(isLifecycleActive: hasCompletedOnboarding)
        .opacity(showsMainApp ? 1 : 0)
        .blur(radius: showsMainApp ? 0 : OnboardingTransitions.dismissBlurRadius)
        .allowsHitTesting(showsMainApp)
        .accessibilityHidden(!showsMainApp)
      if !hasCompletedOnboarding {
        OnboardingFlowView(
          hasCompletedOnboarding: $hasCompletedOnboarding,
          isExitingToHome: $isOnboardingExitingToHome
        )
        .allowsHitTesting(!isOnboardingExitingToHome)
      }
    }
    .toolbar(showsAppChrome ? .visible : .hidden, for: .windowToolbar)
    .onAppear {
      isMainAppRevealed = hasCompletedOnboarding
    }
    .onChange(of: isOnboardingExitingToHome) { isExiting in
      if isExiting {
        revealMainAppAfterMount()
      } else if !hasCompletedOnboarding {
        isMainAppRevealed = false
      }
    }
    .onChange(of: hasCompletedOnboarding) { isCompleted in
      if isCompleted {
        isMainAppRevealed = true
      } else if !isOnboardingExitingToHome {
        isMainAppRevealed = false
      }
    }
  }

  private func revealMainAppAfterMount() {
    guard !hasCompletedOnboarding else {
      isMainAppRevealed = true
      return
    }
    isMainAppRevealed = false

    guard !reduceMotion else {
      isMainAppRevealed = true
      return
    }

    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 120_000_000)
      guard isOnboardingExitingToHome, !hasCompletedOnboarding else { return }
      withAnimation(.easeInOut(duration: OnboardingTransitions.dismissDuration)) {
        isMainAppRevealed = true
      }
    }
  }
}
