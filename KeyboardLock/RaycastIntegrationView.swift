//
//  RaycastIntegrationView.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import SwiftUI

struct RaycastIntegrationView: View {
    private let quicklinks: [(mode: LockMode, name: String, description: String)] = [
        (.keyboard, "Lock Keyboard", "Shows overlay with unlock button"),
        (.keyboardMouse, "Lock Keyboard + Mouse", "Shows overlay, no unlock button"),
        (.keyboardSilent, "Lock Keyboard (Cat Mode)", "Silent lock, no overlay"),
        (.keyboardMouseSilent, "Lock Keyboard + Mouse (Cat Mode)", "Silent lock, blocks all input"),
    ]

    var body: some View {
        Form {
            Section {
                Text("Add KeyboardLock commands to Raycast for quick access via keyboard shortcuts.")
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(quicklinks, id: \.mode) { quicklink in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quicklink.name)
                            Text(quicklink.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Add to Raycast") {
                            addToRaycast(mode: quicklink.mode, name: quicklink.name)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Lock Commands")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock")
                        Text("Unlocks keyboard and mouse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Add to Raycast") {
                        addUnlockToRaycast()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Unlock Command")
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func addToRaycast(mode: LockMode, name: String) {
        let link = "keyboardlock://lock/\(mode.rawValue)"
        openRaycastQuicklinkCreator(name: name, link: link)
    }

    private func addUnlockToRaycast() {
        openRaycastQuicklinkCreator(name: "Unlock Keyboard", link: "keyboardlock://unlock")
    }

    private func openRaycastQuicklinkCreator(name: String, link: String) {
        let context = ["name": name]
        guard let contextData = try? JSONSerialization.data(withJSONObject: context),
              let contextString = String(data: contextData, encoding: .utf8),
              let encodedContext = contextString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedLink = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "raycast://extensions/raycast/raycast/create-quicklink?context=\(encodedContext)&fallbackText=\(encodedLink)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    RaycastIntegrationView()
}
