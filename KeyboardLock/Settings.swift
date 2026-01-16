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
    static let launchAtLogin = "launchAtLogin"
    static let showOverlay = "showOverlay"
    static let blockMouse = "blockMouse"
}

enum AppSettings {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.autoUnlockEnabled: true,
            SettingsKey.autoUnlockDuration: 120.0,
            SettingsKey.showOverlay: true,
            SettingsKey.blockMouse: false
        ])
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
        LockMode(showsOverlay: showOverlay, blocksMouse: blockMouse)
    }
}
