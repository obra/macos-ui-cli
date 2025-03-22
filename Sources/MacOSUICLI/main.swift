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

/// Command to list and find windows
struct WindowsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "windows",
        abstract: "List and find windows"
    )
    
    @Flag(name: .long, help: "Show the focused window")
    var focused = false
    
    @Option(name: .shortAndLong, help: "Application name to list windows for")
    var app: String?
    
    @Option(name: .shortAndLong, help: "Application PID to list windows for")
    var pid: Int32?
    
    func run() throws {
        // Get the application first
        var application: Application? = nil
        
        if let appName = app {
            application = ApplicationManager.getApplicationByName(appName)
            if application == nil {
                print("No application found with name: \(appName)")
                return
            }
        } else if let appPid = pid {
            application = ApplicationManager.getApplicationByPID(appPid)
            if application == nil {
                print("No application found with PID: \(appPid)")
                return
            }
        } else if focused {
            application = ApplicationManager.getFocusedApplication()
            if application == nil {
                print("No focused application found")
                return
            }
        }
        
        // If no application specified, use the focused one
        if application == nil {
            application = ApplicationManager.getFocusedApplication()
            if application == nil {
                print("No focused application found")
                return
            }
        }
        
        // Get and display windows
        guard let app = application else { return }
        
        print("Windows for \(app.name):")
        let windows = app.getWindows()
        
        if windows.isEmpty {
            print("No windows found")
        } else {
            for (index, window) in windows.enumerated() {
                print("\(index + 1). \(window.title) - \(window.frame.width)x\(window.frame.height)")
            }
        }
    }
}

/// Command to find, inspect, and interact with UI elements
struct ElementsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "elements",
        abstract: "Find, inspect, and interact with UI elements"
    )
    
    @Flag(name: .long, help: "Show the focused element")
    var focused = false
    
    @Option(name: .long, help: "Find elements by role (button, textField, etc.)")
    var role: String?
    
    @Option(name: .long, help: "Find elements by title or label")
    var title: String?
    
    @Option(name: .long, help: "Find element by path (e.g., 'window[Main]/button[OK]')")
    var path: String?
    
    @Option(name: .long, help: "Application name to search in")
    var app: String?
    
    @Option(name: .long, help: "Application PID to search in")
    var pid: Int32?
    
    func run() throws {
        // Handle focused element request
        if focused {
            if let element = ElementFinder.getFocusedElement() {
                print("Focused element:")
                printElementDetails(element)
            } else {
                print("No focused element found")
            }
            return
        }
        
        // Get the application first
        var application: Application? = nil
        
        if let appName = app {
            application = ApplicationManager.getApplicationByName(appName)
            if application == nil {
                print("No application found with name: \(appName)")
                return
            }
        } else if let appPid = pid {
            application = ApplicationManager.getApplicationByPID(appPid)
            if application == nil {
                print("No application found with PID: \(appPid)")
                return
            }
        } else {
            application = ApplicationManager.getFocusedApplication()
            if application == nil {
                print("No focused application found")
                return
            }
        }
        
        guard let app = application else { return }
        print("Searching in application: \(app.name)")
        
        // Get the focused window by default
        guard let window = app.getFocusedWindow() else {
            print("No focused window found")
            return
        }
        
        // Convert Window to Element for searching
        let rootElement = Element(role: "window", title: window.title)
        
        // Handle path search
        if let pathQuery = path {
            if let element = ElementFinder.findElementByPath(pathQuery, in: rootElement) {
                print("Element found at path '\(pathQuery)':")
                printElementDetails(element)
            } else {
                print("No element found at path '\(pathQuery)'")
            }
            return
        }
        
        // Handle role/title search
        let elements = ElementFinder.findElements(
            in: rootElement,
            byRole: role,
            byTitle: title
        )
        
        if elements.isEmpty {
            print("No matching elements found")
        } else {
            print("Found \(elements.count) matching elements:")
            for (index, element) in elements.enumerated() {
                print("\(index + 1). \(element.role): \(element.title)")
            }
        }
    }
    
    /// Prints detailed information about an element
    /// - Parameter element: The element to print details for
    private func printElementDetails(_ element: Element) {
        print("- Role: \(element.role)")
        print("- Title: \(element.title)")
        print("- Has children: \(element.hasChildren)")
        
        let attributes = element.getAttributes()
        if !attributes.isEmpty {
            print("- Attributes:")
            for (key, value) in attributes {
                print("  - \(key): \(value)")
            }
        }
        
        if !element.children.isEmpty {
            print("- Children:")
            for (index, child) in element.children.enumerated() {
                print("  \(index + 1). \(child.role): \(child.title)")
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
            ApplicationsCommand.self,
            WindowsCommand.self,
            ElementsCommand.self
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
