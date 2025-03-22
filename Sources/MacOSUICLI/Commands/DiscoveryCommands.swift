// ABOUTME: This file contains commands for discovering applications, windows, and UI elements.
// ABOUTME: These commands allow users to explore the UI hierarchy without modifying anything.

import Foundation
import ArgumentParser
import Haxcessibility

/// Group for all discovery-related commands
public struct DiscoveryCommands: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "discover",
        abstract: "Commands for discovering UI elements",
        discussion: """
        The discovery commands allow you to find and inspect UI elements without modifying them.
        Use these commands to explore the UI hierarchy of applications on your system.
        
        Examples:
          macos-ui-cli discover apps --focused
          macos-ui-cli discover windows --app "Safari"
          macos-ui-cli discover elements --app "Calculator" --role "button"
        """,
        subcommands: [
            ApplicationsCommand.self,
            WindowsCommand.self,
            ElementsCommand.self
        ],
        defaultSubcommand: ApplicationsCommand.self
    )
    
    public init() {}
}

/// Command to list and find applications
public struct ApplicationsCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "apps",
        abstract: "List and find applications",
        discussion: """
        Find and list applications running on your system.
        
        Examples:
          macos-ui-cli discover apps                  # List all accessible applications
          macos-ui-cli discover apps --focused        # Show the currently focused application
          macos-ui-cli discover apps --name "Safari"  # Find application by name
          macos-ui-cli discover apps --pid 1234       # Find application by process ID
        """
    )
    
    @Flag(name: .long, help: "Show the focused application")
    var focused = false
    
    @Option(name: .shortAndLong, help: "Find application by name")
    var name: String?
    
    @Option(name: .shortAndLong, help: "Find application by PID")
    var pid: Int32?
    
    public init() {}
    
    @OptionGroup
    var globalOptions: GlobalOptions
    
    public func run() throws {
        // Get the formatter based on global options
        let formatter = globalOptions.createFormatter()
        let errorHandler = ErrorHandler.shared
        
        if focused {
            do {
                if let app = try ApplicationManager.getFocusedApplication() {
                    print(formatter.formatMessage("Focused application:", type: .info))
                    print(formatter.formatApplication(app))
                } else {
                    print(formatter.formatMessage("No focused application found", type: .warning))
                }
            } catch {
                print(errorHandler.handle(error))
            }
            return
        }
        
        if let pid = pid {
            do {
                let app = try ApplicationManager.getApplicationByPID(pid)
                print(formatter.formatMessage("Application found:", type: .success))
                print(formatter.formatApplication(app))
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with PID \(pid)", type: .error))
            }
            return
        }
        
        if let name = name {
            do {
                let app = try ApplicationManager.getApplicationByName(name)
                print(formatter.formatMessage("Application found:", type: .success))
                print(formatter.formatApplication(app))
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with name \(name)", type: .error))
            }
            return
        }
        
        // Default: list all applications
        do {
            let apps = try ApplicationManager.getAllApplications()
            if apps.isEmpty {
                print(formatter.formatMessage("No applications found", type: .warning))
            } else {
                print(formatter.formatApplications(apps))
            }
        } catch {
            print(errorHandler.handle(error))
        }
    }
}

/// Command to list and find windows
public struct WindowsCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "windows",
        abstract: "List and find windows",
        discussion: """
        Find and list windows of applications.
        
        Examples:
          macos-ui-cli discover windows              # List windows of the focused application
          macos-ui-cli discover windows --focused    # Show the focused window
          macos-ui-cli discover windows --app "Safari"  # List windows of a specific application
          macos-ui-cli discover windows --pid 1234   # List windows of an application by process ID
        """
    )
    
    @Flag(name: .long, help: "Show the focused window")
    var focused = false
    
    @Option(name: .shortAndLong, help: "Application name to list windows for")
    var app: String?
    
    @Option(name: .shortAndLong, help: "Application PID to list windows for")
    var pid: Int32?
    
    public init() {}
    
    @OptionGroup
    var globalOptions: GlobalOptions
    
    public func run() throws {
        // Get the formatter based on global options
        let formatter = globalOptions.createFormatter()
        let errorHandler = ErrorHandler.shared
        
        // Get the application first
        var application: Application? = nil
        
        if let appName = app {
            do {
                application = try ApplicationManager.getApplicationByName(appName)
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with name: \(appName)", type: .error))
                return
            }
        } else if let appPid = pid {
            do {
                application = try ApplicationManager.getApplicationByPID(appPid)
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with PID: \(appPid)", type: .error))
                return
            }
        } else if focused {
            do {
                application = try ApplicationManager.getFocusedApplication()
                if application == nil {
                    print(formatter.formatMessage("No focused application found", type: .warning))
                    return
                }
            } catch {
                print(errorHandler.handle(error))
                return
            }
        }
        
        // If no application specified, use the focused one
        if application == nil {
            do {
                application = try ApplicationManager.getFocusedApplication()
                if application == nil {
                    print(formatter.formatMessage("No focused application found", type: .warning))
                    return
                }
            } catch {
                print(errorHandler.handle(error))
                return
            }
        }
        
        // Get and display windows
        guard let app = application else { return }
        
        print(formatter.formatMessage("Windows for \(app.name):", type: .info))
        do {
            let windows = try app.getWindows()
            
            if windows.isEmpty {
                print(formatter.formatMessage("No windows found", type: .warning))
            } else {
                print(formatter.formatWindows(windows))
            }
        } catch {
            print(errorHandler.handle(error))
        }
    }
}

