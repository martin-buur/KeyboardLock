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

            Section("Commands") {
                commandRow(
                    title: "Lock",
                    subtitle: "Locks keyboard using current settings",
                    raycastName: "Lock Keyboard",
                    link: "keyboardlock://lock"
                )
                commandRow(
                    title: "Unlock",
                    subtitle: "Unlocks keyboard and mouse",
                    raycastName: "Unlock Keyboard",
                    link: "keyboardlock://unlock"
                )
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func commandRow(title: String, subtitle: String, raycastName: String, link: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Add to Raycast") {
                openRaycastQuicklinkCreator(name: raycastName, link: link)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
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
