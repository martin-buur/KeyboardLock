//
//  SettingsView.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.autoUnlockEnabled) private var autoUnlockEnabled = true
    @AppStorage(SettingsKey.autoUnlockDuration) private var autoUnlockDuration: Double = 120
    @AppStorage(SettingsKey.defaultLockMode) private var defaultLockMode = LockMode.keyboard.rawValue

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Auto-unlock after timeout", isOn: $autoUnlockEnabled)

                if autoUnlockEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Slider(value: $autoUnlockDuration, in: 30...300, step: 30) {
                            Text("Duration")
                        }
                        Text(formatDuration(autoUnlockDuration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Auto-Unlock Timer")
            }

            Section {
                Picker("Default lock mode", selection: $defaultLockMode) {
                    Text("Keyboard").tag(LockMode.keyboard.rawValue)
                    Text("Keyboard + Mouse").tag(LockMode.keyboardMouse.rawValue)
                    Divider()
                    Text("Keyboard (cat mode)").tag(LockMode.keyboardSilent.rawValue)
                    Text("Keyboard + Mouse (cat mode)").tag(LockMode.keyboardMouseSilent.rawValue)
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Text("System")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes) min \(secs) sec"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(secs) sec"
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
