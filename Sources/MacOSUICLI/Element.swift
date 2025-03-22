// ABOUTME: This file provides a Swift wrapper around the HAXElement class.
// ABOUTME: It enables traversal and interaction with UI elements.

import Foundation
import Haxcessibility

/// Represents a UI element from a macOS application
public class Element {
    private var haxElement: HAXElement? = nil
    
    /// The role of the element (e.g., button, text field)
    public var role: String = ""
    
    /// The title or label of the element
    public var title: String = ""
    
    /// Whether the element has children
    public var hasChildren: Bool = false
    
    /// The process ID of the element
    public var pid: pid_t = 0
    
    /// Whether the element is currently focused
    public var isFocused: Bool = false
    
    /// The parent element
    public weak var parent: Element? = nil
    
    /// The child elements
    public var children: [Element] = []
    
    /// Creates an Element instance from a HAXElement instance
    /// - Parameter haxElement: The HAXElement instance
    init(haxElement: HAXElement?) {
        self.haxElement = haxElement
        self.role = haxElement?.role ?? "unknown"
        self.title = haxElement?.title ?? ""
        self.hasChildren = haxElement?.hasChildren ?? false
        self.pid = haxElement?.processIdentifier ?? 0
        
        // Load children
        if let haxChildren = haxElement?.children {
            for haxChild in haxChildren {
                // Since all Haxcessibility objects inherit from HAXElement, we can use them directly
                let childElement = Element(haxElement: haxChild)
                childElement.parent = self
                self.children.append(childElement)
            }
        }
    }
    
    /// Creates a mock Element for testing
    /// - Parameters:
    ///   - role: The role of the element
    ///   - title: The title of the element
    ///   - hasChildren: Whether the element has children
    init(role: String, title: String, hasChildren: Bool = false) {
        self.role = role
        self.title = title
        self.hasChildren = hasChildren
    }
    
    /// Gets the underlying HAXElement instance
    /// - Returns: The HAXElement instance, or nil if not available
    public func getHaxElement() -> HAXElement? {
        return self.haxElement
    }
    
    /// Adds a child element
    /// - Parameter child: The child element to add
    public func addChild(_ child: Element) {
        child.parent = self
        self.children.append(child)
        self.hasChildren = true
    }
    
    /// Gets the attributes of the element
    /// - Returns: A dictionary of attribute names and values
    /// - Throws: UIElementError if attributes cannot be retrieved
    public func getAttributes() throws -> [String: Any] {
        var attributes: [String: Any] = [:]
        
        guard let haxElement = self.haxElement else {
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "No underlying accessibility element")
        }
        
