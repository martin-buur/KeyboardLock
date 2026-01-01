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
            Image(systemName: appDelegate.keyboardManager.isLocked ? "keyboard.badge.ellipsis" : "keyboard")
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

        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        handleDeepLink(url)
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

struct MenuBarView: View {
    @ObservedObject var keyboardManager: KeyboardManager

    var body: some View {
        if keyboardManager.isLocked {
            Button("Unlock") {
                keyboardManager.unlock()
            }
            .keyboardShortcut("u", modifiers: [])
        } else {
            Button("Lock Keyboard") {
                keyboardManager.lock(mode: .keyboard)
            }
            .keyboardShortcut("1", modifiers: [])

            Button("Lock Keyboard + Mouse") {
                keyboardManager.lock(mode: .keyboardMouse)
            }
            .keyboardShortcut("2", modifiers: [])

            Divider()

            Button("Lock Keyboard (cat mode)") {
                keyboardManager.lock(mode: .keyboardSilent)
            }
            .keyboardShortcut("3", modifiers: [])

            Button("Lock Keyboard + Mouse (cat mode)") {
                keyboardManager.lock(mode: .keyboardMouseSilent)
            }
            .keyboardShortcut("4", modifiers: [])
        }

        Divider()

        if !keyboardManager.hasPermission {
            Button("Grant Permission...") {
                keyboardManager.requestPermission()
            }
            Divider()
        }

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
