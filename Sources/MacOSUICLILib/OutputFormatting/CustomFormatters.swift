// ABOUTME: This file provides specialized formatters for custom error formatting.
// ABOUTME: It allows proper formatting of errors without modifying the original formatters.

import Foundation

/// A formatter that wraps another formatter and provides proper error formatting
public class ErrorFormattingDecorator: OutputFormatter {
    /// The wrapped formatter
    private let wrappedFormatter: OutputFormatter
    
    /// Initialize with a formatter to wrap
    /// - Parameter formatter: The formatter to wrap
    public init(wrappedFormatter: OutputFormatter) {
        self.wrappedFormatter = wrappedFormatter
    }
    
    // MARK: - Pass-through methods
    
    public func formatApplication(_ app: Application) -> String {
        return wrappedFormatter.formatApplication(app)
    }
    
    public func formatApplications(_ apps: [Application]) -> String {
        return wrappedFormatter.formatApplications(apps)
    }
    
    public func formatWindow(_ window: Window) -> String {
        return wrappedFormatter.formatWindow(window)
    }
    
    public func formatWindows(_ windows: [Window]) -> String {
        return wrappedFormatter.formatWindows(windows)
    }
    
    public func formatElement(_ element: Element) -> String {
        return wrappedFormatter.formatElement(element)
    }
    
    public func formatElements(_ elements: [Element]) -> String {
        return wrappedFormatter.formatElements(elements)
    }
    
    public func formatElementHierarchy(_ rootElement: Element) -> String {
        return wrappedFormatter.formatElementHierarchy(rootElement)
    }
    
    public func formatMessage(_ message: String, type: MessageType) -> String {
        return wrappedFormatter.formatMessage(message, type: type)
    }
    
    public func formatCommandResponse(_ response: String, success: Bool) -> String {
        return wrappedFormatter.formatCommandResponse(response, success: success)
    }
    
    // MARK: - Override formatError
    
    public func formatError(_ error: Error) -> String {
        // Special handling for XML formatter to fix the error tags
        if let xmlFormatter = wrappedFormatter as? XMLFormatter {
            return formatXMLError(error, formatter: xmlFormatter)
        }
        
        // For other formatters, use the default implementation
        return wrappedFormatter.formatError(error)
    }
    
    // MARK: - Helpers
    
    /// Format an error as XML properly
    /// - Parameters:
    ///   - error: The error to format
    ///   - formatter: The XML formatter to use
    /// - Returns: A properly formatted XML string
    private func formatXMLError(_ error: Error, formatter: XMLFormatter) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<error>\n"
        xml += "  <message>\(escapeXML(error.localizedDescription))</message>\n"
        xml += "  <type>\(String(describing: type(of: error)))</type>\n"
        
        // Add additional information for ApplicationError types
        if let appError = error as? ApplicationError {
            xml += "  <code>\(appError.errorCode)</code>\n"
            
            // Add recovery suggestion based on verbosity
            xml += "  <recoverySuggestion>\(escapeXML(appError.recoverySuggestion))</recoverySuggestion>\n"
            
            // Add debug info if available
            if let debugInfo = appError.debugInfo {
                xml += "  <debugInfo>\(escapeXML(debugInfo))</debugInfo>\n"
            }
        }
        
        xml += "</error>"
        return xml
    }
    
    /// Escape special XML characters in a string
    /// - Parameter text: The text to escape
    /// - Returns: The escaped text
    private func escapeXML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

/// Extension to FormatterFactory to create a properly error-formatting wrapper
extension FormatterFactory {
    /// Create a formatter with proper error handling
    /// - Parameters:
    ///   - format: The output format to use
    ///   - verbosity: The verbosity level
    ///   - colorized: Whether to use color in output
    /// - Returns: An OutputFormatter instance with proper error handling
    public static func createWithErrorHandling(
        format: OutputFormat = .plainText,
        verbosity: VerbosityLevel = .normal,
        colorized: Bool = false
    ) -> OutputFormatter {
        let baseFormatter = create(format: format, verbosity: verbosity, colorized: colorized)
        return ErrorFormattingDecorator(wrappedFormatter: baseFormatter)
    }
}