//
//  UnlockTracker.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import Cocoa

final class UnlockTracker {
    private var cmdPressCount = 0
    private var lastPressTime: Date?
    private let timeWindow: TimeInterval = 2.0
    private let requiredPresses = 6

    private var cmdWasPressed = false

    func reset() {
        cmdPressCount = 0
        lastPressTime = nil
        cmdWasPressed = false
    }

    /// Track CMD key presses from flagsChanged events.
    /// Returns true when unlock should trigger.
    func trackCmdKey(flags: CGEventFlags) -> Bool {
        let cmdPressed = flags.contains(.maskCommand)

        // Detect CMD key press (transition from not pressed to pressed)
        if cmdPressed && !cmdWasPressed {
            cmdWasPressed = true
            return registerPress()
        } else if !cmdPressed && cmdWasPressed {
            // CMD key released
            cmdWasPressed = false
        }

        return false
    }

    private func registerPress() -> Bool {
        let now = Date()

        if let last = lastPressTime, now.timeIntervalSince(last) < timeWindow {
            cmdPressCount += 1
        } else {
            // Time window expired, start fresh
            cmdPressCount = 1
        }
        lastPressTime = now

        if cmdPressCount >= requiredPresses {
            reset()
            return true
        }

        return false
    }
}
