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
        window.ignoresMouseEvents = false // Block clicks - unlock via button or CMD key
        window.contentView = NSHostingView(rootView: LockOverlayView())

        return window
    }
}

struct LockOverlayView: View {
    @State private var pressCount = 0
    private let requiredPresses = 6

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 24) {
                Image(systemName: "keyboard")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Keyboard Locked")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)

                if pressCount > 0 {
                    let remaining = requiredPresses - pressCount
                    HStack(spacing: 12) {
                        ForEach(0..<requiredPresses, id: \.self) { index in
                            Circle()
                                .fill(index < pressCount ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                    }
                    .padding(.vertical, 8)

                    Text("\(remaining) more")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .contentTransition(.numericText())
                } else {
                    Text("Press ⌘ 6 times to unlock")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Button(action: unlock) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open")
                        Text("Unlock")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .unlockProgressChanged)) { notification in
            if let count = notification.userInfo?["pressCount"] as? Int {
                withAnimation(.easeInOut(duration: 0.15)) {
                    pressCount = count
                }
            }
        }
    }

    private func unlock() {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.keyboardlock.unlock"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}

#Preview {
    LockOverlayView()
        .frame(width: 800, height: 600)
}
