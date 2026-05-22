import SwiftUI

// MARK: - Row count

enum SkeletonRowCount {
    static let defaultCount = 8
    static let minimum = 6
    static let maximum = 12

    static func clamped(_ count: Int, default defaultCount: Int = defaultCount) -> Int {
        guard count > 0 else { return defaultCount }
        return max(minimum, min(maximum, count))
    }
}

// MARK: - Primitives

enum SkeletonOpacity {
    static let strong: Double = 0.2
    static let medium: Double = 0.15
    static let light: Double = 0.14
    static let subtle: Double = 0.12
}

struct SkeletonBar: View {
    var width: CGFloat
    var height: CGFloat = 10
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.secondary.opacity(SkeletonOpacity.medium))
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

struct SkeletonCircle: View {
    var diameter: CGFloat

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(SkeletonOpacity.light))
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

// MARK: - Loading crossfade

/// Crossfades between a loading placeholder and loaded content (respects Reduce Motion).
struct ScanContentCrossfade<Loading: View, Loaded: View>: View {
    var isLoading: Bool
    @ViewBuilder var loading: () -> Loading
    @ViewBuilder var loaded: () -> Loaded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            loaded()
                .opacity(isLoading ? 0 : 1)
            loading()
                .opacity(isLoading ? 1 : 0)
                .allowsHitTesting(isLoading)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - List placeholder

/// List-shaped placeholder rows shown while a tab scan is in progress.
struct ScanListSkeletonPlaceholder: View {
    var rowCount: Int = SkeletonRowCount.defaultCount

    var body: some View {
        List {
            ForEach(0..<rowCount, id: \.self) { index in
                skeletonRow(index: index)
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(AppStyle.canvas)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading results")
    }

    private func skeletonRow(index: Int) -> some View {
        let primaryWidth: CGFloat = 120 + CGFloat((index * 17) % 81)
        let secondaryWidth: CGFloat = 140 + CGFloat((index * 13) % 60)
        let trailingWidth: CGFloat = 52 + CGFloat((index * 11) % 24)
        let badgeWidth: CGFloat = 72 + CGFloat((index * 7) % 20)

        return HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(SkeletonOpacity.light))
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.xxSmall) {
                HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(SkeletonOpacity.light))
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonBar(width: primaryWidth, height: 12)
                        SkeletonBar(width: secondaryWidth, height: 9)
                    }

                    Spacer(minLength: AppStyle.Spacing.xSmall)

                    SkeletonBar(width: trailingWidth, height: 10)
                    SkeletonBar(width: badgeWidth, height: 18, cornerRadius: AppStyle.Radius.chip)
                }
            }
        }
        .padding(.horizontal, AppStyle.Spacing.small)
        .padding(.vertical, 10)
        .frame(minHeight: AppStyle.Row.listRowMinHeight, alignment: .leading)
        .background(AppStyle.elevated, in: RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous)
                .stroke(AppStyle.hairline)
        }
        .listRowInsets(ScanListRowInsets.standard)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .shimmering()
    }
}

// MARK: - Filter chips

struct FilterChipSkeletonRow: View {
    var chipCount: Int = SafetyFilter.allCases.count

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<chipCount, id: \.self) { index in
                    let width: CGFloat = 64 + CGFloat((index * 11) % 36)
                    SkeletonBar(width: width, height: 26, cornerRadius: AppStyle.Radius.chip)
                        .shimmering()
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading filters")
    }
}

// MARK: - Status bar

struct ScanStatusBarSkeleton: View {
    var showsSelectedSummary: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            SkeletonBar(width: 88, height: 10)
            if showsSelectedSummary {
                Text("·")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                SkeletonBar(width: 72, height: 10)
            }

            Spacer(minLength: 12)

            if showsSelectedSummary {
                SkeletonBar(width: 64, height: 10)
                Text("·")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            SkeletonBar(width: 76, height: 10)
        }
        .font(.footnote)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppStyle.canvas)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppStyle.hairline)
                .frame(height: 1)
        }
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading scan summary")
    }
}

// MARK: - Deletion overlay

struct CleaningOverlay: View {
    var message: String = "Cleaning…"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.regular)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Shimmer

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.1),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: phase * geo.size.width * 2 - geo.size.width)
                    }
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .clipped()
    }
}
