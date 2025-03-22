// ABOUTME: This file defines the OutputFormatter protocol and related types for output formatting.
// ABOUTME: It provides an interface for formatting various UI element data in different formats.

import Foundation
import CoreGraphics

/// Represents the format options for output
public enum OutputFormat: String, Codable, CaseIterable {
    case plainText = "text"
    case json = "json"
    case xml = "xml"
    
    public static func fromString(_ string: String) -> OutputFormat {
        return OutputFormat.allCases.first { $0.rawValue == string.lowercased() } ?? .plainText
    }
}

/// Represents message types for formatting
public enum MessageType {
    case info
    case success
    case warning
    case error
}

/// Represents verbosity levels for output
public enum VerbosityLevel: Int, Codable, CaseIterable {
    case minimal = 0    // Basic info only
    case normal = 1     // Standard level of detail
    case detailed = 2   // Additional details
    case debug = 3      // All available information
    
    public static func fromInt(_ level: Int) -> VerbosityLevel {
        return VerbosityLevel.allCases.first { $0.rawValue == level } ?? .normal
    }
}

/// Protocol for output formatters
public protocol OutputFormatter {
    /// Format a single application
    func formatApplication(_ app: Application) -> String
    
    /// Format a collection of applications
    func formatApplications(_ apps: [Application]) -> String
    
    /// Format a single window
    func formatWindow(_ window: Window) -> String
    
    /// Format a collection of windows
    func formatWindows(_ windows: [Window]) -> String
    
    /// Format a single element
    func formatElement(_ element: Element) -> String
    
    /// Format a collection of elements
    func formatElements(_ elements: [Element]) -> String
    
    /// Format element hierarchy starting from a root element
    func formatElementHierarchy(_ rootElement: Element) -> String
    
    /// Format a message with a specific type
    func formatMessage(_ message: String, type: MessageType) -> String
    
    /// Format a command response
    func formatCommandResponse(_ response: String, success: Bool) -> String
    
    /// Format an error
    func formatError(_ error: Error) -> String
}

/// Factory for creating formatters
public class FormatterFactory {
    /// Create an output formatter with specified format and options
    /// - Parameters:
    ///   - format: The output format to use
    ///   - verbosity: The verbosity level
    ///   - colorized: Whether to use color in output
    /// - Returns: An OutputFormatter instance
    public static func create(
        format: OutputFormat = .plainText,
        verbosity: VerbosityLevel = .normal,
        colorized: Bool = false
    ) -> OutputFormatter {
        switch format {
        case .json:
            return JSONFormatter(verbosity: verbosity)
        case .xml:
            return XMLFormatter(verbosity: verbosity)
        case .plainText:
            return PlainTextFormatter(verbosity: verbosity, colorized: colorized)
        }
    }
}