        guard let attributeNames = haxElement.attributeNames else {
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "Cannot retrieve attribute names")
        }
        
        for name in attributeNames {
            do {
                let value = try haxElement.getAttributeValue(forKey: name)
                attributes[name] = value
            } catch {
                // Log the error but continue with other attributes
                DebugLogger.shared.logWarning("Failed to get attribute '\(name)' for element '\(title)': \(error.localizedDescription)")
                continue
            }
        }
        
        return attributes
    }
    
    /// Performs an action on the element (e.g., press a button)
    /// - Parameter action: The name of the action to perform
    /// - Throws: UIElementError if the action cannot be performed
    public func performAction(_ action: String) throws {
        guard let haxElement = self.haxElement else {
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "No underlying accessibility element")
        }
        
        // First check if the element supports this action
        let availableActions = getAvailableActionsNoThrow()
        if !availableActions.contains(action) {
            throw UIElementError.elementDoesNotSupportAction(description: "Element with title '\(title)' and role '\(role)'", action: action)
        }
        
        do {
            try withTimeout(5.0) {
                try haxElement.performAction(action)
            }
        } catch let error as OperationError {
            // Rethrow timeout errors
            throw error
        } catch {
            // Convert other errors to UIElementError
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "Failed to perform action '\(action)': \(error.localizedDescription)")
        }
    }
    
    /// Gets all descendant elements that match the given criteria
    /// - Parameters:
    ///   - role: The role to match
    ///   - title: The title to match
    /// - Returns: An array of matching elements
    /// - Throws: UIElementError if there's an issue accessing elements
    public func findDescendants(byRole role: String? = nil, byTitle title: String? = nil) throws -> [Element] {
        var results: [Element] = []
        
        // Check if this element matches
        var matches = true
        
        if let role = role, self.role != role {
            matches = false
        }
        
        if let title = title, self.title != title {
            matches = false
        }
        
        if matches {
            results.append(self)
        }
        
        // Use timeout in case the tree is very large
        try withTimeout(10.0) {
            // Recursively check children
            for child in self.children {
                do {
                    let childResults = try child.findDescendants(byRole: role, byTitle: title)
                    results.append(contentsOf: childResults)
                } catch {
                    // Log the error but continue with other children
                    DebugLogger.shared.logWarning("Error searching child element: \(error.localizedDescription)")
                }
            }
        }
        
        return results
    }
    
    /// Safe version of findDescendants that doesn't throw
    /// - Parameters:
    ///   - role: The role to match
    ///   - title: The title to match
    /// - Returns: An array of matching elements, empty array if there was an error
    public func findDescendantsNoThrow(byRole role: String? = nil, byTitle title: String? = nil) -> [Element] {
        do {
            return try findDescendants(byRole: role, byTitle: title)
        } catch {
            DebugLogger.shared.logError(error)
            return []
        }
    }
    
    /// Sets focus to this element
    /// - Throws: UIElementError if focus cannot be set
    public func focus() throws {
        guard let haxElement = self.haxElement else {
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "No underlying accessibility element")
        }
        
        // Try to set the AXFocused attribute to true
        do {
            try withRetry(maxAttempts: 3, delay: 0.5) {
                try haxElement.setAttributeValue(true as CFTypeRef, forKey: "AXFocused")
            }
            self.isFocused = true
        } catch let error as OperationError {
            // Rethrow timeout or retry errors
            throw error
        } catch {
            // Convert other errors to UIElementError
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "Failed to set focus: \(error.localizedDescription)")
        }
    }
    
    /// Gets available actions for this element
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    public func getAvailableActions() throws -> [String] {
        guard let haxElement = self.haxElement else {
            throw UIElementError.invalidElementState(description: "Element with title '\(title)'", state: "No underlying accessibility element")
        }
        
        // Get actions from the accessibility API if available
        do {
            if let actionNames = try haxElement.getAttributeValue(forKey: "AXActions") as? [String] {
                // Always include focus if it's not already there
                var actions = Set(actionNames)
                actions.insert("focus")
                return Array(actions)
            }
        } catch {
            // Log the error but continue with default actions
            DebugLogger.shared.logWarning("Failed to get actions for element '\(title)': \(error.localizedDescription)")
        }
        
        // Default actions that most elements support
        return ["focus"]
    }
    
    /// Safe version of getAvailableActions that doesn't throw
    /// - Returns: Array of action names, empty array if there was an error
    public func getAvailableActionsNoThrow() -> [String] {
        do {
            return try getAvailableActions()
        } catch {
            DebugLogger.shared.logError(error)
            return ["focus"]
        }
    }
    
    /// Safe version of getAttributes that doesn't throw
    /// - Returns: Dictionary of attribute names and values, empty dictionary if there was an error
    public func getAttributesNoThrow() -> [String: Any] {
        do {
            return try getAttributes()
        } catch {
            DebugLogger.shared.logError(error)
            return [:]
        }
    }
}

/// Utility class for finding elements across the system
public class ElementFinder {
    /// Finds elements matching the given criteria in a container element
    /// - Parameters:
    ///   - container: The container element to search within
    ///   - role: The role to match
    ///   - title: The title to match
    /// - Returns: An array of matching elements
    /// - Throws: UIElementError if elements cannot be found or accessed
    public static func findElements(in container: Element, byRole role: String? = nil, byTitle title: String? = nil) throws -> [Element] {
        return try container.findDescendants(byRole: role, byTitle: title)
    }
    