/// Command to find, inspect, and interact with UI elements
public struct ElementsCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "elements",
        abstract: "Find, inspect, and interact with UI elements",
        discussion: """
        Find and inspect UI elements within applications.
        
        Examples:
          macos-ui-cli discover elements --focused              # Show the focused element
          macos-ui-cli discover elements --app "Calculator" --role "button"  # Find all buttons in Calculator
          macos-ui-cli discover elements --app "Safari" --title "Google"    # Find elements with title "Google"
          macos-ui-cli discover elements --path "window[Main]/button[OK]"  # Find element by path
        """
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
    
    public init() {}
    
    @OptionGroup
    var globalOptions: GlobalOptions
    
    public func run() throws {
        // Get the formatter based on global options
        let formatter = globalOptions.createFormatter()
        let errorHandler = ErrorHandler.shared
        
        // Handle focused element request
        if focused {
            do {
                let element = try ElementFinder.getFocusedElement()
                print(formatter.formatMessage("Focused element:", type: .info))
                print(formatter.formatElement(element))
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No focused element found", type: .warning))
            }
            return
        }
        
        // Get the application first
        var application: Application? = nil
        
        if let appName = app {
            do {
                application = try ApplicationManager.getApplicationByName(appName)
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with name: \(appName)", type: .error))
                return
            }
        } else if let appPid = pid {
            do {
                application = try ApplicationManager.getApplicationByPID(appPid)
            } catch {
                print(errorHandler.handle(error))
                print(formatter.formatMessage("No application found with PID: \(appPid)", type: .error))
                return
            }
        } else {
            do {
                application = try ApplicationManager.getFocusedApplication()
                if application == nil {
                    print(formatter.formatMessage("No focused application found", type: .warning))
                    return
                }
            } catch {
                print(errorHandler.handle(error))
                return
            }
        }
        
        guard let app = application else { return }
        print(formatter.formatMessage("Searching in application: \(app.name)", type: .info))
        
        // Get the focused window by default
        do {
            guard let window = try app.getFocusedWindow() else {
                print(formatter.formatMessage("No focused window found", type: .warning))
                return
            }
            
            // Convert Window to Element for searching
            let rootElement = Element(role: "window", title: window.title)
            
            // Handle path search
            if let pathQuery = path {
                do {
                    let element = try ElementFinder.findElementByPath(pathQuery, in: rootElement)
                    print(formatter.formatMessage("Element found at path '\(pathQuery)':", type: .success))
                    print(formatter.formatElement(element))
                } catch {
                    print(errorHandler.handle(error))
                    print(formatter.formatMessage("No element found at path '\(pathQuery)'", type: .error))
                }
                return
            }
            
            // Handle role/title search
            do {
                let elements = try ElementFinder.findElements(
                    in: rootElement,
                    byRole: role,
                    byTitle: title
                )
                
                if elements.isEmpty {
                    print(formatter.formatMessage("No matching elements found", type: .warning))
                } else {
                    print(formatter.formatMessage("Found \(elements.count) matching elements:", type: .success))
                    print(formatter.formatElements(elements))
                }
            } catch {
                print(errorHandler.handle(error))
            }
        } catch {
            print(errorHandler.handle(error))
            print(formatter.formatMessage("Could not access focused window", type: .error))
        }
    }
}