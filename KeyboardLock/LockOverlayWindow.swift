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

    func show(showUnlockButton: Bool) {
        // Create an overlay for each screen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, showUnlockButton: showUnlockButton)
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

    private func createOverlayWindow(for screen: NSScreen, showUnlockButton: Bool) -> NSWindow {
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
        window.ignoresMouseEvents = false
        window.contentView = NSHostingView(rootView: LockOverlayView(showUnlockButton: showUnlockButton))

        return window
    }
}

struct LockOverlayView: View {
    let showUnlockButton: Bool

    @State private var pressCount = 0
    @State private var remainingSeconds: Int?
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

                if showUnlockButton {
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

            // Countdown timer at bottom
            if let remaining = remainingSeconds {
                VStack {
                    Spacer()
                    Text(timerText(remaining))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 32)
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .lockTimerUpdated)) { notification in
            if let remaining = notification.userInfo?["remaining"] as? TimeInterval {
                remainingSeconds = Int(remaining)
            }
        }
    }

    private func timerText(_ remainingSeconds: Int) -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "Auto-unlock in %d:%02d", minutes, seconds)
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
    LockOverlayView(showUnlockButton: true)
        .frame(width: 800, height: 600)
}
