//
//  Settings.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import SwiftUI

enum SettingsKey {
    static let autoUnlockEnabled = "autoUnlockEnabled"
    static let autoUnlockDuration = "autoUnlockDuration"
    static let defaultLockMode = "defaultLockMode"
    static let launchAtLogin = "launchAtLogin"
    static let showOverlay = "showOverlay"
    static let blockMouse = "blockMouse"
}

enum AppSettings {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.autoUnlockEnabled: true,
            SettingsKey.autoUnlockDuration: 120.0,
            SettingsKey.defaultLockMode: LockMode.keyboard.rawValue,
            SettingsKey.showOverlay: true,
            SettingsKey.blockMouse: false
        ])
    }

    static var defaultLockMode: LockMode {
        let rawValue = UserDefaults.standard.string(forKey: SettingsKey.defaultLockMode) ?? LockMode.keyboard.rawValue
        return LockMode(rawValue: rawValue) ?? .keyboard
    }

    static var showOverlay: Bool {
        get { UserDefaults.standard.bool(forKey: SettingsKey.showOverlay) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.showOverlay) }
    }

    static var blockMouse: Bool {
        get { UserDefaults.standard.bool(forKey: SettingsKey.blockMouse) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.blockMouse) }
    }

    static var lockModeFromToggles: LockMode {
        switch (showOverlay, blockMouse) {
        case (true, false): return .keyboard
        case (true, true): return .keyboardMouse
        case (false, false): return .keyboardSilent
        case (false, true): return .keyboardMouseSilent
        }
    }
}
