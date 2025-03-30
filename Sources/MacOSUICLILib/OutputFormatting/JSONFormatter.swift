// ABOUTME: This file implements the JSONFormatter for structured JSON output.
// ABOUTME: It provides machine-readable JSON output with different verbosity levels.

import Foundation
import CoreGraphics

/// Formatter for JSON output
public class JSONFormatter: OutputFormatter {
    /// The verbosity level
    let verbosity: VerbosityLevel
    
    /// The JSON encoder
    let encoder: JSONEncoder
    
    /// Initialize a new JSONFormatter
    /// - Parameter verbosity: The verbosity level
    public init(verbosity: VerbosityLevel = .normal) {
        self.verbosity = verbosity
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    // MARK: - Applications
    
    public func formatApplication(_ app: Application) -> String {
        let appData = formatApplicationData(app)
        return encodeToJSONString(appData)
    }
    
    public func formatApplications(_ apps: [Application]) -> String {
        let appsData = apps.map { formatApplicationData($0) }
        let wrapper: [String: Any] = [
            "applications": appsData,
            "count": apps.count
        ]
        return encodeToJSONString(wrapper)
    }
    
    private func formatApplicationData(_ app: Application) -> [String: Any] {
        switch verbosity {
        case .minimal:
            return [
                "name": app.name,
                "pid": app.pid
            ]
        case .normal:
            return [
                "name": app.name,
                "pid": app.pid,
                "windowCount": app.getWindowsNoThrow().count
            ]
        case .detailed, .debug:
            return [
                "name": app.name,
                "pid": app.pid,
                "windows": app.getWindowsNoThrow().map { formatWindowData($0) }
            ]
        }
    }
    
    // MARK: - Windows
    
    public func formatWindow(_ window: Window) -> String {
        let windowData = formatWindowData(window)
        return encodeToJSONString(windowData)
    }
    
    public func formatWindows(_ windows: [Window]) -> String {
        let windowsData = windows.map { formatWindowData($0) }
        let wrapper: [String: Any] = [
            "windows": windowsData,
            "count": windows.count
        ]
        return encodeToJSONString(wrapper)
    }
    
    private func formatWindowData(_ window: Window) -> [String: Any] {
        let frame = window.frame
        
        switch verbosity {
        case .minimal:
            return [
                "title": window.title
            ]
        case .normal:
            return [
                "title": window.title,
                "width": frame.width,
                "height": frame.height
            ]
        case .detailed, .debug:
            return [
                "title": window.title,
                "position": [
                    "x": frame.origin.x,
                    "y": frame.origin.y
                ],
                "size": [
                    "width": frame.width,
                    "height": frame.height
                ]
            ]
        }
    }
    
    // MARK: - UI Elements
    
    public func formatElement(_ element: Element) -> String {
        let elementData = formatElementData(element)
        return encodeToJSONString(elementData)
    }
    
    public func formatElements(_ elements: [Element]) -> String {
        let elementsData = elements.map { formatElementData($0) }
        let wrapper: [String: Any] = [
            "elements": elementsData,
            "count": elements.count
        ]
        return encodeToJSONString(wrapper)
    }
    
    private func formatElementData(_ element: Element) -> [String: Any] {
        switch verbosity {
        case .minimal:
            return [
                "role": element.role,
                "title": element.title
            ]
        case .normal:
            return [
                "role": element.role,
                "title": element.title,
                "hasChildren": element.hasChildren
            ]
        case .detailed:
            var data: [String: Any] = [
                "role": element.role,
                "title": element.title,
                "hasChildren": element.hasChildren,
                "attributes": element.getAttributesNoThrow()
            ]
            
            if element.hasChildren && !element.children.isEmpty {
                data["childCount"] = element.children.count
            }
            
            return data
        case .debug:
            var data: [String: Any] = [
                "role": element.role,
                "title": element.title,
                "pid": element.pid,
                "isFocused": element.isFocused,
                "hasChildren": element.hasChildren,
                "attributes": element.getAttributesNoThrow(),
                "actions": element.getAvailableActionsNoThrow()
            ]
            
            if element.hasChildren && !element.children.isEmpty {
                data["children"] = element.children.map { formatElementData($0) }
            }
            
            return data
        }
    }
    
    // MARK: - Hierarchy
    
    public func formatElementHierarchy(_ rootElement: Element) -> String {
        let hierarchyData = formatHierarchyElementData(rootElement)
        return encodeToJSONString(hierarchyData)
    }
    
    private func formatHierarchyElementData(_ element: Element) -> [String: Any] {
        var data: [String: Any] = [
            "role": element.role,
            "title": element.title
        ]
        
        // Add verbose information if requested
        if verbosity.rawValue >= VerbosityLevel.detailed.rawValue {
            data["attributes"] = element.getAttributesNoThrow()
        }
        
        // Always include children for hierarchy
        if element.hasChildren && !element.children.isEmpty {
            data["children"] = element.children.map { formatHierarchyElementData($0) }
        }
        
        return data
    }
    
    // MARK: - Messages
    
    public func formatMessage(_ message: String, type: MessageType) -> String {
        let messageData: [String: Any] = [
            "message": message,
            "type": messageTypeString(type)
        ]
        return encodeToJSONString(messageData)
    }
    
    public func formatCommandResponse(_ response: String, success: Bool) -> String {
        let responseData: [String: Any] = [
            "response": response,
            "success": success
        ]
        return encodeToJSONString(responseData)
    }
    
    public func formatError(_ error: Error) -> String {
        var errorData: [String: Any] = [
            "error": error.localizedDescription,
            "type": String(describing: type(of: error))
        ]
        
        // Add additional information for ApplicationError types
        if let appError = error as? ApplicationError {
            errorData["code"] = appError.errorCode
            
            // Add recovery suggestion based on verbosity
            if verbosity.rawValue >= VerbosityLevel.normal.rawValue {
                errorData["recoverySuggestion"] = appError.recoverySuggestion
            }
            
            // Add debug info based on verbosity
            if verbosity.rawValue >= VerbosityLevel.detailed.rawValue, 
               let debugInfo = appError.debugInfo {
                errorData["debugInfo"] = debugInfo
            }
        }
        
        return encodeToJSONString(errorData)
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
    
    /// Encode a dictionary to a JSON string
    /// - Parameter data: The dictionary to encode
    /// - Returns: A JSON string
    private func encodeToJSONString(_ data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            // Fall back to simple JSON if encoding fails
            print("Error encoding to JSON: \(error)")
        }
        
        // Fallback for encoding error
        return "{\"error\": \"Failed to encode data to JSON\"}"
    }
}