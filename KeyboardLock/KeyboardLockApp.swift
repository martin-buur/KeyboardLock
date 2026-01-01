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
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardManager = KeyboardManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            keyboardManager.lock()
        case "unlock":
            keyboardManager.unlock()
        case "toggle":
            keyboardManager.toggle()
        default:
            break
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var keyboardManager: KeyboardManager

    var body: some View {
        if keyboardManager.isLocked {
            Button("Unlock Keyboard") {
                keyboardManager.unlock()
            }
            .keyboardShortcut("u", modifiers: [])
        } else {
            Button("Lock Keyboard") {
                keyboardManager.lock()
            }
            .keyboardShortcut("l", modifiers: [])
        }

        Divider()

        if !keyboardManager.hasPermission {
            Button("Grant Permission...") {
                keyboardManager.requestPermission()
            }
            Divider()
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
