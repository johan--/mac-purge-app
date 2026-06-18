import AppKit
import SwiftUI

struct OnboardingWelcomeStep: View {
  var body: some View {
    VStack(spacing: AppStyle.Spacing.large) {
      VStack(spacing: AppStyle.Spacing.medium) {
        Image(nsImage: NSApplication.shared.applicationIconImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 96, height: 96)
          .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          .accessibilityHidden(true)

        Text("Meet Purge.")
          .font(.system(size: 34, weight: .bold, design: .rounded))
          .multilineTextAlignment(.center)

        Text(
          "Purge quietly keeps your Mac clean in the background. You get a big win today, and it keeps working long after."
        )
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
      }

      HStack(spacing: AppStyle.Spacing.large) {
        OnboardingFeatureChip(symbol: "speaker.slash.fill", label: "Runs silently")
          .onboardingBlurIn(index: 0)
        OnboardingFeatureChip(symbol: "magnifyingglass", label: "Digs deep")
          .onboardingBlurIn(index: 1)
        OnboardingFeatureChip(symbol: "shield.checkered", label: "Always safe")
          .onboardingBlurIn(index: 2)
      }
      .padding(.top, AppStyle.Spacing.small)
    }
    .frame(maxWidth: OnboardingLayout.contentMaxWidth, maxHeight: .infinity)
  }
}
