// ABOUTME: This file contains the main entry point for the MacOSUICLI application.
// ABOUTME: It defines the root command and handles basic CLI argument parsing.

import Foundation
import ArgumentParser
import Haxcessibility

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
    
    @Flag(name: .long, help: "Create an app wrapper to simplify accessibility permissions")
    var createWrapper = false
    
    func run() throws {
        if createWrapper {
            print("Creating app wrapper...")
            // Import the AppWrapperCreator at runtime
            let wrapperCreated = AppWrapperCreator.createAppWrapper()
            if wrapperCreated {
                print("App wrapper created successfully")
                print("Please grant accessibility permissions to the app wrapper and run it from there")
            }
            return
        }
        
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

/// Command for text field operations
struct TextCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Read from or write to text fields"
    )
    
    @Flag(name: .shortAndLong, help: "Read text from the field instead of writing")
    var read = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .shortAndLong, help: "The title of the text field")
    var field: String
    
    @Option(name: .shortAndLong, help: "The text to write (required for write operation)")
    var value: String?
    
    func run() throws {
        // Get the application
        guard let application = ApplicationManager.getApplicationByName(app) else {
            print("Application '\(app)' not found")
            return
        }
        
        // Get the focused window
        guard let window = application.getFocusedWindow() else {
            print("No focused window found for \(app)")
            return
        }
        
        // Get elements in the window
        let elements = window.getElements()
        let rootElement = elements.first ?? Element(role: "window", title: window.title)
        
        // Find text field by title
        let textFields = ElementFinder.findElements(in: rootElement, byRole: "textField", byTitle: field)
        
        guard let textField = textFields.first else {
            print("No text field found with title '\(field)'")
            return
        }
        
        // Convert to TextFieldElement
        guard let textFieldElement = TextFieldElement.fromElement(textField) else {
            print("Found element is not a valid text field")
            return
        }
        
        // Perform read or write operation
        if read {
            if let value = textFieldElement.getValue() {
                print("Value of text field '\(field)': \(value)")
            } else {
                print("Could not read value from text field '\(field)'")
            }
        } else {
            guard let newValue = value else {
                print("Error: text value is required for write operation")
                return
            }
            
            if textFieldElement.setValue(newValue) {
                print("Successfully set text field '\(field)' to: \(newValue)")
            } else {
                print("Failed to set value for text field '\(field)'")
            }
        }
    }
}

/// Command for button operations
struct ButtonCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "button",
        abstract: "Interact with buttons"
    )
    
    @Flag(name: .shortAndLong, help: "Press the button")
    var press = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .shortAndLong, help: "The title of the button")
    var title: String
    
    func run() throws {
        // Get the application
        guard let application = ApplicationManager.getApplicationByName(app) else {
            print("Application '\(app)' not found")
            return
        }
        
        // Get the focused window
        guard let window = application.getFocusedWindow() else {
            print("No focused window found for \(app)")
            return
        }
        
        // Get elements in the window
        let elements = window.getElements()
        let rootElement = elements.first ?? Element(role: "window", title: window.title)
        
        // Find button by title
        let buttons = ElementFinder.findElements(in: rootElement, byRole: "button", byTitle: title)
        
        guard let button = buttons.first else {
            print("No button found with title '\(title)'")
            return
        }
        
        // Convert to ButtonElement
        guard let buttonElement = ButtonElement.fromElement(button) else {
            print("Found element is not a valid button")
            return
        }
        
        // Press the button
        if press {
            if buttonElement.press() {
                print("Successfully pressed button '\(title)'")
            } else {
                print("Failed to press button '\(title)'")
            }
        } else {
            print("Button '\(title)' found but no action specified")
            print("Use --press to press the button")
        }
    }
}

