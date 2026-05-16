import SwiftUI

struct AppPageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                Text(title)
                    .font(AppStyle.Typography.pageTitle)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppStyle.Spacing.medium)

            trailing()
        }
        .padding(.horizontal, AppStyle.Spacing.large)
        .padding(.top, AppStyle.Spacing.large)
        .padding(.bottom, AppStyle.Spacing.small)
    }
}

struct AppButtonStyle: ButtonStyle {
    enum Variant {
        case bordered
        case filled
        case ghost
        case destructive
    }

    var variant: Variant = .bordered

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background(configuration: configuration))
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.45)
    }

    private var foregroundStyle: Color {
        switch variant {
        case .bordered, .ghost:
            return .primary
        case .filled:
            return .white
        case .destructive:
            return AppStyle.danger
        }
    }

    private func background(configuration: Configuration) -> Color {
        switch variant {
        case .bordered:
            return configuration.isPressed ? AppStyle.rowHover : AppStyle.elevated
        case .filled:
            return AppStyle.accent
        case .ghost:
            return configuration.isPressed ? AppStyle.rowHover : .clear
        case .destructive:
            return AppStyle.danger.opacity(configuration.isPressed ? 0.18 : 0.1)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
            .stroke(variant == .filled ? Color.clear : AppStyle.hairline)
    }
}

struct AppBadge: View {
    enum Tone {
        case neutral
        case accent
        case safe
        case warning
        case danger
    }

    let text: String
    var tone: Tone = .neutral

    var body: some View {
        Text(text)
            .font(AppStyle.Typography.metadataEmphasis)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous)
                    .stroke(color.opacity(0.14))
            }
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous))
    }

    private var color: Color {
        switch tone {
        case .neutral: return .secondary
        case .accent: return AppStyle.accent
        case .safe: return AppStyle.safe
        case .warning: return AppStyle.warning
        case .danger: return AppStyle.danger
        }
    }
}

struct AppNavRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppStyle.Spacing.xSmall) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? AppStyle.accent : .secondary)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: AppStyle.Spacing.xSmall)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? AppStyle.selectionFill : Color.clear)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                        .stroke(AppStyle.selectionStroke)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AppSortMenu: View {
    @Binding var selection: SortOption

    var body: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    selection = option
                } label: {
                    if option == selection {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
            }
        } label: {
            Label(selection.shortDisplayName, systemImage: "arrow.up.arrow.down")
                .labelStyle(.titleAndIcon)
        }
        .menuStyle(.button)
        .buttonStyle(AppButtonStyle(variant: .bordered))
        .fixedSize()
        .accessibilityLabel("Sort by \(selection.displayName)")
    }
}

