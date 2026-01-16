//
//  RaycastIntegrationView.swift
//  KeyboardLock
//
//  Created by Martijn Buurman on 01/01/2026.
//

import SwiftUI

struct RaycastIntegrationView: View {
    var body: some View {
        Form {
            Section {
                Text("Add KeyboardLock commands to Raycast for quick access via keyboard shortcuts.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock")
                        Text("Locks keyboard using current settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Add to Raycast") {
                        openRaycastQuicklinkCreator(name: "Lock Keyboard", link: "keyboardlock://lock")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock")
                        Text("Unlocks keyboard and mouse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Add to Raycast") {
                        openRaycastQuicklinkCreator(name: "Unlock Keyboard", link: "keyboardlock://unlock")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Commands")
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
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
