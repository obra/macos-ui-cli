// ABOUTME: This file contains utility commands for system-level tasks.
// ABOUTME: These commands handle permissions, version info, and other tool configuration.

import Foundation
import ArgumentParser
import Haxcessibility

/// Group for all utility commands
public struct UtilityCommands: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "util",
        abstract: "Utility commands for the tool",
        discussion: """
        The utility commands help with tool configuration, permissions management,
        and other system-level tasks.
        
        Examples:
          macos-ui-cli util permissions --request
          macos-ui-cli util version
          macos-ui-cli util info
          macos-ui-cli util format --help
        """,
        subcommands: [
            PermissionsCommand.self,
            VersionCommand.self,
            InfoCommand.self,
            FormatCommand.self
        ],
        defaultSubcommand: nil
    )
    
    public init() {}
}

/// Command to check and request accessibility permissions
public struct PermissionsCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "permissions",
        abstract: "Check and request accessibility permissions",
        discussion: """
        Check, request, or manage accessibility permissions.
        
        Examples:
          macos-ui-cli util permissions           # Check permission status
          macos-ui-cli util permissions --request # Request permissions
          macos-ui-cli util permissions --open    # Open System Preferences
          macos-ui-cli util permissions --create-wrapper # Create app wrapper
        """
    )
    
    @Flag(name: .long, help: "Prompt the user to enable accessibility permissions")
    var request = false
    
    @Flag(name: .long, help: "Open the System Preferences to the Accessibility section")
    var open = false
    
    @Flag(name: .long, help: "Create an app wrapper to simplify accessibility permissions")
    var createWrapper = false
    
    public init() {}
    
    public func run() throws {
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

/// Command for displaying version information
public struct VersionCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show detailed version information",
        discussion: """
        Display version information about the tool and its dependencies.
        
        Examples:
          macos-ui-cli util version
        """
    )
    
    public init() {}
    
    public func run() throws {
        let version = "0.2.0"
        let buildDate = "2025-03-22"
        let swiftVersion = "5.5+"
        let osRequirement = "macOS 11.0+"
        
        print("MacOSUICLI - Command-line tool for macOS UI automation")
        print("Version: \(version) (Built on \(buildDate))")
        print("Swift: \(swiftVersion)")
        print("OS Requirement: \(osRequirement)")
        print("Haxcessibility: \(SystemAccessibility.isAvailable() ? "Available" : "Not available")")
        print("Accessibility Permissions: \(AccessibilityPermissions.checkPermission() == .granted ? "Granted" : "Not granted")")
        
        if AccessibilityPermissions.checkPermission() != .granted {
            print("\nAccessibility permissions are required for this tool to function correctly.")
            print("Use 'macos-ui-cli util permissions --request' to request permissions.")
        }
    }
}

/// Command for displaying system information
public struct InfoCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Display system information",
        discussion: """
        Show information about the system and current accessibility status.
        
        Examples:
          macos-ui-cli util info
        """
    )
    
    public init() {}
    
    public func run() throws {
        print("System Information:")
        print("------------------")
        
        let processInfo = ProcessInfo.processInfo
        print("Host name: \(processInfo.hostName)")
        print("OS Version: \(processInfo.operatingSystemVersionString)")
        print("Process ID: \(processInfo.processIdentifier)")
        
        print("\nAccessibility Status:")
        print("--------------------")
        let permissionStatus = AccessibilityPermissions.checkPermission()
        print("Accessibility Permissions: \(permissionStatus == .granted ? "Granted" : "Not granted")")
        
        print("\nRunning Applications:")
        print("--------------------")
        do {
            let apps = try ApplicationManager.getAllApplications()
            if apps.isEmpty {
                print("No applications found")
            } else {
                for app in apps.prefix(5) {
                    print("- \(app.name) (PID: \(app.pid))")
                }
                if apps.count > 5 {
                    print("... and \(apps.count - 5) more")
                }
            }
        } catch {
            print("Error getting applications: \(error.localizedDescription)")
        }
        
        print("\nFocused Application:")
        print("------------------")
        do {
            if let focusedApp = try ApplicationManager.getFocusedApplication() {
                print("- \(focusedApp.name) (PID: \(focusedApp.pid))")
                
                do {
                    if let focusedWindow = try focusedApp.getFocusedWindow() {
                        print("  Focused Window: \(focusedWindow.title)")
                    } else {
                        print("  No focused window")
                    }
                } catch {
                    print("  Error getting focused window: \(error.localizedDescription)")
                }
            } else {
                print("No focused application")
            }
        } catch {
            print("Error getting focused application: \(error.localizedDescription)")
        }
    }
}

