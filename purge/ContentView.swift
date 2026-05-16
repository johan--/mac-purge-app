//
//  ContentView.swift
//  purge
//
//  Created by Jithin Sabu on 05/05/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PurgeStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    private let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    private var cleanSelectedTitle: String {
        guard store.selectedCount > 0 else { return "Clean Selected" }
        return "Clean Selected (\(formatBytes(store.selectedTotalBytes)))"
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if store.hasFullDiskAccess {
                tabContent
                    .frame(minWidth: 600, minHeight: 400)
            } else {
                PermissionPromptView {
                    store.refreshPermission()
                    if store.hasFullDiskAccess && !isRunningPreview {
                        Task { await store.scanAll() }
                    }
                }
            }
        }
        .task {
            guard !isRunningPreview else { return }
            if !hasCompletedOnboarding {
                showOnboarding = true
                return
            }
            guard store.hasFullDiskAccess, store.cacheItems.isEmpty, store.devTools.isEmpty, store.projectGroups.isEmpty else { return }
            await store.scanAll()
        }
        .onChange(of: hasCompletedOnboarding) { completed in
            guard !isRunningPreview, !completed else { return }
            showOnboarding = true
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !isRunningPreview else { return }
            Task {
                await ScheduledCleaningRegistrar.shared.runGracefulActivationSweepIfPastDue()
            }
        }
        .toolbar {
            if store.hasFullDiskAccess && store.selectedTab != .settings {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.showDeletionSheet = true
                    } label: {
                        Label(cleanSelectedTitle, systemImage: "trash.fill")
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                    }
                    .buttonStyle(AppButtonStyle(variant: .filled))
                    .disabled(store.selectedCount == 0 || store.isDeleting)
                }
            }
        }
        .sheet(isPresented: $store.showDeletionSheet) {
            DeletionConfirmSheet(
                candidates: store.deletionCandidatesForSheet,
                onCancel: { store.dismissDeletionSheet() },
                onConfirm: {
                    store.userConfirmedDeletionFromPrimarySheet()
                }
            )
        }
        .sheet(item: $store.pendingUnknownDeletion) { payload in
            UnknownDeleteConfirmSheet(
                candidates: payload.candidates,
                onCancel: { store.dismissUnknownDeletionRequest() },
                onConfirm: {
                    Task { await store.userConfirmedUnknownDeletionFlow() }
                }
            )
        }
        .sheet(item: $store.lastDeletionReport) { report in
            DeletionSummarySheet(
                report: report,
                onDone: {
                    store.lastDeletionReport = nil
                },
                onScanAgain: {
                    store.lastDeletionReport = nil
                    if !isRunningPreview {
                        Task { await store.scanAll() }
                    }
                }
            )
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                onComplete: completeOnboarding
            )
            .interactiveDismissDisabled(true)
        }
        .alert(
            "Missing reinstall instructions",
            isPresented: $store.showMissingLockfileFriction
        ) {
            Button("Cancel", role: .cancel) { store.cancelDeletionFrictionFlow() }
            Button("Delete anyway", role: .destructive) { store.acknowledgeMissingLockfileRisk() }
        } message: {
            Text(
                """
                We could not find the file that tells us how to reinstall this folder. Deleting is probably fine, but \
                when you reinstall later it might download slightly different versions than before.
                """
            )
        }
        .alert(
            "You have unsaved code changes nearby",
            isPresented: $store.showUncommittedGitFriction
        ) {
            Button("Pause", role: .cancel) { store.cancelDeletionFrictionFlow() }
            Button("Clean anyway", role: .destructive) { store.acknowledgeUncommittedGitRisk() }
        } message: {
            Text(
                """
                One of your projects has changes that have not been saved to git yet. Make sure your work is backed \
                up before cleaning. Purge cannot undo deletions.
                """
            )
        }
        .alert(
            "Permanently delete these items?",
            isPresented: $store.showHighRiskDeletionSecondConfirm
        ) {
            Button("Cancel", role: .cancel) { store.cancelHighRiskDeletionSecondStep() }
            Button("Delete permanently", role: .destructive) { store.confirmHighRiskDeletionSecondStep() }
        } message: {
            Text(
                """
                This includes folders marked Do Not Delete and/or Not Sure. They will be removed immediately and \
                cannot be restored by Purge. Only continue if you understand the risk.
                """
            )
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .frame(minWidth: 800, minHeight: 600)
        .tint(AppStyle.accent)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        showOnboarding = false

        guard !isRunningPreview, store.hasFullDiskAccess else { return }
        Task { await store.scanAll() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Purge")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Local cleanup")
                        .font(AppStyle.Typography.metadata)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.top, AppStyle.Spacing.medium)

                VStack(spacing: 2) {
                    ForEach(PurgeStore.Tab.allCases) { tab in
                        AppNavRow(
                            title: tab.rawValue,
                            systemImage: tab.icon,
                            isSelected: store.selectedTab == tab,
                            action: { store.selectedTab = tab }
                        )
                    }
                }
            }
            .padding(.horizontal, AppStyle.Spacing.small)

            Spacer(minLength: AppStyle.Spacing.medium)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
                Text("Space Freed")
                    .font(AppStyle.Typography.metadata)
                    .foregroundStyle(.tertiary)
                Text(formatBytes(store.totalRecoveredBytes))
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()
                Capsule(style: .continuous)
                    .fill(AppStyle.hairline)
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(AppStyle.accent)
                            .frame(width: 44, height: 3)
                    }
            }
            .padding(AppStyle.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppStyle.elevated)
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous)
                    .stroke(AppStyle.hairline)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous))
            .padding(AppStyle.Spacing.small)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
        .background(AppStyle.panel)
        .navigationTitle("Purge")
    }

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            AppStyle.canvas
                .ignoresSafeArea()

            switch store.selectedTab {
            case .appCaches:
                AppCachesView(
                    items: $store.cacheItems,
                    isLoading: store.isScanningGeneral,
                    onScan: { Task { await store.scanGeneral() } }
                )
            case .devTools:
                DevToolsView(
                    isLoading: store.isScanningDeveloper,
                    onScan: { Task { await store.scanDeveloper() } }
                )
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(makePreviewStore())
}

private func makePreviewStore() -> PurgeStore {
    let store = PurgeStore()
    store.hasFullDiskAccess = true
    store.cacheItems = [
        CacheItem(
            appName: "Safari",
            bundleID: "com.apple.Safari",
            path: URL(fileURLWithPath: "/Users/preview/Library/Caches/com.apple.Safari"),
            sizeBytes: 845_000_000,
            lastModified: Date(),
            isSelected: false,
            safetyInfo: SafetyInfo(
                level: .safe,
                headline: "Application caches are safe to remove",
                explanation: "Apps recreate cache files automatically after relaunch.",
                recoverySteps: "Reopen the app and continue using it.",
                reinstallCommand: nil
            ),
            reinstallSafety: .notApplicable,
            gitStatus: .unknown
        )
    ]
    return store
}
