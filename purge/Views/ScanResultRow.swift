import AppKit
import SwiftUI

struct ScanResultRow: View {
    @Binding var isSelected: Bool
    let primaryLabel: String
    let formattedSize: String
    let dateModifiedLine: String?
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

    @State private var isHoveringRow = false
    @State private var showSafetyPopover = false
    @State private var hoverPopoverWorkItem: DispatchWorkItem?

    private var statusLabel: String {
        safetyInfo.level.displayName
    }

    private var statusColor: Color {
        switch safetyInfo.level {
        case .safe: return AppStyle.safe
        case .medium: return AppStyle.warning
        case .danger: return AppStyle.danger
        case .unknown: return AppStyle.neutral
        }
    }

    private var statusTone: AppBadge.Tone {
        switch safetyInfo.level {
        case .safe: return .safe
        case .medium: return .warning
        case .danger: return .danger
        case .unknown: return .neutral
        }
    }

    private var popoverStatusColor: Color {
        statusColor
    }

    private var popoverExplanation: String {
        safetyInfo.explanation
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

    init(
        isSelected: Binding<Bool>,
        primaryLabel: String,
        formattedSize: String,
        dateModifiedLine: String?,
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
        allowsBulkSelection: Bool = true
    ) {
        self._isSelected = isSelected
        self.primaryLabel = primaryLabel
        self.formattedSize = formattedSize
        self.dateModifiedLine = dateModifiedLine
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
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            controlColumn

            if canSelectForBulk {
                Button {
                    isSelected.toggle()
                } label: {
                    rowMainContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                rowMainContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(0.55)
            }
        }
        .contextMenu {
            rowContextMenu
        }
        .padding(.vertical, 2)
        .padding(.horizontal, AppStyle.Spacing.xSmall)
        .frame(minHeight: AppStyle.Row.compactHeight)
        .background(rowBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                .stroke(isSelected ? AppStyle.selectionStroke : Color.clear)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHoveringRow = hovering
            }
        }
    }

    private var rowBackground: Color {
        if isSelected { return AppStyle.selectionFill }
        if isHoveringRow { return AppStyle.rowHover }
        return .clear
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

    /// Dot, icon, labels, size — hover popover attaches here so the checkbox column stays fully clickable.
    private var rowMainContent: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)

            Image(nsImage: resolvedIcon)
                .resizable()
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .opacity(0.88)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(primaryLabel)
                        .font(AppStyle.Typography.rowTitle)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(formattedSize)
                        .font(AppStyle.Typography.metadataEmphasis)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack(alignment: .center, spacing: 6) {
                    if let dateModifiedLine {
                        Text(dateModifiedLine)
                            .font(AppStyle.Typography.metadata)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    statusBadges
                }
            }
        }
        .onHover { hovering in
            hoverPopoverWorkItem?.cancel()
            hoverPopoverWorkItem = nil

            if hovering {
                let work = DispatchWorkItem { showSafetyPopover = true }
                hoverPopoverWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: work)
            } else {
                showSafetyPopover = false
            }
        }
        .popover(isPresented: $showSafetyPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 10) {
                Text(statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(popoverStatusColor)
                Text(popoverExplanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if offersUnknownDeletion {
                    Divider()
                    Button("Delete…", role: .destructive) {
                        showSafetyPopover = false
                        onRequestUnknownDelete?()
                    }
                    .controlSize(.small)
                }
            }
            .padding(12)
            .frame(width: 300, alignment: .leading)
        }
    }

    @ViewBuilder
    private var statusBadges: some View {
        AppBadge(text: statusLabel, tone: statusTone)
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

    private var controlColumn: some View {
        Toggle("", isOn: $isSelected)
            .labelsHidden()
            .disabled(!canSelectForBulk)
            .opacity(canSelectForBulk ? 1 : 0.45)
    }
}
