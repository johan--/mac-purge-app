import AppKit
import SwiftUI

struct ScanResultRow: View {
    @Binding var isSelected: Bool
    let primaryLabel: String
    let formattedSize: String
    let safetyInfo: SafetyInfo
    /// When nil, a generic folder icon is shown.
    let icon: NSImage?
    let onRequestUnknownDelete: (() -> Void)?
    /// Small footer line (e.g. artifact kind tag).
    let detailCaption: String?
    let reinstallSafety: ReinstallSafetyStatus?
    let showUncommittedRepoChanges: Bool

    /// Per-row recategorization entry points. When nil, the corresponding menu
    /// item or badge is hidden.
    let onRecategorize: (() -> Void)?
    let onMarkSafe: (() -> Void)?
    let onMarkMedium: (() -> Void)?
    let onMarkDanger: (() -> Void)?
    let onResetToAutomatic: (() -> Void)?
    let isUserOverride: Bool
    /// When `false`, the row checkbox is disabled (e.g. high-risk items that should not participate in bulk select).
    var allowsBulkSelection: Bool = true
    /// When true, trailing size and safety badge show skeleton placeholders (post-scan enrichment).
    var isMetadataPending: Bool = false

    private var statusLabel: String {
        safetyInfo.level.displayName
    }

    private var statusTone: AppBadge.Tone {
        switch safetyInfo.level {
        case .safe: return .safe
        case .medium: return .warning
        case .danger: return .danger
        case .unknown: return .neutral
        }
    }

    private var offersUnknownDeletion: Bool {
        safetyInfo.level == .unknown && onRequestUnknownDelete != nil
    }

    private var canSelectForBulk: Bool {
        allowsBulkSelection
    }

    private var resolvedIcon: NSImage {
        if let icon {
            return icon
        }
        return NSWorkspace.shared.icon(forFileType: "public.folder")
    }

    private var hasExtraBadges: Bool {
        isUserOverride || detailCaption != nil || showsReinstallBadge || showUncommittedRepoChanges
    }

    private var showsReinstallBadge: Bool {
        guard let reinstallSafety else { return false }
        return reinstallSafety != .notApplicable
    }

    init(
        isSelected: Binding<Bool>,
        primaryLabel: String,
        formattedSize: String,
        safetyInfo: SafetyInfo,
        icon: NSImage?,
        onRequestUnknownDelete: (() -> Void)?,
        detailCaption: String? = nil,
        reinstallSafety: ReinstallSafetyStatus? = nil,
        showUncommittedRepoChanges: Bool = false,
        onRecategorize: (() -> Void)? = nil,
        onMarkSafe: (() -> Void)? = nil,
        onMarkMedium: (() -> Void)? = nil,
        onMarkDanger: (() -> Void)? = nil,
        onResetToAutomatic: (() -> Void)? = nil,
        isUserOverride: Bool = false,
        allowsBulkSelection: Bool = true,
        isMetadataPending: Bool = false
    ) {
        self._isSelected = isSelected
        self.primaryLabel = primaryLabel
        self.formattedSize = formattedSize
        self.safetyInfo = safetyInfo
        self.icon = icon
        self.onRequestUnknownDelete = onRequestUnknownDelete
        self.detailCaption = detailCaption
        self.reinstallSafety = reinstallSafety
        self.showUncommittedRepoChanges = showUncommittedRepoChanges
        self.onRecategorize = onRecategorize
        self.onMarkSafe = onMarkSafe
        self.onMarkMedium = onMarkMedium
        self.onMarkDanger = onMarkDanger
        self.onResetToAutomatic = onResetToAutomatic
        self.isUserOverride = isUserOverride
        self.allowsBulkSelection = allowsBulkSelection
        self.isMetadataPending = isMetadataPending
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if canSelectForBulk {
                Toggle("", isOn: $isSelected)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
            }

            if canSelectForBulk {
                Button {
                    isSelected.toggle()
                } label: {
                    rowMainContent
                }
                .buttonStyle(.plain)
            } else {
                rowMainContent
            }

            Spacer(minLength: 12)

            trailingColumn
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(canSelectForBulk ? 1 : 0.55)
        .contextMenu {
            rowContextMenu
        }
    }

    private var rowMainContent: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(nsImage: resolvedIcon)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(primaryLabel)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Text(safetyInfo.explanation)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if hasExtraBadges || isMetadataPending {
                    badgesRow
                }
            }
        }
    }

    private var trailingColumn: some View {
        ScanContentCrossfade(isLoading: isMetadataPending) {
            VStack(alignment: .trailing, spacing: 8) {
                SkeletonBar(width: 44, height: 10, cornerRadius: 4)
                    .shimmering()
                SkeletonBar(width: 72, height: 18, cornerRadius: AppStyle.Radius.chip)
                    .shimmering()
            }
        } loaded: {
            VStack(alignment: .trailing, spacing: 8) {
                Text(formattedSize)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                AppBadge(text: statusLabel, tone: statusTone)
            }
        }
    }

    @ViewBuilder
    private var badgesRow: some View {
        HStack(alignment: .center, spacing: 6) {
            extraBadges
        }
    }

    @ViewBuilder
    private var rowContextMenu: some View {
        if let onRecategorize {
            Button("Recategorize") {
                onRecategorize()
            }
        }

        if hasAnyMarkAction {
            Divider()
            if let onMarkSafe, safetyInfo.level != .safe {
                Button("Mark as Safe to Clean") { onMarkSafe() }
            }
            if let onMarkMedium, safetyInfo.level != .medium {
                Button("Mark as Check First") { onMarkMedium() }
            }
            if let onMarkDanger, safetyInfo.level != .danger {
                Button("Mark as Do Not Delete") { onMarkDanger() }
            }
        }

        if isUserOverride, let onResetToAutomatic {
            Divider()
            Button("Reset to automatic") { onResetToAutomatic() }
        }

        if offersUnknownDeletion {
            Divider()
            Button("Delete…", role: .destructive) {
                onRequestUnknownDelete?()
            }
        }
    }

    private var hasAnyMarkAction: Bool {
        onMarkSafe != nil || onMarkMedium != nil || onMarkDanger != nil
    }

    private var extraBadges: some View {
        ScanContentCrossfade(isLoading: isMetadataPending) {
            SkeletonBar(width: 96, height: 16, cornerRadius: AppStyle.Radius.chip)
                .shimmering()
        } loaded: {
            Group {
                if isUserOverride {
                    userOverrideBadge
                }
                if let detailCaption {
                    AppBadge(text: detailCaption, tone: .neutral)
                }
                if let reinstallSafety {
                    switch reinstallSafety {
                    case .reinstallable:
                        AppBadge(text: "Can be rebuilt", tone: .safe)
                    case .missingLockfile:
                        AppBadge(text: "Check support files", tone: .warning)
                    case .notApplicable:
                        EmptyView()
                    }
                }
                if showUncommittedRepoChanges {
                    AppBadge(text: "Local changes nearby", tone: .warning)
                }
            }
        }
    }

    @ViewBuilder
    private var userOverrideBadge: some View {
        if let onResetToAutomatic {
            Button {
                onResetToAutomatic()
            } label: {
                AppBadge(text: "Manual category", tone: .accent)
            }
            .buttonStyle(.plain)
            .help("Reset to automatic")
        } else {
            AppBadge(text: "Manual category", tone: .accent)
        }
    }
}
