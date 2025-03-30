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
          macos-ui-cli util interactive
          macos-ui-cli util explore "Safari"
          macos-ui-cli util navigate "Safari"
        """,
        subcommands: [
            PermissionsCommand.self,
            VersionCommand.self,
            InfoCommand.self,
            FormatCommand.self,
            InteractiveCommand.self,
            ExploreCommand.self,
            NavigateCommand.self
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

/// Command to enter interactive shell mode
public struct InteractiveCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "interactive",
        abstract: "Start interactive shell mode",
        discussion: """
        Start an interactive shell for exploring and manipulating UI elements.
        This mode provides command history, tab completion, and context awareness.
        
        Example:
          macos-ui-cli util interactive
        """
    )
    
    public init() {}
    
    public func run() throws {
        print("Starting interactive mode...")
        print("Type 'help' for available commands, 'exit' to quit")
        
        // Start the interactive shell
        let interactive = InteractiveMode()
        try interactive.startREPL()
    }
}

/// Command to deeply explore an application's accessibility hierarchy
public struct ExploreCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "explore",
        abstract: "Deeply explore an application's UI hierarchy",
        discussion: """
        Thoroughly explore an application's UI hierarchy and accessibility properties.
        This command will display all available UI elements, their attributes, and
        accessible actions in a detailed manner.
        
        Examples:
          macos-ui-cli util explore "Safari"    # Explore Safari's UI
          macos-ui-cli util explore "Terminal"  # Explore Terminal's UI
          macos-ui-cli util explore --all       # Show accessibility details for all apps
          macos-ui-cli util explore --focused   # Explore currently focused app
          macos-ui-cli util explore --depth 3   # Limit exploration depth to 3 levels
        """
    )
    
    @Argument(help: "Name of the application to explore")
    var appName: String?
    
    @Option(name: .long, help: "Process ID of the specific application to explore")
    var pid: Int32?
    
    @Flag(name: .long, help: "Explore all running applications")
    var all: Bool = false
    
    @Flag(name: .long, help: "Explore the currently focused application")
    var focused: Bool = false
    
    @Option(name: .long, help: "Maximum depth to explore in the hierarchy (default: unlimited)")
    var depth: Int?
    
    @Option(name: .shortAndLong, help: "Output format: text, json, or xml")
    var format: String = "text"
    
    @Option(name: .shortAndLong, help: "Verbosity level (0-3)")
    var verbosity: Int = 2
    
    @Flag(name: .shortAndLong, inversion: .prefixedNo, help: "Enable colorized output")
    var color: Bool = false
    
    @Flag(name: .long, help: "Include all attribute values (can be verbose)")
    var showAttributes: Bool = false
    
    @Flag(name: .long, help: "Show available actions for each element")
    var showActions: Bool = false
    
    @Flag(name: .long, help: "Export results to a file")
    var export: Bool = false
    
    @Option(name: .long, help: "Path to export results (default: ./app-exploration.txt)")
    var exportPath: String = "./app-exploration.txt"
    
    public init() {}
    
    public func run() throws {
        // Create formatter with specified settings
        let outputFormat = OutputFormat.fromString(format)
        let verbosityLevel = VerbosityLevel.fromInt(verbosity)
        let formatter = FormatterFactory.create(
            format: outputFormat,
            verbosity: verbosityLevel,
            colorized: color
        )
        
        // Check permissions
        if AccessibilityPermissions.checkPermission() != .granted {
            print("Accessibility permissions are required for this command.")
            print("Use 'macos-ui-cli util permissions --request' to request permissions.")
            throw AccessibilityError.permissionDenied
        }
        
        var results: [String] = []
        
        // Get the application(s) to explore
        if all {
            // Explore all applications
            let apps = try ApplicationManager.getAllApplications()
            print("Exploring \(apps.count) applications...")
            
            for app in apps {
                let appExploration = try exploreApplication(app, maxDepth: depth, formatter: formatter)
                results.append(appExploration)
                print(appExploration)
                print("\n-----------------------------------\n")
            }
        } else if focused {
            // Explore focused application
            guard let focusedApp = try ApplicationManager.getFocusedApplication() else {
                throw ApplicationManagerError.applicationNotFound(description: "No focused application")
            }
            
            print("Exploring focused application: \(focusedApp.name)...")
            let appExploration = try exploreApplication(focusedApp, maxDepth: depth, formatter: formatter)
            results.append(appExploration)
            print(appExploration)
        } else if let specificPid = pid {
            // Explore application by PID
            print("Looking up application with PID: \(specificPid)...")
            let app = try ApplicationManager.getApplicationByPID(specificPid)
            
            print("Exploring application: \(app.name) (PID: \(app.pid))...")
            let appExploration = try exploreApplication(app, maxDepth: depth, formatter: formatter)
            results.append(appExploration)
            print(appExploration)
        } else if let name = appName {
            // Explore specified application
            print("Searching for application: \(name)...")
            let app = try ApplicationManager.getApplicationByName(name)
            
            print("Exploring application: \(app.name) (PID: \(app.pid))...")
            let appExploration = try exploreApplication(app, maxDepth: depth, formatter: formatter)
            results.append(appExploration)
            print(appExploration)
        } else {
            // No application specified
            print("Please specify an application name, use --pid to specify a process ID, or use --all or --focused")
            throw ValidationError.invalidArgument(name: "appName", reason: "No application specified")
        }
        
        // Export results if requested
        if export {
            print("Exporting results to \(exportPath)...")
            let outputString = results.joined(separator: "\n\n-----------------------------------\n\n")
            do {
                try outputString.write(toFile: exportPath, atomically: true, encoding: .utf8)
                print("Results exported successfully")
            } catch {
                print("Error exporting results: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Explore a single application and return a detailed description
    private func exploreApplication(_ app: Application, maxDepth: Int?, formatter: OutputFormatter) throws -> String {
        var result = "APPLICATION: \(app.name) (PID: \(app.pid))\n"
        result += "==================================================\n\n"
        
        // Get application windows
        let windows = try app.getWindows()
        result += "Found \(windows.count) windows:\n\n"
        
        for (windowIndex, window) in windows.enumerated() {
            result += "WINDOW \(windowIndex+1): \(window.title)\n"
            result += "--------------------------------------------------\n"
            result += "  Position: (\(Int(window.frame.origin.x)), \(Int(window.frame.origin.y)))\n"
            result += "  Size: \(Int(window.frame.width))x\(Int(window.frame.height))\n"
            result += "  Fullscreen: \(window.isFullscreen ? "Yes" : "No")\n"
            result += "  Minimized: \(window.isMinimized ? "Yes" : "No")\n\n"
            
            // Get window elements
            let elements = try window.getElements()
            
            if elements.isEmpty {
                result += "  No UI elements found in this window\n"
            } else {
                result += "  UI HIERARCHY:\n"
                
                // Only explore the first element since it contains the entire window hierarchy
                if let rootElement = elements.first {
                    result += exploreElementHierarchy(rootElement, level: 1, maxDepth: maxDepth)
                }
            }
            
            result += "\n"
        }
        
        return result
    }
    
    /// Recursively explore an element's hierarchy with proper indentation
    private func exploreElementHierarchy(_ element: Element, level: Int, maxDepth: Int?) -> String {
        // Check if we've reached the maximum depth
        if let maxDepth = maxDepth, level > maxDepth {
            return ""
        }
        
        let indent = String(repeating: "  ", count: level)
        var result = ""
        
        // Element basic information with role description
        var elementDescription = "\(indent)- \(element.role)"
        
        // Include subrole if available
        if !element.subRole.isEmpty {
            elementDescription += ":\(element.subRole)"
        }
        
        // Include title and role description
        if !element.title.isEmpty {
            elementDescription += " [\(element.title)]"
            if !element.roleDescription.isEmpty && element.title != element.roleDescription {
                elementDescription += " (\(element.roleDescription))"
            }
        } else if !element.roleDescription.isEmpty {
            elementDescription += " [\(element.roleDescription)]"
        }
        
        result += elementDescription + "\n"
        
        // Include attributes if requested
        if showAttributes {
            let attributes = element.getAttributesNoThrow()
            if !attributes.isEmpty {
                result += "\(indent)  Attributes:\n"
                for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
                    result += "\(indent)    \(key): \(String(describing: value))\n"
                }
            }
        }
        
        // Include actions if requested
        if showActions {
            let actions = element.getAvailableActionsNoThrow()
            if !actions.isEmpty {
                result += "\(indent)  Actions: \(actions.joined(separator: ", "))\n"
            }
        }
        
        // Make sure children are loaded
        if element.hasChildren {
            element.loadChildrenIfNeeded()
        }
        
        // Recursively explore children
        if !element.children.isEmpty {
            for child in element.children {
                result += exploreElementHierarchy(child, level: level + 1, maxDepth: maxDepth)
            }
        } else if element.hasChildren {
            // If element reports having children but none are loaded
            result += "\(indent)  (has children, not accessible)\n"
        }
        
        return result
    }
}

/// Command to launch the curses-style UI Navigator
public struct NavigateCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "navigate",
        abstract: "Launch curses-style UI Navigator with keyboard navigation",
        discussion: """
        Launch a curses-style terminal UI for navigating and interacting with application UI elements.
        This mode provides visual representation of UI hierarchy with keyboard navigation.
        
        Examples:
          macos-ui-cli util navigate "Safari"    # Navigate Safari's UI
          macos-ui-cli util navigate --focused   # Navigate currently focused app
        """
    )
    
    @Argument(help: "Name of the application to navigate")
    var appName: String?
    
    @Flag(name: .long, help: "Navigate the currently focused application")
    var focused: Bool = false
    
    @Option(name: .long, help: "Process ID of the specific application to navigate")
    var pid: Int32?
    
    @Flag(name: .shortAndLong, inversion: .prefixedNo, help: "Enable colorized output")
    var color: Bool = true
    
    public init() {}
    
    public func run() throws {
        // Check permissions
        if AccessibilityPermissions.checkPermission() != .granted {
            print("Accessibility permissions are required for this command.")
            print("Use 'macos-ui-cli util permissions --request' to request permissions.")
            throw AccessibilityError.permissionDenied
        }
        
        let formatter = FormatterFactory.create(
            format: .plainText,
            verbosity: .normal,
            colorized: color
        )
        
        let navigator = UINavigator(formatter: formatter)
        
        if focused {
            // Navigate focused application
            guard let focusedApp = try ApplicationManager.getFocusedApplication() else {
                throw ApplicationManagerError.applicationNotFound(description: "No focused application")
            }
            
            print("Starting UI Navigator for focused application: \(focusedApp.name)...")
            try navigator.startWithApplication(focusedApp.name)
        } else if let specificPid = pid {
            // Navigate application by PID
            print("Looking up application with PID: \(specificPid)...")
            let app = try ApplicationManager.getApplicationByPID(specificPid)
            
            print("Starting UI Navigator for: \(app.name) (PID: \(app.pid))...")
            try navigator.startWithApplication(app.name)
        } else if let name = appName {
            // Navigate specified application
            print("Starting UI Navigator for: \(name)...")
            try navigator.startWithApplication(name)
        } else {
            // No application specified
            print("Please specify an application name, use --pid to specify a process ID, or use --focused")
            throw ValidationError.invalidArgument(name: "appName", reason: "No application specified")
        }
    }
}