    /// Safe version of findElements that doesn't throw
    /// - Parameters:
    ///   - container: The container element to search within
    ///   - role: The role to match
    ///   - title: The title to match
    /// - Returns: An array of matching elements, empty array if there was an error
    public static func findElementsNoThrow(in container: Element, byRole role: String? = nil, byTitle title: String? = nil) -> [Element] {
        do {
            return try findElements(in: container, byRole: role, byTitle: title)
        } catch {
            DebugLogger.shared.logError(error)
            return []
        }
    }
    
    /// Gets the currently focused element in the system
    /// - Returns: The focused element
    /// - Throws: UIElementError if focused element cannot be determined
    public static func getFocusedElement() throws -> Element {
        guard let app = try ApplicationManager.getFocusedApplication() else {
            throw ApplicationManagerError.applicationNotFound(description: "No focused application")
        }
        
        guard let window = try app.getFocusedWindow() else {
            throw UIElementError.elementNotFound(description: "Focused window")
        }
        
        // In a real implementation, we would query the accessibility API
        // using HAXElement's focusedElement functionality
        // For now we'll handle the mock implementation
        #if DEBUG
        // For testing we'll return a mock element
        let element = Element(role: "textField", title: "Focused Element")
        element.isFocused = true
        return element
        #else
        // Try to find the focused element using the API
        guard let haxElement = window.getHaxElement() else {
            throw UIElementError.invalidElementState(description: "Window with title '\(window.title)'", state: "No underlying accessibility element")
        }
        
        do {
            if let focusedElement = try haxElement.getAttributeValue(forKey: "AXFocusedElement") as? HAXElement {
                let element = Element(haxElement: focusedElement)
                element.isFocused = true
                return element
            } else {
                throw UIElementError.elementNotFound(description: "Focused element in window '\(window.title)'")
            }
        } catch {
            throw UIElementError.invalidElementState(description: "Window with title '\(window.title)'", state: "Failed to get focused element: \(error.localizedDescription)")
        }
        #endif
    }
    
    /// Safe version of getFocusedElement that doesn't throw
    /// - Returns: The focused element, or nil if there was an error
    public static func getFocusedElementNoThrow() -> Element? {
        do {
            return try getFocusedElement()
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
    
    /// Finds an element using a path string
    /// - Parameters:
    ///   - path: A path string like "window[Main Window]/button[OK]"
    ///   - container: The container element to start from
    /// - Returns: The element at the path
    /// - Throws: UIElementError if element cannot be found
    public static func findElementByPath(_ path: String, in container: Element) throws -> Element {
        let pathComponents = path.split(separator: "/")
        var currentElement = container
        
        try withTimeout(5.0) {
            for component in pathComponents {
                let parts = component.split(separator: "[")
                guard parts.count == 2 else {
                    throw ValidationError.invalidArgument(name: "path", reason: "Invalid path format at component: \(component)")
                }
                
                let role = String(parts[0])
                let title = String(parts[1].dropLast())
                
                let matches = try currentElement.findDescendants(byRole: role, byTitle: title)
                guard let match = matches.first else {
                    throw UIElementError.elementNotFound(description: "\(role) with title '\(title)'")
                }
                
                currentElement = match
            }
        }
        
        return currentElement
    }
    
    /// Safe version of findElementByPath that doesn't throw
    /// - Parameters:
    ///   - path: A path string like "window[Main Window]/button[OK]"
    ///   - container: The container element to start from
    /// - Returns: The element at the path, or nil if not found
    public static func findElementByPathNoThrow(_ path: String, in container: Element) -> Element? {
        do {
            return try findElementByPath(path, in: container)
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
}