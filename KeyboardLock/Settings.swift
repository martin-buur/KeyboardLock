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
}

enum AppSettings {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.autoUnlockEnabled: true,
            SettingsKey.autoUnlockDuration: 120.0,
            SettingsKey.defaultLockMode: LockMode.keyboard.rawValue
        ])
    }

    static var defaultLockMode: LockMode {
        let rawValue = UserDefaults.standard.string(forKey: SettingsKey.defaultLockMode) ?? LockMode.keyboard.rawValue
        return LockMode(rawValue: rawValue) ?? .keyboard
    }
}
