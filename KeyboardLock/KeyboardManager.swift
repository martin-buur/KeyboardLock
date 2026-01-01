//
//  KeyboardManager.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import Cocoa
import Combine

final class KeyboardManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var hasPermission = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let unlockTracker = UnlockTracker()
    private let overlayController = LockOverlayController()

    init() {
        checkPermission()
        setupDistributedNotifications()
    }

    deinit {
        unlock()
    }

    // MARK: - Permission Handling

    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Re-check after a delay (user might grant permission)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.checkPermission()
        }
    }

    // MARK: - Lock/Unlock

    func lock() {
        guard !isLocked else { return }

        // Check permission first
        checkPermission()
        guard hasPermission else {
            requestPermission()
            return
        }

        // Create event tap for keyboard events + media keys
        // NX_SYSDEFINED = 14 (for media keys like brightness, volume, play/pause)
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                      (1 << CGEventType.keyUp.rawValue) |
                                      (1 << CGEventType.flagsChanged.rawValue) |
                                      (1 << 14)

        // Store self pointer for callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<KeyboardManager>.fromOpaque(userInfo).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: userInfo
        )

        guard let tap = eventTap else {
            print("Failed to create event tap. Check Input Monitoring permission.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        unlockTracker.reset()
        isLocked = true
        overlayController.show()
        postNotification(name: "KeyboardLockStateChanged", userInfo: ["locked": true])
    }

    func unlock() {
        guard isLocked else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isLocked = false
        overlayController.hide()
        postNotification(name: "KeyboardLockStateChanged", userInfo: ["locked": false])
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lock()
        }
    }

    // MARK: - Event Handling

    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled by system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        }

        // Handle media keys (NX_SYSDEFINED, type 14)
        if type.rawValue == 14 {
            // Check if it's a media key event (subtype 8)
            if let nsEvent = NSEvent(cgEvent: event) {
                if nsEvent.subtype.rawValue == 8 {
                    // Block media key
                    return nil
                }
            }
            // Let other system-defined events through
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags

        // Check for CMD key press (unlock mechanism)
        if type == .flagsChanged {
            if unlockTracker.trackCmdKey(flags: flags) {
                DispatchQueue.main.async { [weak self] in
                    self?.unlock()
                }
                return Unmanaged.passRetained(event) // Let this key through
            }
        }

        // Block all other keyboard events
        return nil
    }

    // MARK: - Distributed Notifications (for CLI)

    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            self,
            selector: #selector(handleLockNotification),
            name: NSNotification.Name("com.keyboardlock.lock"),
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleUnlockNotification),
            name: NSNotification.Name("com.keyboardlock.unlock"),
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleToggleNotification),
            name: NSNotification.Name("com.keyboardlock.toggle"),
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleStatusNotification),
            name: NSNotification.Name("com.keyboardlock.status"),
            object: nil
        )
    }

    @objc private func handleLockNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.lock()
        }
    }

    @objc private func handleUnlockNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.unlock()
        }
    }

    @objc private func handleToggleNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.toggle()
        }
    }

    @objc private func handleStatusNotification() {
        postNotification(name: "com.keyboardlock.status.response", userInfo: ["locked": isLocked])
    }

    private func postNotification(name: String, userInfo: [String: Any]) {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name(name),
            object: nil,
            userInfo: userInfo,
            deliverImmediately: true
        )
    }
}
