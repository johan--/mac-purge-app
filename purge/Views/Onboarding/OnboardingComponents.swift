import AppKit
import SwiftUI

struct OnboardingScanFinding: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let formattedSize: String
}

struct OnboardingLayout {
  static let contentMaxWidth: CGFloat = 520
  static let horizontalPadding: CGFloat = 48
  static let verticalPadding: CGFloat = 40
  static let buttonWidth: CGFloat = 260
}

struct OnboardingPrimaryButton: View {
  let title: String
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.body.weight(.semibold))
        .frame(width: OnboardingLayout.buttonWidth)
        .padding(.vertical, 8)
    }
    .buttonStyle(.borderedProminent)
    .tint(AppStyle.accent)
    .disabled(!isEnabled)
    .keyboardShortcut(.return, modifiers: [])
  }
}

struct OnboardingSecondaryButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(.medium))
        .frame(width: OnboardingLayout.buttonWidth)
        .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
    .foregroundStyle(.secondary)
  }
}

struct OnboardingFeatureChip: View {
  let symbol: String
  let label: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: symbol)
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(AppStyle.accent)
        .frame(width: 52, height: 52)
        .background(AppStyle.accent.opacity(0.12), in: Circle())

      Text(label)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
  }
}

struct OnboardingPermissionRow: View {
  let symbol: String
  let title: String
  let description: String
  let badgeText: String
  let badgeTone: AppBadge.Tone
  var isGranted: Bool = false

  var body: some View {
    HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
      Image(systemName: symbol)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(AppStyle.accent)
        .frame(width: 40, height: 40)
        .background(AppStyle.elevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(title)
            .font(.subheadline.weight(.semibold))
          AppBadge(text: badgeText, tone: badgeTone)
          if isGranted {
            Image(systemName: "checkmark.circle.fill")
              .font(.caption)
              .foregroundStyle(AppStyle.safe)
              .accessibilityLabel("Granted")
          }
        }
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .padding(AppStyle.Spacing.small)
    .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
        .stroke(AppStyle.hairline)
    }
    .accessibilityElement(children: .combine)
  }
}

struct OnboardingToggleRow: View {
  let title: String
  let subtitle: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.medium))
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 8)
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
        .tint(AppStyle.accent)
    }
    .padding(AppStyle.Spacing.small)
    .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
        .stroke(AppStyle.hairline)
    }
  }
}

struct OnboardingProgressBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(Color.primary.opacity(0.1))
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(AppStyle.accent)
          .frame(width: max(0, geo.size.width * min(1, max(0, progress))))
          .animation(.easeInOut(duration: 0.3), value: progress)
      }
    }
    .frame(height: 6)
    .accessibilityLabel("Scan progress")
    .accessibilityValue("\(Int(progress * 100)) percent")
  }
}

struct OnboardingResultsSummaryRow: View {
  let label: String
  let formattedSize: String
  let badgeText: String
  let badgeTone: AppBadge.Tone

  var body: some View {
    HStack {
      AppBadge(text: badgeText, tone: badgeTone)
      Text(label)
        .font(.subheadline.weight(.medium))
      Spacer()
      Text(formattedSize)
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
    }
    .padding(AppStyle.Spacing.small)
    .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
        .stroke(AppStyle.hairline)
    }
  }
}

private struct OnboardingStepTransition: ViewModifier {
  let blur: CGFloat
  let opacity: Double
  let offset: CGFloat

  func body(content: Content) -> some View {
    content
      .blur(radius: blur)
      .opacity(opacity)
      .offset(y: offset)
  }
}

enum OnboardingTransitions {
  static func stepTransition(reduceMotion: Bool) -> AnyTransition {
    if reduceMotion {
      return .opacity
    }
    return .modifier(
      active: OnboardingStepTransition(blur: 8, opacity: 0, offset: 12),
      identity: OnboardingStepTransition(blur: 0, opacity: 1, offset: 0)
    )
  }
}

func openFullDiskAccessSettings() {
  guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
    return
  }
  NSWorkspace.shared.open(url)
}