/// Command for output formatting options
public struct FormatCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "format",
        abstract: "Configure output formatting",
        discussion: """
        Configure and test different output formatting options. These settings
        can be used with any command to control how the output is presented.
        
        Examples:
          macos-ui-cli util format --format json          # Set output format to JSON
          macos-ui-cli util format --format xml           # Set output format to XML
          macos-ui-cli util format --verbose              # Increase verbosity
          macos-ui-cli util format --color                # Enable colored output
          macos-ui-cli util format --sample apps          # Show sample apps output
          macos-ui-cli util format --sample hierarchy     # Show sample hierarchy
        """
    )
    
    @Option(name: .shortAndLong, help: "Output format: text, json, or xml")
    var format: String = "text"
    
    @Option(name: .shortAndLong, help: "Verbosity level (0-3)")
    var verbosity: Int = 1
    
    @Flag(name: .shortAndLong, help: "Enable colorized output")
    var color: Bool = false
    
    @Option(name: .long, help: "Show sample output (apps, windows, elements, hierarchy)")
    var sample: String?
    
    public init() {}
    
    public func run() throws {
        // Convert format string to OutputFormat
        let outputFormat = OutputFormat.fromString(format)
        let verbosityLevel = VerbosityLevel.fromInt(verbosity)
        
        // Create the formatter
        let formatter = FormatterFactory.create(
            format: outputFormat,
            verbosity: verbosityLevel,
            colorized: color
        )
        
        // Output current format settings
        print("Current Format Settings:")
        print("- Format: \(outputFormat.rawValue)")
        print("- Verbosity: \(verbosityLevel.rawValue) (\(verbosityLevel))")
        print("- Color: \(color ? "Enabled" : "Disabled")")
        
        // Generate sample output if requested
        if let sampleType = sample {
            print("\nSample Output:")
            
            switch sampleType.lowercased() {
            case "app", "apps", "applications":
                // Sample applications
                let apps = [
                    Application(mockWithName: "Safari", pid: 1234),
                    Application(mockWithName: "Notes", pid: 5678),
                    Application(mockWithName: "Calculator", pid: 9012)
                ]
                print(formatter.formatApplications(apps))
                
            case "window", "windows":
                // Sample windows
                let windows = [
                    Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600)),
                    Window(title: "Settings", frame: CGRect(x: 100, y: 100, width: 400, height: 300)),
                    Window(title: "About", frame: CGRect(x: 200, y: 200, width: 300, height: 200))
                ]
                print(formatter.formatWindows(windows))
                
            case "element", "elements":
                // Sample elements
                let elements = [
                    Element(role: "button", title: "OK"),
                    Element(role: "button", title: "Cancel"),
                    Element(role: "textField", title: "Search"),
                    Element(role: "checkbox", title: "Enable Feature")
                ]
                print(formatter.formatElements(elements))
                
            case "hierarchy":
                // Sample element hierarchy
                let root = Element(role: "window", title: "Main Window")
                let toolbar = Element(role: "toolbar", title: "Toolbar")
                let content = Element(role: "group", title: "Content")
                let button1 = Element(role: "button", title: "OK")
                let button2 = Element(role: "button", title: "Cancel")
                let field = Element(role: "textField", title: "Search")
                
                toolbar.addChild(button1)
                toolbar.addChild(button2)
                toolbar.addChild(field)
                
                root.addChild(toolbar)
                root.addChild(content)
                
                print(formatter.formatElementHierarchy(root))
                
            case "all":
                // Show all samples
                print("\n=== APPLICATIONS ===")
                let apps = [
                    Application(mockWithName: "Safari", pid: 1234),
                    Application(mockWithName: "Notes", pid: 5678)
                ]
                print(formatter.formatApplications(apps))
                
                print("\n=== WINDOWS ===")
                let windows = [
                    Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600)),
                    Window(title: "Settings", frame: CGRect(x: 100, y: 100, width: 400, height: 300))
                ]
                print(formatter.formatWindows(windows))
                
                print("\n=== ELEMENTS ===")
                let elements = [
                    Element(role: "button", title: "OK"),
                    Element(role: "textField", title: "Search")
                ]
                print(formatter.formatElements(elements))
                
                print("\n=== HIERARCHY ===")
                let root = Element(role: "window", title: "Main Window")
                let button = Element(role: "button", title: "OK")
                root.addChild(button)
                print(formatter.formatElementHierarchy(root))
                
            default:
                print("Unknown sample type: \(sampleType)")
                print("Available sample types: apps, windows, elements, hierarchy, all")
            }
        }
        
        // Show usage hint
        print("\nTo use this format with other commands, use the global format options:")
        print("  --format <format>     Set output format (text, json, xml)")
        print("  --verbosity <level>   Set verbosity level (0-3)")
        print("  --color               Enable colorized output")
    }
}