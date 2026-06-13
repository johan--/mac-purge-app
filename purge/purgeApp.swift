//
//  purgeApp.swift
//  purge
//
//  Created by Jithin Sabu on 05/05/26.
//

import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class PurgeAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply the saved appearance before the first paint to avoid a launch flash.
        AppAppearance.apply(AppearanceMode.current)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        CleaningQuitGuard.shouldAllowTermination() ? .terminateNow : .terminateCancel
    }
}

@main
struct PurgeApp: App {
    @NSApplicationDelegateAdaptor(PurgeAppDelegate.self) private var appDelegate
    @StateObject private var store = PurgeStore()
    @StateObject private var diskStore = DiskSummaryStore()
    @AppStorage(AppearanceMode.userDefaultsKey)
    private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var systemThemeObserver: NSObjectProtocol?
    @State private var activeColorScheme: ColorScheme = {
        let mode = AppearanceMode.current
        switch mode {
        case .light: return .light
        case .dark: return .dark
        case .system: return .light
        }
    }()

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    /// SwiftUI semantic colors need `preferredColorScheme`; AppKit-backed menu
    /// pickers need `NSApp`/`NSWindow` appearance. Apply both together.
    private func applyAppAppearance() {
        AppAppearance.apply(appearanceMode)
        activeColorScheme = appearanceMode.resolvedColorScheme
    }

    init() {
        UNUserNotificationCenter.current().delegate = ScheduledNotificationPresentationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(diskStore)
                .onAppear {
                    diskStore.refresh()
                    ScheduledCleaningRegistrar.shared.attach(store: store)
                    CleaningQuitGuard.isCleaningActive = { [weak store] in
                        store?.isManualCleaningInProgress ?? false
                    }
                    applyAppAppearance()
                    systemThemeObserver = AppAppearance.addSystemThemeObserver {
                        guard appearanceMode == .system else { return }
                        applyAppAppearance()
                    }
                }
                .font(.system(.body, design: .rounded))
                .preferredColorScheme(activeColorScheme)
                .onChange(of: appearanceModeRaw) { _ in
                    applyAppAppearance()
                }
                .onDisappear {
                    if let systemThemeObserver {
                        DistributedNotificationCenter.default().removeObserver(systemThemeObserver)
                    }
                }
        }
        .defaultSize(width: AppWindowLayout.width, height: AppWindowLayout.defaultHeight)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            PurgeCommands(store: store)
        }

        MenuBarExtra(formatBytes(store.safeRecoverableBytes), systemImage: "externaldrive.badge.minus") {
            Button("Open Purge") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            Divider()
            VStack(alignment: .leading, spacing: 2) {
                Text("Safe to clean: \(formatBytes(store.safeRecoverableBytes))")
                    .font(.headline)
                Text("\(formatBytes(store.totalRecoveredBytes)) recovered so far")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            Divider()
            Button("Clean Safe Files Now") {
                Task { await store.performManualSafeCleanNow() }
            }
            .disabled(store.isDeleting)
            Divider()
            Button("Quit Purge") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct PurgeCommands: Commands {
    let store: PurgeStore

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {}
                .keyboardShortcut(",", modifiers: .command)
                .disabled(true)
        }
        CommandGroup(after: .newItem) {
            Button("Scan All") {
                Task { await store.scanAll() }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(!store.hasFullDiskAccess || store.isDeleting)
        }
        CommandGroup(replacing: .undoRedo) {}
    }
}
