//
//  KeyboardManager.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import Cocoa
import Combine

enum LockMode: String {
    case keyboard = "keyboard"
    case keyboardMouse = "keyboard-mouse"
    case keyboardSilent = "keyboard-silent"
    case keyboardMouseSilent = "keyboard-mouse-silent"

    var includesMouse: Bool {
        self == .keyboardMouse || self == .keyboardMouseSilent
    }

    var showsOverlay: Bool {
        self == .keyboard || self == .keyboardMouse
    }

    var showsUnlockButton: Bool {
        self == .keyboard
    }
}

extension Notification.Name {
    static let lockTimerUpdated = Notification.Name("com.keyboardlock.lockTimerUpdated")
}

final class KeyboardManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var hasPermission = false
    @Published private(set) var currentMode: LockMode?
    @Published private(set) var lockEndTime: Date?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let unlockTracker = UnlockTracker()
    private let overlayController = LockOverlayController()
    private var autoUnlockTimer: DispatchWorkItem?
    private var countdownTimer: Timer?

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

    func lock(mode: LockMode? = nil) {
        guard !isLocked else { return }
        let mode = mode ?? AppSettings.defaultLockMode

        // Check permission first
        checkPermission()
        guard hasPermission else {
            requestPermission()
            return
        }

        currentMode = mode

        // Build event mask based on mode
        var eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                      (1 << CGEventType.keyUp.rawValue) |
                                      (1 << CGEventType.flagsChanged.rawValue) |
                                      (1 << 14) // Media keys

        if mode.includesMouse {
            eventMask |= (1 << CGEventType.leftMouseDown.rawValue) |
                         (1 << CGEventType.leftMouseUp.rawValue) |
                         (1 << CGEventType.rightMouseDown.rawValue) |
                         (1 << CGEventType.rightMouseUp.rawValue) |
                         (1 << CGEventType.otherMouseDown.rawValue) |
                         (1 << CGEventType.otherMouseUp.rawValue) |
                         (1 << CGEventType.scrollWheel.rawValue)
        }

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
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: userInfo
        )

        guard let tap = eventTap else {
            print("Failed to create event tap. Check Input Monitoring permission.")
            currentMode = nil
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        unlockTracker.reset()
        isLocked = true

        // Start auto-unlock timer
        startAutoUnlockTimer()

        // Show overlay if mode requires it
        if mode.showsOverlay {
            overlayController.show(showUnlockButton: mode.showsUnlockButton)
        }

        postNotification(name: "KeyboardLockStateChanged", userInfo: ["locked": true])
    }

    func unlock() {
        guard isLocked else { return }

        // Cancel auto-unlock timer
        cancelAutoUnlockTimer()

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isLocked = false
        currentMode = nil
        lockEndTime = nil
        overlayController.hide()
        postNotification(name: "KeyboardLockStateChanged", userInfo: ["locked": false])
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lock(mode: AppSettings.defaultLockMode)
        }
    }

    // MARK: - Auto-Unlock Timer

    private func startAutoUnlockTimer() {
        guard UserDefaults.standard.bool(forKey: SettingsKey.autoUnlockEnabled) else {
            return
        }

        let duration = UserDefaults.standard.double(forKey: SettingsKey.autoUnlockDuration)
        let autoUnlockDuration = duration > 0 ? duration : 120

        lockEndTime = Date().addingTimeInterval(autoUnlockDuration)

        // Post initial timer update
        postTimerUpdate()

        // Start countdown timer for UI updates (every second)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.postTimerUpdate()
        }

        // Schedule auto-unlock
        let workItem = DispatchWorkItem { [weak self] in
            self?.unlock()
        }
        autoUnlockTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoUnlockDuration, execute: workItem)
    }

    private func cancelAutoUnlockTimer() {
        autoUnlockTimer?.cancel()
        autoUnlockTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func postTimerUpdate() {
        guard let endTime = lockEndTime else { return }
        let remaining = max(0, endTime.timeIntervalSinceNow)
        NotificationCenter.default.post(
            name: .lockTimerUpdated,
            object: nil,
            userInfo: ["remaining": remaining]
        )
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
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

        // Handle mouse events - block them if in mouse lock mode
        let mouseEvents: [CGEventType] = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp,
            .scrollWheel
        ]
        if mouseEvents.contains(type) {
            return nil // Block mouse event
        }

        // Check for CMD key press (unlock mechanism)
        if type == .flagsChanged {
            if unlockTracker.trackCmdKey(flags: event.flags) {
                DispatchQueue.main.async { [weak self] in
                    self?.unlock()
                }
                return Unmanaged.passRetained(event)
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
