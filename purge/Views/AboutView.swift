import AppKit
import SwiftUI

struct AboutView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    var showsPageHeader = true
    /// When true, the parent owns scrolling and the macOS 26 progressive scroll-edge blur.
    var usesExternalScrollContainer = false

    var body: some View {
        Group {
            if usesExternalScrollContainer {
                aboutScrollContent
            } else {
                VStack(spacing: 0) {
                    if showsPageHeader {
                        AppSectionPageHeader(title: "About")
                    }

                    ScrollView {
                        aboutScrollContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(AppStyle.canvas)
    }

    private var aboutScrollContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            appIdentitySection
            whatsNewSection
            comingNextSection
            actionCardSection
            footerSection
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppDetailPageLayout.horizontalInset)
        .padding(
            .top,
            usesExternalScrollContainer
                ? AppDetailPageLayout.scrollEdgeClearanceBelowHeader
                : (showsPageHeader ? AppStyle.Spacing.medium : AppDetailPageLayout.topContentInset)
        )
        .padding(.bottom, AppDetailPageLayout.verticalPadding)
    }

    private var appIdentitySection: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contentShape(Rectangle())

            Text("Purge")
                .font(.system(size: 30, weight: .semibold, design: .rounded))

            Text("Version \(appVersion)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var whatsNewSection: some View {
        aboutCard {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("What's new in 1.1", accent: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                featureRows([
                    .init(icon: "sparkles", title: "All-new onboarding", description: "A clean full-screen setup flow that walks you through your first scan."),
                    .init(icon: "arrow.clockwise", title: "Smarter scanning", description: "Items stream in as they're found. No more frozen screens."),
                    .init(icon: "square.on.square", title: "Duplicate entries fixed", description: "Apps with multiple cache locations now show as a single combined row."),
                    .init(icon: "xmark.circle", title: "AI identification removed", description: "Replaced with a fast, reliable hand-curated local database.")
                ])
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
            }
        }
    }

    private var comingNextSection: some View {
        VStack(spacing: 14) {
            aboutCard {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Coming in 1.2", accent: true)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    featureRows([
                        .init(icon: "chart.bar.fill", title: "Stats screen", description: "See your lifetime cleaned and a history of past scans."),
                        .init(icon: "bell.fill", title: "Smart notifications", description: "Alerts when Purge finds something worth your attention.")
                    ])
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                }
            }

            aboutCard {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("On the roadmap", accent: false)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    featureRows([
                        .init(icon: "square.and.arrow.up", title: "Shareable stats card", description: "Like Spotify Wrapped but for your disk."),
                        .init(icon: "calendar", title: "Monthly digest", description: "A summary of what Purge cleaned automatically each month."),
                        .init(icon: "hammer.fill", title: "More dev tool coverage", description: "Broader support for more languages and build tools.")
                    ])
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                }
            }
        }
    }

    private var actionCardSection: some View {
        aboutCard {
            VStack(spacing: 0) {
                AboutActionRow(icon: "ant.fill", label: "Report a bug") {
                    NSWorkspace.shared.open(reportBugURL)
                }

                InsetCardDivider()

                AboutActionRow(icon: "lightbulb.fill", label: "Request a feature") {
                    NSWorkspace.shared.open(featureRequestURL)
                }

                InsetCardDivider()

                AboutActionRow(icon: "arrow.counterclockwise", label: "Replay onboarding") {
                    hasCompletedOnboarding = false
                }
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("Made with")
                    .foregroundStyle(.secondary)
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("by")
                    .foregroundStyle(.secondary)
                Text("Jithin")
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .font(.subheadline)

            Text(footerVersionText)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var footerVersionText: String {
        guard let buildDate = bundleReleaseDate else {
            return "Version \(appVersion)"
        }
        return "Version \(appVersion) · \(Self.buildDateFormatter.string(from: buildDate))"
    }

    private func featureRows(_ items: [FeatureItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, alignment: .center)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(item.description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 12)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(AppStyle.hairline)
                        .frame(height: 0.5)
                }
            }
        }
    }

    private func sectionLabel(_ text: String, accent: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(accent ? AppStyle.accent : .secondary)
    }

    private func aboutCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppStyle.elevated,
                in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                    .strokeBorder(AppStyle.hairline, lineWidth: 0.5)
            }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String

        switch (version?.isEmpty == false ? version : nil, build?.isEmpty == false ? build : nil) {
        case let (.some(version), .some(build)) where build != version:
            return "\(version) (\(build))"
        case let (.some(version), _):
            return version
        case let (_, .some(build)):
            return build
        default:
            return "1.0.0"
        }
    }

    private var bundleReleaseDate: Date? {
        guard let url = Bundle.main.executableURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date
        else { return nil }
        return date
    }

    private static let buildDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    private var reportBugURL: URL {
        URL(string: "mailto:design@jithinsabu.com?subject=Purge%20Bug%20Report")!
    }

    private var featureRequestURL: URL {
        URL(string: "mailto:design@jithinsabu.com?subject=Purge%20Feature%20Request")!
    }
}

private struct FeatureItem {
    let icon: String
    let title: String
    let description: String
}

private struct AboutActionRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 12)
            }
            .padding(.horizontal, 16)
            .frame(height: AppStyle.Row.compactHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
