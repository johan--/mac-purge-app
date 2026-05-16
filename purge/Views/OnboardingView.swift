import AppKit
import SwiftUI

private enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case howItWorks
    case features
    case safety
    case permission

    var stepLabel: String {
        "Step \(rawValue + 1) of \(Self.allCases.count)"
    }
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    let onComplete: () -> Void

    @EnvironmentObject private var store: PurgeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        VStack(spacing: 0) {
            headerChrome

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, AppStyle.Spacing.medium)

            footerChrome
        }
        .padding(AppStyle.Spacing.large)
        .frame(width: 640, height: 480)
        .background(AppStyle.canvas)
        .foregroundStyle(.primary)
    }

    // MARK: - Chrome

    private var headerChrome: some View {
        VStack(spacing: AppStyle.Spacing.xSmall) {
            Text(currentStep.stepLabel)
                .font(AppStyle.Typography.metadata)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            progressDots
        }
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step == currentStep ? AppStyle.accent : Color.primary.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }

    private var footerChrome: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            Button("Skip") {
                complete()
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            if currentStep != .welcome {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.bordered)
            }

            primaryFooterButton
        }
        .padding(.top, AppStyle.Spacing.medium)
    }

    @ViewBuilder
    private var primaryFooterButton: some View {
        switch currentStep {
        case .permission:
            Button {
                complete()
            } label: {
                Text("Start scanning")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppStyle.accent)
            .disabled(!store.hasFullDiskAccess)
            .keyboardShortcut(.return, modifiers: [])
        default:
            Button {
                advance()
            } label: {
                Text(currentStep == .safety ? "Continue" : "Next")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppStyle.accent)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case .welcome:
                welcomeScreen
            case .howItWorks:
                howItWorksScreen
            case .features:
                featuresScreen
            case .safety:
                safetyScreen
            case .permission:
                permissionScreen
            }
        }
        .id(currentStep)
        .transition(contentTransition)
    }

    private var contentTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: 12)),
            removal: .opacity.combined(with: .offset(x: -12))
        )
    }

    // MARK: - Screen 1

    private var welcomeScreen: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            centeredSymbol("externaldrive.badge.checkmark", size: 56)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                Text("Free up your Mac. Safely.")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    """
                    Junk from apps and dev tools builds up over time. Purge finds it, \
                    explains it in plain English, and only removes what is safe.
                    """
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Screen 2

    private var howItWorksScreen: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                Text("Scan. Understand. Clean.")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Text("Three steps to reclaim disk space without guesswork.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                howItWorksStepRow(icon: "magnifyingglass", title: "Scan your Mac", detail: "Find caches and dev leftovers in one pass.")
                howItWorksStepRow(icon: "text.book.closed", title: "Read plain-English explanations", detail: "Know what each folder is before you touch it.")
                howItWorksStepRow(icon: "trash", title: "Clean what you trust", detail: "Select items and delete only what you approve.")
            }

            OnboardingScanRowMock()
        }
    }

    private func howItWorksStepRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppStyle.accent)
                .frame(width: 24, height: 24)
                .background(AppStyle.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Screen 3

    private var featuresScreen: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                Text("Built for everyday Macs and dev machines")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Text("Everything you need to keep storage under control.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: AppStyle.Spacing.small), GridItem(.flexible(), spacing: AppStyle.Spacing.small)],
                spacing: AppStyle.Spacing.small
            ) {
                featureCard(icon: "app.badge", title: "App Caches", detail: "Friendly names for ~/Library/Caches.")
                featureCard(icon: "hammer", title: "Dev Tools", detail: "DerivedData, node_modules, Docker, and more.")
                featureCard(icon: "shield.checkered", title: "Safety tags", detail: "Every item is labeled before you delete.")
                featureCard(icon: "clock.arrow.circlepath", title: "Scheduled cleaning", detail: "Optional automation in Settings.")
            }
        }
    }

    private func featureCard(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.accent)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppStyle.Spacing.small)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                .stroke(AppStyle.hairline)
        }
    }

    // MARK: - Screen 4

    private var safetyScreen: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                Text("You're always in control")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Text("Every item is tagged before you delete anything.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                safetyTagRow(level: .safe, description: "Regenerates automatically. Nothing important is lost.")
                safetyTagRow(level: .medium, description: "Usually safe, but you might need to re-download or rebuild.")
                safetyTagRow(level: .danger, description: "Could break something. Leave it alone.")
                safetyTagRow(level: .unknown, description: "Purge could not identify this. We recommend skipping it.")
            }
            .padding(AppStyle.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                    .stroke(AppStyle.hairline)
            }
        }
    }

    // MARK: - Screen 5

    private var permissionScreen: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                Text("One permission, then your first scan")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Text("Purge needs Full Disk Access to scan caches in your home directory.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                permissionChecklistRow(
                    number: 1,
                    text: "Open System Settings → Privacy & Security → Full Disk Access"
                )
                permissionChecklistRow(number: 2, text: "Enable Purge in the list")
                permissionChecklistRow(number: 3, text: "Return here and confirm access below")
            }
            .padding(AppStyle.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                    .stroke(AppStyle.hairline)
            }

            HStack(spacing: AppStyle.Spacing.small) {
                Button("Open Privacy Settings") {
                    openPrivacySettings()
                }
                .buttonStyle(.bordered)

                Button("I've granted access") {
                    store.refreshPermission()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: AppStyle.Spacing.xSmall) {
                if store.hasFullDiskAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppStyle.safe)
                }
                Text(
                    store.hasFullDiskAccess
                        ? "Full Disk Access is enabled. You're ready to scan."
                        : "Files never leave your Mac. Scanning stays local."
                )
                .font(.caption)
                .foregroundStyle(store.hasFullDiskAccess ? AppStyle.safe : .secondary)
            }
        }
    }

    private func permissionChecklistRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(AppStyle.accent, in: Circle())

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helpers

    private func centeredSymbol(_ name: String, size: CGFloat) -> some View {
        HStack {
            Spacer()
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .foregroundStyle(AppStyle.accent)
                .symbolRenderingMode(.hierarchical)
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func safetyTagRow(level: SafetyLevel, description: String) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Circle()
                .fill(safetyColor(for: level))
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

    private func safetyColor(for level: SafetyLevel) -> Color {
        switch level {
        case .safe: return AppStyle.safe
        case .medium: return AppStyle.warning
        case .danger: return AppStyle.danger
        case .unknown: return AppStyle.neutral
        }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            complete()
            return
        }
        setStep(next)
    }

    private func goBack() {
        guard let previous = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        setStep(previous)
    }

    private func setStep(_ step: OnboardingStep) {
        if reduceMotion {
            currentStep = step
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                currentStep = step
            }
        }
    }

    private func complete() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Mock scan row

private struct OnboardingScanRowMock: View {
    var body: some View {
        ScanListRow(
            icon: .symbol("folder.fill"),
            title: "Xcode DerivedData",
            subtitle: "Build artifacts Xcode can recreate",
            formattedSize: "4.2 GB",
            primaryBadgeText: "Safe to Clean",
            primaryBadgeTone: .safe
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example scan row: Xcode DerivedData, 4.2 gigabytes, Safe to Clean")
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false), onComplete: {})
        .environmentObject(PurgeStore())
}
