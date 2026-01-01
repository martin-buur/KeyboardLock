//
//  LockOverlayWindow.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import Cocoa
import SwiftUI

final class LockOverlayController {
    private var overlayWindows: [NSWindow] = []

    func show() {
        // Create an overlay for each screen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
            window.orderFrontRegardless()
        }
    }

    func hide() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true // Click-through
        window.contentView = NSHostingView(rootView: LockOverlayView())

        return window
    }
}

struct LockOverlayView: View {
    var body: some View {
        ZStack {
            // Semi-transparent dark background
            Color.black.opacity(0.7)

            VStack(spacing: 24) {
                Image(systemName: "keyboard")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Keyboard Locked")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)

                Text("Press ⌘ 6 times to unlock")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("or click the menu bar icon")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LockOverlayView()
        .frame(width: 800, height: 600)
}
