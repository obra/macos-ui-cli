// ABOUTME: This file implements the PlainTextFormatter for human-readable text output.
// ABOUTME: It provides formatting with optional colorization and different verbosity levels.

import Foundation
import CoreGraphics

/// Terminal ANSI color codes
public struct ANSIColor {
    static let reset = "\u{001B}[0m"
    static let black = "\u{001B}[30m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
    static let white = "\u{001B}[37m"
    static let bold = "\u{001B}[1m"
}

/// Formatter for plain text output
public class PlainTextFormatter: OutputFormatter {
    /// The verbosity level
    let verbosity: VerbosityLevel
    
    /// Whether to use color in output
    let colorized: Bool
    
    /// Initialize a new PlainTextFormatter
    /// - Parameters:
    ///   - verbosity: The verbosity level
    ///   - colorized: Whether to use color in output
    public init(verbosity: VerbosityLevel = .normal, colorized: Bool = false) {
        self.verbosity = verbosity
        self.colorized = colorized
    }
    
    // MARK: - Applications
    
    public func formatApplication(_ app: Application) -> String {
        let name = colorize(app.name, with: ANSIColor.bold)
        
        switch verbosity {
        case .minimal:
            return name
        case .normal:
            return "\(name) (PID: \(app.pid))"
        case .detailed, .debug:
            return "\(name)\n  PID: \(app.pid)\n  Windows: \(app.getWindowsNoThrow().count)"
        }
    }
    
    public func formatApplications(_ apps: [Application]) -> String {
        if apps.isEmpty {
            return "No applications found"
        }
        
        let title = colorize("Applications:", with: ANSIColor.bold)
        let appStrings = apps.enumerated().map { index, app in
            return "\(index + 1). \(formatApplication(app))"
        }
        
        return "\(title)\n\(appStrings.joined(separator: "\n"))"
    }
    
    // MARK: - Windows
    
    public func formatWindow(_ window: Window) -> String {
        let title = colorize(window.title, with: ANSIColor.bold)
        let frame = window.frame
        
        switch verbosity {
        case .minimal:
            return title
        case .normal:
            return "\(title) - \(Int(frame.width))x\(Int(frame.height))"
        case .detailed, .debug:
            return """
            \(title)
              Position: (\(Int(frame.origin.x)), \(Int(frame.origin.y)))
              Size: \(Int(frame.width))x\(Int(frame.height))
            """
        }
    }
    
    public func formatWindows(_ windows: [Window]) -> String {
        if windows.isEmpty {
            return "No windows found"
        }
        
        let title = colorize("Windows:", with: ANSIColor.bold)
        let windowStrings = windows.enumerated().map { index, window in
            return "\(index + 1). \(formatWindow(window))"
        }
        
        return "\(title)\n\(windowStrings.joined(separator: "\n"))"
    }
    
    // MARK: - UI Elements
    
    public func formatElement(_ element: Element) -> String {
        let role = colorize(element.role, with: ANSIColor.green)
        let title = colorize(element.title, with: ANSIColor.bold)
        
        switch verbosity {
        case .minimal:
            return "\(role): \(title)"
        case .normal:
            var output = "\(role): \(title)"
            if element.hasChildren {
                output += " (has children)"
            }
            return output
        case .detailed:
            var output = "\(role): \(title)\n"
            
            let attributes = element.getAttributesNoThrow()
            if !attributes.isEmpty {
                output += "  Attributes:\n"
                for (key, value) in attributes {
                    output += "    \(key): \(value)\n"
                }
            }
            
            return output
        case .debug:
            var output = "\(role): \(title)\n"
            
            output += "  PID: \(element.pid)\n"
            output += "  Focused: \(element.isFocused)\n"
            
            let attributes = element.getAttributesNoThrow()
            if !attributes.isEmpty {
                output += "  Attributes:\n"
                for (key, value) in attributes {
                    output += "    \(key): \(value)\n"
                }
            }
            
            let actions = element.getAvailableActionsNoThrow()
            if !actions.isEmpty {
                output += "  Actions:\n"
                for action in actions {
                    output += "    \(action)\n"
                }
            }
            
            return output
        }
    }
    
    public func formatElements(_ elements: [Element]) -> String {
        if elements.isEmpty {
            return "No elements found"
        }
        
        let title = colorize("Elements:", with: ANSIColor.bold)
        let elementStrings = elements.enumerated().map { index, element in
            return "\(index + 1). \(formatElement(element))"
        }
        
        return "\(title)\n\(elementStrings.joined(separator: "\n"))"
    }
    
    // MARK: - Hierarchy Visualization
    
    public func formatElementHierarchy(_ rootElement: Element) -> String {
        let title = colorize("Element Hierarchy:", with: ANSIColor.bold)
        let hierarchyText = formatElementInHierarchy(rootElement, level: 0)
        return "\(title)\n\(hierarchyText)"
    }
    
    private func formatElementInHierarchy(_ element: Element, level: Int) -> String {
        let indent = String(repeating: "  ", count: level)
        let role = colorize(element.role, with: ANSIColor.green)
        let title = colorize(element.title, with: ANSIColor.bold)
        
        var output = "\(indent)\(role): \(title)"
        
        // For verbosity levels above minimal, show attributes
        if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
            let attributes = element.getAttributesNoThrow()
            if !attributes.isEmpty {
                output += "\n"
                for (key, value) in attributes {
                    output += "\(indent)  \(key): \(value)\n"
                }
            }
        }
        
        // Add children if any
        if element.hasChildren && !element.children.isEmpty {
            for child in element.children {
                output += "\n\(formatElementInHierarchy(child, level: level + 1))"
            }
        }
        
        return output
    }
    
    // MARK: - Messages
    
    public func formatMessage(_ message: String, type: MessageType) -> String {
        switch type {
        case .info:
            return colorize(message, with: ANSIColor.blue)
        case .success:
            return colorize(message, with: ANSIColor.green)
        case .warning:
            return colorize(message, with: ANSIColor.yellow)
        case .error:
            return colorize(message, with: ANSIColor.red)
        }
    }
    
    public func formatCommandResponse(_ response: String, success: Bool) -> String {
        if success {
            return formatMessage(response, type: .success)
        } else {
            return formatMessage(response, type: .error)
        }
    }
    
    public func formatError(_ error: Error) -> String {
        var errorMessage = "Error: \(error.localizedDescription)"
        
        // Add additional information for ApplicationError types
        if let appError = error as? ApplicationError {
            errorMessage += "\nError Code: \(appError.errorCode)"
            
            // Only show recovery suggestion in normal+ verbosity
            if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
                errorMessage += "\nRecovery Suggestion: \(appError.recoverySuggestion)"
            }
            
            // Only show debug info in detailed+ verbosity
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue, 
               let debugInfo = appError.debugInfo {
                errorMessage += "\nDebug Info: \(debugInfo)"
            }
        }
        
        return formatMessage(errorMessage, type: .error)
    }
    
    // MARK: - Helpers
    
    /// Apply color to a string if colorization is enabled
    /// - Parameters:
    ///   - string: The string to colorize
    ///   - color: The ANSI color code to apply
    /// - Returns: The colorized string or the original string if colorization is disabled
    private func colorize(_ string: String, with color: String) -> String {
        if colorized {
            return "\(color)\(string)\(ANSIColor.reset)"
        }
        return string
    }
}