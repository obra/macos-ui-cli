// ABOUTME: This file contains the main entry point for the MacOSUICLI application.
// ABOUTME: It defines the root command and handles basic CLI argument parsing.

import Foundation
import ArgumentParser

/// Command to check and request accessibility permissions
struct PermissionsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "permissions",
        abstract: "Check and request accessibility permissions"
    )
    
    @Flag(name: .long, help: "Prompt the user to enable accessibility permissions")
    var request = false
    
    @Flag(name: .long, help: "Open the System Preferences to the Accessibility section")
    var open = false
    
    func run() throws {
        if open {
            print("Opening Accessibility preferences...")
            AccessibilityPermissions.openAccessibilityPreferences()
            return
        }
        
        let status = request ? 
            AccessibilityPermissions.requestPermission() : 
            AccessibilityPermissions.checkPermission()
            
        switch status {
        case .granted:
            print("Accessibility permissions are granted")
        case .denied:
            print("Accessibility permissions are denied")
            print(AccessibilityPermissions.getPermissionError())
        case .unknown:
            print("Accessibility permission status could not be determined")
        }
    }
}

/// Command to list and find applications
struct ApplicationsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "apps",
        abstract: "List and find applications"
    )
    
    @Flag(name: .long, help: "Show the focused application")
    var focused = false
    
    @Option(name: .shortAndLong, help: "Find application by name")
    var name: String?
    
    @Option(name: .shortAndLong, help: "Find application by PID")
    var pid: Int32?
    
    func run() throws {
        if focused {
            if let app = ApplicationManager.getFocusedApplication() {
                print("Focused application: \(app.name) (PID: \(app.pid))")
            } else {
                print("No focused application found")
            }
            return
        }
        
        if let pid = pid {
            if let app = ApplicationManager.getApplicationByPID(pid) {
                print("Application found: \(app.name) (PID: \(app.pid))")
            } else {
                print("No application found with PID \(pid)")
            }
            return
        }
        
        if let name = name {
            if let app = ApplicationManager.getApplicationByName(name) {
                print("Application found: \(app.name) (PID: \(app.pid))")
            } else {
                print("No application found with name \(name)")
            }
            return
        }
        
        // Default: list all applications
        let apps = ApplicationManager.getAllApplications()
        if apps.isEmpty {
            print("No applications found")
        } else {
            print("Applications:")
            for app in apps {
                print("- \(app.name) (PID: \(app.pid))")
            }
        }
    }
}

struct MacOSUICLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "macos-ui-cli",
        abstract: "Command-line tool for macOS UI automation via accessibility APIs",
        version: "0.1.0",
        subcommands: [
            PermissionsCommand.self,
            ApplicationsCommand.self
        ],
        defaultSubcommand: nil
    )
    
    func run() throws {
        print("MacOSUICLI - Command-line tool for macOS UI automation")
        print("Version: \(MacOSUICLI.configuration.version)")
        print("Use --help to see available commands")
        
        // Check if Haxcessibility is available
        print("Haxcessibility available: \(SystemAccessibility.isAvailable() ? "Yes" : "No")")
    }
}

MacOSUICLI.main()
