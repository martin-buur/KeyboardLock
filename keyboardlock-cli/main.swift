//
//  main.swift
//  keyboardlock-cli
//
//  Created by Martijn Buurman on 01/01/2026.
//

import Foundation

func printUsage() {
    print("""
    Usage: keyboardlock <command>

    Commands:
        lock      Lock the keyboard
        unlock    Unlock the keyboard
        toggle    Toggle keyboard lock state
        status    Get current lock status
        help      Show this help message

    Examples:
        keyboardlock lock
        keyboardlock toggle
    """)
}

func openURL(_ urlString: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [urlString]

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}

guard CommandLine.arguments.count > 1 else {
    printUsage()
    exit(1)
}

let command = CommandLine.arguments[1].lowercased()

switch command {
case "lock":
    openURL("keyboardlock://lock")
    print("Keyboard locked")

case "unlock":
    openURL("keyboardlock://unlock")
    print("Keyboard unlocked")

case "toggle":
    openURL("keyboardlock://toggle")
    print("Keyboard toggled")

case "help", "-h", "--help":
    printUsage()

default:
    print("Unknown command: \(command)")
    printUsage()
    exit(1)
}
