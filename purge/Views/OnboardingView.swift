import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 14) {
                navigationButtons
                progressDots
            }
        }
        .padding(32)
        .frame(width: 560, height: 420)
        .background(onboardingBackground)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch currentPage {
        case 0:
            firstScreen
        default:
            safetyScreen
        }
    }

    private var firstScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            centeredSymbol("sparkles", size: 64)

            VStack(alignment: .leading, spacing: 12) {
                Text("Your Mac collects junk.\nPurge cleans it safely.")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    """
                    Over time your Mac fills up with leftover files from apps, \
                    coding projects, and system processes. Purge finds them, \
                    explains what they are in plain English, and only removes \
                    what is safe.
                    """
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var safetyScreen: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How Purge decides what is safe")
                .font(.system(.title2, design: .rounded).weight(.bold))

            Text("Every item is tagged before you delete anything.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                safetyTagRow(
                    level: .safe,
                    description: "Always regenerated automatically. Nothing is lost."
                )
                safetyTagRow(
                    level: .medium,
                    description: "Safe to delete but may cause minor inconvenience."
                )
                safetyTagRow(
                    level: .danger,
                    description: "Could break something. Leave it alone."
                )
                safetyTagRow(
                    level: .unknown,
                    description: "Purge could not identify this. We recommend skipping it."
                )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Spacer()

            if currentPage == 1 {
                Button {
                    complete()
                } label: {
                    Text("Done →")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Skip") {
                    complete()
                }
                .buttonStyle(.plain)

                Button {
                    advance()
                } label: {
                    Text("Next →")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.primary.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var onboardingBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.11),
                Color(red: 0.05, green: 0.06, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func centeredSymbol(_ name: String, size: CGFloat) -> some View {
        HStack {
            Spacer()
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func safetyTagRow(level: SafetyLevel, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(level.color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(level.displayName)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func advance() {
        if currentPage == 0 {
            hasCompletedOnboarding = true
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            currentPage = min(currentPage + 1, 1)
        }
    }

    private func complete() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false), onComplete: {})
}
