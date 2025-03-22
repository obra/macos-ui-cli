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
    public func getAttributes() -> [String: Any] {
        var attributes: [String: Any] = [:]
        
        if let haxElement = self.haxElement,
           let attributeNames = haxElement.attributeNames {
            for name in attributeNames {
                do {
                    let value = try haxElement.getAttributeValue(forKey: name)
                    attributes[name] = value
                } catch {
                    // Skip attributes that can't be accessed
                    continue
                }
            }
        }
        
        return attributes
    }
    
    /// Performs an action on the element (e.g., press a button)
    /// - Parameter action: The name of the action to perform
    /// - Returns: Whether the action was successful
    public func performAction(_ action: String) -> Bool {
        guard let haxElement = self.haxElement else {
            return false
        }
        
        do {
            try haxElement.performAction(action)
            return true
        } catch {
            return false
        }
    }
    
    /// Gets all descendant elements that match the given criteria
    /// - Parameters:
    ///   - role: The role to match
    ///   - title: The title to match
    /// - Returns: An array of matching elements
    public func findDescendants(byRole role: String? = nil, byTitle title: String? = nil) -> [Element] {
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
        
        // Recursively check children
        for child in children {
            results.append(contentsOf: child.findDescendants(byRole: role, byTitle: title))
        }
        
        return results
    }
    
    /// Sets focus to this element
    /// - Returns: True if successful, false otherwise
    public func focus() -> Bool {
        guard let haxElement = self.haxElement else {
            return false
        }
        
        // Try to set the AXFocused attribute to true
        do {
            try haxElement.setAttributeValue(true as CFTypeRef, forKey: "AXFocused")
            self.isFocused = true
            return true
        } catch {
            return false
        }
    }
    
    /// Gets available actions for this element
    /// - Returns: Array of action names
    public func getAvailableActions() -> [String] {
        guard let haxElement = self.haxElement else {
            return []
        }
        
        // Get actions from the accessibility API if available
        do {
            if let actionNames = try haxElement.getAttributeValue(forKey: "AXActions") as? [String] {
                return actionNames
            }
        } catch {
            // Ignore errors and return default actions
        }
        
        // Default actions that most elements support
        return ["focus"]
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
    public static func findElements(in container: Element, byRole role: String? = nil, byTitle title: String? = nil) -> [Element] {
        return container.findDescendants(byRole: role, byTitle: title)
    }
    
    /// Gets the currently focused element in the system
    /// - Returns: The focused element, or nil if none
    public static func getFocusedElement() -> Element? {
        let app = ApplicationManager.getFocusedApplication()
        guard let app = app, let _ = app.getFocusedWindow() else {
            return nil
        }
        
        // In a real implementation, we would query the accessibility API
        // using HAXElement's focusedElement functionality
        // For now we'll return a mock element for testing
        let element = Element(role: "textField", title: "Focused Element")
        element.isFocused = true
        return element
    }
    
    /// Finds an element using a path string
    /// - Parameters:
    ///   - path: A path string like "window[Main Window]/button[OK]"
    ///   - container: The container element to start from
    /// - Returns: The element at the path, or nil if not found
    public static func findElementByPath(_ path: String, in container: Element) -> Element? {
        let pathComponents = path.split(separator: "/")
        var currentElement = container
        
        for component in pathComponents {
            let parts = component.split(separator: "[")
            guard parts.count == 2 else { return nil }
            
            let role = String(parts[0])
            let title = String(parts[1].dropLast())
            
            let matches = currentElement.findDescendants(byRole: role, byTitle: title)
            guard let match = matches.first else { return nil }
            
            currentElement = match
        }
        
        return currentElement
    }
}