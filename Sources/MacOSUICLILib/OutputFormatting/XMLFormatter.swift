// ABOUTME: This file implements the XMLFormatter for structured XML output.
// ABOUTME: It provides machine-readable XML output with different verbosity levels.

import Foundation
import CoreGraphics

/// Formatter for XML output
public class XMLFormatter: OutputFormatter {
    /// The verbosity level
    let verbosity: VerbosityLevel
    
    /// Initialize a new XMLFormatter
    /// - Parameter verbosity: The verbosity level
    public init(verbosity: VerbosityLevel = .normal) {
        self.verbosity = verbosity
    }
    
    // MARK: - Applications
    
    public func formatApplication(_ app: Application) -> String {
        var xml = "<application>\n"
        xml += "  <n>\(escapeXML(app.name))</n>\n"
        xml += "  <pid>\(app.pid)</pid>\n"
        
        if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
            let windows = app.getWindowsNoThrow()
            xml += "  <windowCount>\(windows.count)</windowCount>\n"
            
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue && !windows.isEmpty {
                xml += "  <windows>\n"
                for window in windows {
                    xml += "    <window>\n"
                    xml += "      <title>\(escapeXML(window.title))</title>\n"
                    xml += "    </window>\n"
                }
                xml += "  </windows>\n"
            }
        }
        
