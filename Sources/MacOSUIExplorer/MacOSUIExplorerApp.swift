// ABOUTME: This file contains the main app entry point for the SwiftUI-based Accessibility Explorer.
// ABOUTME: It defines the app structure and initializes key view models.

import SwiftUI
import MacOSUICLILib
import AppKit

// App entry point defined in main.swift
struct MacOSUIExplorerApp: App {
    // Initialize our view models that will be shared throughout the app
    @StateObject private var applicationViewModel = ApplicationViewModel()
    @StateObject private var elementTreeViewModel = ElementTreeViewModel()
    
    init() {
        // Initialize the safety mode
        _ = SafetyMode.shared
        
        // Set up app exception handler
        NSSetUncaughtExceptionHandler { exception in
            DebugLogger.shared.log("CRITICAL: Uncaught exception: \(exception)")
            DebugLogger.shared.log("Name: \(exception.name.rawValue), Reason: \(exception.reason ?? "unknown")")
            let callStackSymbols = exception.callStackSymbols 
            DebugLogger.shared.log("Call stack: \(callStackSymbols.joined(separator: "\n"))")
        }
        
        DebugLogger.shared.log("App initialized - Safety mode active by default")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(applicationViewModel)
                .environmentObject(elementTreeViewModel)
                .onAppear {
                    // Check and request accessibility permissions on launch
                    let permissionStatus = AccessibilityPermissions.checkPermission()
                    if permissionStatus != .granted {
                        let _ = AccessibilityPermissions.requestPermission()
                    }
                    
                    // Load running applications
                    applicationViewModel.refreshApplications()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Accessibility") {
                Button("Refresh Applications") {
                    applicationViewModel.refreshApplications()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Button("Refresh Element Tree") {
                    elementTreeViewModel.refreshCurrentView()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Show Element Bounds") {
                    elementTreeViewModel.toggleElementBoundsOverlay()
                }
                .keyboardShortcut("b", modifiers: [.command])
                
                Divider()
                
                // Add safety mode toggle
                Toggle("Safety Mode", isOn: Binding(
                    get: { SafetyMode.shared.isEnabled },
                    set: { SafetyMode.shared.isEnabled = $0 }
                ))
                .keyboardShortcut("s", modifiers: [.command, .option])
                
                Button("Check CPU Usage") {
                    let usage = SafetyMode.shared.getCurrentCPUUsage()
                    
                    let alert = NSAlert()
                    alert.messageText = "CPU Usage"
                    alert.informativeText = "Current CPU usage: \(String(format: "%.1f", usage))%"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                .keyboardShortcut("u", modifiers: [.command, .option])
            }
        }
    }
}