/// Command for window manipulation
struct WindowCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "window",
        abstract: "Manipulate windows"
    )
    
    @Flag(name: .long, help: "Focus the window")
    var focus = false
    
    @Flag(name: .long, help: "Raise the window to the front")
    var raise = false
    
    @Flag(name: .long, help: "Close the window")
    var close = false
    
    @Flag(name: .long, help: "Minimize the window")
    var minimize = false
    
    @Flag(name: .long, help: "Restore a minimized window")
    var restore = false
    
    @Flag(name: .long, help: "Toggle fullscreen mode")
    var fullscreen = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .long, help: "The title of the window (defaults to focused window)")
    var title: String?
    
    @Option(name: .long, help: "New position (format: 'x,y')")
    var position: String?
    
    @Option(name: .long, help: "New size (format: 'width,height')")
    var size: String?
    
    func run() throws {
        // Get the application
        guard let application = ApplicationManager.getApplicationByName(app) else {
            print("Application '\(app)' not found")
            return
        }
        
        // Get the window
        var window: Window? = nil
        
        if let windowTitle = title {
            let windows = application.getWindows()
            window = windows.first { $0.title == windowTitle }
            if window == nil {
                print("No window found with title '\(windowTitle)'")
                return
            }
        } else {
            window = application.getFocusedWindow()
            if window == nil {
                print("No focused window found for \(app)")
                return
            }
        }
        
        guard let targetWindow = window else { return }
        print("Window: \(targetWindow.title)")
        
        // Handle position change
        if let positionString = position {
            let components = positionString.split(separator: ",")
            if components.count == 2,
               let x = Double(components[0]),
               let y = Double(components[1]) {
                
                let newPosition = CGPoint(x: x, y: y)
                if targetWindow.setPosition(newPosition) {
                    print("Successfully moved window to position: \(newPosition)")
                } else {
                    print("Failed to move window")
                }
            } else {
                print("Invalid position format. Use 'x,y'")
            }
        }
        
        // Handle size change
        if let sizeString = size {
            let components = sizeString.split(separator: ",")
            if components.count == 2,
               let width = Double(components[0]),
               let height = Double(components[1]) {
                
                let newSize = CGSize(width: width, height: height)
                if targetWindow.setSize(newSize) {
                    print("Successfully resized window to: \(newSize)")
                } else {
                    print("Failed to resize window")
                }
            } else {
                print("Invalid size format. Use 'width,height'")
            }
        }
        
        // Handle other window operations
        if focus {
            if targetWindow.focus() {
                print("Successfully focused window")
            } else {
                print("Failed to focus window")
            }
        }
        
        if raise {
            if targetWindow.raise() {
                print("Successfully raised window")
            } else {
                print("Failed to raise window")
            }
        }
        
        if minimize {
            if targetWindow.minimize() {
                print("Successfully minimized window")
            } else {
                print("Failed to minimize window")
            }
        }
        
        if restore {
            if targetWindow.restore() {
                print("Successfully restored window")
            } else {
                print("Failed to restore window")
            }
        }
        
        if fullscreen {
            if targetWindow.toggleFullscreen() {
                print("Successfully toggled fullscreen mode")
            } else {
                print("Failed to toggle fullscreen mode")
            }
        }
        
        if close {
            if targetWindow.close() {
                print("Successfully closed window")
            } else {
                print("Failed to close window")
            }
        }
    }
}

/// Command for keyboard input
struct KeyboardCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "keyboard",
        abstract: "Simulate keyboard input"
    )
    
    @Option(name: .shortAndLong, help: "Text to type")
    var text: String?
    
    @Option(name: .shortAndLong, help: "Key combination to press (e.g., cmd+c, cmd+option+esc)")
    var combo: String?
    
    func run() throws {
        // Check accessibility permissions first
        guard AccessibilityPermissions.checkPermission() == .granted else {
            print("Accessibility permissions required for keyboard input")
            print("Use 'macos-ui-cli permissions --request' to request permissions")
            return
        }
        
        // Handle text typing
        if let text = text {
            if KeyboardInput.typeString(text) {
                print("Successfully typed text")
            } else {
                print("Failed to type text")
            }
            return
        }
        
        // Handle key combination
        if let combination = combo {
            // Parse the combination (e.g., "cmd+c", "cmd+option+esc")
            let parts = combination.lowercased().split(separator: "+")
            guard parts.count >= 2 else {
                print("Invalid key combination format. Use format like 'cmd+c'")
                return
            }
            
            var modifiers: [KeyboardInput.Modifier] = []
            var key: String = ""
            
            // The last part is the key, everything else is a modifier
            for i in 0..<parts.count-1 {
                let part = parts[i]
                switch part {
                case "cmd", "command":
                    modifiers.append(.command)
                case "opt", "option", "alt":
                    modifiers.append(.option)
                case "ctrl", "control":
                    modifiers.append(.control)
                case "shift":
                    modifiers.append(.shift)
                default:
                    print("Unknown modifier: \(part)")
                    return
                }
            }
            
            // The last part is the key
            key = String(parts.last!)
            
            if KeyboardInput.pressKeyCombination(modifiers, key: key) {
                print("Successfully pressed key combination")
            } else {
                print("Failed to press key combination")
            }
            return
        }
        
        print("No action specified. Use --text or --combo options")
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
            ElementsCommand.self,
            ButtonCommand.self,
            TextCommand.self,
            WindowCommand.self,
            KeyboardCommand.self
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