        xml += "</application>"
        return xml
    }
    
    public func formatApplications(_ apps: [Application]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<applications count=\"\(apps.count)\">\n"
        
        for app in apps {
            xml += "  <application>\n"
            xml += "    <n>\(escapeXML(app.name))</n>\n"
            xml += "    <pid>\(app.pid)</pid>\n"
            
            if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
                let windows = app.getWindowsNoThrow()
                xml += "    <windowCount>\(windows.count)</windowCount>\n"
            }
            
            xml += "  </application>\n"
        }
        
        xml += "</applications>"
        return xml
    }
    
    // MARK: - Windows
    
    public func formatWindow(_ window: Window) -> String {
        let frame = window.frame
        
        var xml = "<window>\n"
        xml += "  <title>\(escapeXML(window.title))</title>\n"
        
        if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
            xml += "  <size>\n"
            xml += "    <width>\(Int(frame.width))</width>\n"
            xml += "    <height>\(Int(frame.height))</height>\n"
            xml += "  </size>\n"
        }
        
        if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
            xml += "  <position>\n"
            xml += "    <x>\(Int(frame.origin.x))</x>\n"
            xml += "    <y>\(Int(frame.origin.y))</y>\n"
            xml += "  </position>\n"
        }
        
        xml += "</window>"
        return xml
    }
    
    public func formatWindows(_ windows: [Window]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<windows count=\"\(windows.count)\">\n"
        
        for window in windows {
            xml += "  <window>\n"
            xml += "    <title>\(escapeXML(window.title))</title>\n"
            
            let frame = window.frame
            if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
                xml += "    <size>\n"
                xml += "      <width>\(Int(frame.width))</width>\n"
                xml += "      <height>\(Int(frame.height))</height>\n"
                xml += "    </size>\n"
            }
            
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
                xml += "    <position>\n"
                xml += "      <x>\(Int(frame.origin.x))</x>\n"
                xml += "      <y>\(Int(frame.origin.y))</y>\n"
                xml += "    </position>\n"
            }
            
            xml += "  </window>\n"
        }
        
        xml += "</windows>"
        return xml
    }
    
    // MARK: - UI Elements
    
    public func formatElement(_ element: Element) -> String {
        var xml = "<element>\n"
        xml += "  <role>\(escapeXML(element.role))</role>\n"
        xml += "  <title>\(escapeXML(element.title))</title>\n"
        
        if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
            xml += "  <hasChildren>\(element.hasChildren)</hasChildren>\n"
            
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
                xml += "  <attributes>\n"
                for (key, value) in element.getAttributesNoThrow() {
                    xml += "    <attribute>\n"
                    xml += "      <n>\(escapeXML(key))</n>\n"
                    xml += "      <value>\(escapeXML(String(describing: value)))</value>\n"
                    xml += "    </attribute>\n"
                }
                xml += "  </attributes>\n"
            }
            
            if verbosity.rawValue >= VerbosityLevel.debug.rawValue {
                xml += "  <pid>\(element.pid)</pid>\n"
                xml += "  <isFocused>\(element.isFocused)</isFocused>\n"
                
                xml += "  <actions>\n"
                for action in element.getAvailableActionsNoThrow() {
                    xml += "    <action>\(escapeXML(action))</action>\n"
                }
                xml += "  </actions>\n"
                
                if element.hasChildren && !element.children.isEmpty {
                    xml += "  <children>\n"
                    for child in element.children {
                        xml += formatElementXML(child, indent: 4)
                    }
                    xml += "  </children>\n"
                }
            }
        }
        
        xml += "</element>"
        return xml
    }
    
    public func formatElements(_ elements: [Element]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<elements count=\"\(elements.count)\">\n"
        
        for element in elements {
            xml += formatElementXML(element, indent: 2)
        }
        
        xml += "</elements>"
        return xml
    }
    
    // MARK: - Hierarchy
    
    public func formatElementHierarchy(_ rootElement: Element) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<elementHierarchy>\n"
        xml += formatHierarchyElementXML(rootElement, indent: 2)
        xml += "</elementHierarchy>"
        return xml
    }
    
    private func formatHierarchyElementXML(_ element: Element, indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent)
        
        var xml = "\(indentStr)<element>\n"
        xml += "\(indentStr)  <role>\(escapeXML(element.role))</role>\n"
        xml += "\(indentStr)  <title>\(escapeXML(element.title))</title>\n"
        
        // Add verbose information if requested
        if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
            xml += "\(indentStr)  <attributes>\n"
            for (key, value) in element.getAttributesNoThrow() {
                xml += "\(indentStr)    <attribute>\n"
                xml += "\(indentStr)      <n>\(escapeXML(key))</n>\n"
                xml += "\(indentStr)      <value>\(escapeXML(String(describing: value)))</value>\n"
                xml += "\(indentStr)    </attribute>\n"
            }
            xml += "\(indentStr)  </attributes>\n"
        }
        
        // Always include children for hierarchy
        if element.hasChildren && !element.children.isEmpty {
            xml += "\(indentStr)  <children>\n"
            for child in element.children {
                xml += formatHierarchyElementXML(child, indent: indent + 4)
            }
            xml += "\(indentStr)  </children>\n"
        }
        
        xml += "\(indentStr)</element>\n"
        return xml
    }
    
    private func formatElementXML(_ element: Element, indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent)
        
        var xml = "\(indentStr)<element>\n"
        xml += "\(indentStr)  <role>\(escapeXML(element.role))</role>\n"
        xml += "\(indentStr)  <title>\(escapeXML(element.title))</title>\n"
        
        if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
            xml += "\(indentStr)  <hasChildren>\(element.hasChildren)</hasChildren>\n"
        }
        
        if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
            xml += "\(indentStr)  <attributes>\n"
            for (key, value) in element.getAttributesNoThrow() {
                xml += "\(indentStr)    <attribute>\n"
                xml += "\(indentStr)      <n>\(escapeXML(key))</n>\n"
                xml += "\(indentStr)      <value>\(escapeXML(String(describing: value)))</value>\n"
                xml += "\(indentStr)    </attribute>\n"
            }
            xml += "\(indentStr)  </attributes>\n"
        }
        
        xml += "\(indentStr)</element>\n"
        return xml
    }
    
    // MARK: - Messages
    
    public func formatMessage(_ message: String, type: MessageType) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<message type=\"\(messageTypeString(type))\">\n"
        xml += "  <content>\(escapeXML(message))</content>\n"
        xml += "</message>"
        return xml
    }
    
    public func formatCommandResponse(_ response: String, success: Bool) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<response success=\"\(success)\">\n"
        xml += "  <content>\(escapeXML(response))</content>\n"
        xml += "</response>"
        return xml
    }
    
    public func formatError(_ error: Error) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<error>\n"
        xml += "  <message>\(escapeXML(error.localizedDescription))</message>\n"
        xml += "  <type>\(type(of: error))</type>\n"
        
        // Add additional information for ApplicationError types
        if let appError = error as? ApplicationError {
            xml += "  <code>\(appError.errorCode)</code>\n"
            
            // Add recovery suggestion based on verbosity
            if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
                xml += "  <recoverySuggestion>\(escapeXML(appError.recoverySuggestion))</recoverySuggestion>\n"
            }
            
            // Add debug info based on verbosity
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue, 
               let debugInfo = appError.debugInfo {
                xml += "  <debugInfo>\(escapeXML(debugInfo))</debugInfo>\n"
            }
        }
        
        xml += "</error>"
        return xml
    }
    
    // MARK: - Helpers
    
    /// Convert a MessageType to a string
    /// - Parameter type: The message type
    /// - Returns: A string representation of the message type
    private func messageTypeString(_ type: MessageType) -> String {
        switch type {
        case .info: return "info"
        case .success: return "success"
        case .warning: return "warning"
        case .error: return "error"
        }
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