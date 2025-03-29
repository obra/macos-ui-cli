// ABOUTME: Main entry point for the Accessibility Explorer app
// ABOUTME: Creates the app with necessary dependencies and launches the UI

import SwiftUI
import AppKit

@main
struct AccessibilityExplorerApp: App {
    // Use the safe explorer by default, which has proper safety measures
    var body: some Scene {
        WindowGroup {
            SafeExplorerContent()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Add a menu command to toggle safe mode
            CommandGroup(after: .appSettings) {
                Divider()
                Text("Safety Controls")
                Toggle("Enable Safe Mode", isOn: .constant(true))
                    .disabled(true) // Just for information, actual toggle is in the UI
            }
            
            // Add a help menu
            CommandGroup(after: .help) {
                Button("Accessibility Explorer Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/jessesquires/macos-ui-cli/tree/main/AccessibilityExplorer")!)
                }
            }
        }
    }
}

// Main content wrapper that uses our safe explorer
struct SafeExplorerContent: View {
    // Use the SafeExplorerViewModel which includes all our safety measures
    @StateObject private var viewModel = SafeExplorerViewModel()
    
    var body: some View {
        ContentView()
            .environmentObject(viewModel)
            .onAppear {
                // Set up any initial state
                print("AccessibilityExplorer starting up in safe mode")
            }
    }
}