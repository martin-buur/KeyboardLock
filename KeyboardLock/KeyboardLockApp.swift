//
//  KeyboardLockApp.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import SwiftUI

@main
struct KeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(keyboardManager: appDelegate.keyboardManager)
        } label: {
            MenuBarIcon(keyboardManager: appDelegate.keyboardManager)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardManager = KeyboardManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "keyboardlock" else { return }

        switch url.host {
        case "lock":
            // Check for mode in path: keyboardlock://lock/keyboard-mouse
            if let mode = url.pathComponents.dropFirst().first,
               let lockMode = LockMode(rawValue: mode) {
                keyboardManager.lock(mode: lockMode)
            } else {
                keyboardManager.lock()
            }
        case "unlock":
            keyboardManager.unlock()
        default:
            break
        }
    }
}

struct MenuBarIcon: View {
    @ObservedObject var keyboardManager: KeyboardManager

    var body: some View {
        Image(systemName: keyboardManager.isLocked ? "keyboard.fill" : "keyboard")
    }
}

struct MenuBarView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @AppStorage(SettingsKey.showOverlay) private var showOverlay = true
    @AppStorage(SettingsKey.blockMouse) private var blockMouse = false

    var body: some View {
        if keyboardManager.isLocked {
            Button("Unlock") {
                keyboardManager.unlock()
            }
            .keyboardShortcut("u", modifiers: [])
        } else {
            Button("Lock") {
                keyboardManager.lock(mode: AppSettings.lockModeFromToggles)
            }
            .keyboardShortcut("l", modifiers: [])
        }

        Divider()

        Toggle("Show Overlay", isOn: $showOverlay)
            .disabled(keyboardManager.isLocked)

        Toggle("Block Mouse", isOn: $blockMouse)
            .disabled(keyboardManager.isLocked)

        Divider()

        if !keyboardManager.hasPermission {
            Button("Grant Accessibility...") {
                keyboardManager.requestPermission()
            }
            Divider()
        }

        Button("Check for Updates...") {
            UpdaterService.shared.checkForUpdates()
        }

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
