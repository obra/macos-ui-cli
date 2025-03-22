// ABOUTME: This file provides a Swift wrapper around the HAXElement class.
// ABOUTME: It enables traversal and interaction with UI elements.

import Foundation

#if HAXCESSIBILITY_AVAILABLE
import Haxcessibility
#endif

/// Represents a UI element from a macOS application
public class Element {
    private var haxElement: Any? = nil
    
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
    init(haxElement: Any?) {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxElement = haxElement as? HAXElement {
            self.haxElement = haxElement
            self.role = haxElement.role ?? "unknown"
            self.title = haxElement.title ?? ""
            self.hasChildren = haxElement.hasChildren
            self.pid = haxElement.processIdentifier
            
            // Load children
            if let haxChildren = haxElement.children {
                for haxChild in haxChildren {
                    let child = Element(haxElement: haxChild)
                    child.parent = self
                    self.children.append(child)
                }
            }
        }
        #else
        self.haxElement = nil
        #endif
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
        
        #if HAXCESSIBILITY_AVAILABLE
        if let haxElement = self.haxElement as? HAXElement,
           let attributeNames = haxElement.attributeNames {
            for name in attributeNames {
                // In a real implementation, we would get the attribute value
                // using the accessibility API
                attributes[name] = "Value for \(name)"
            }
        }
        #endif
        
        return attributes
    }
    
    /// Performs an action on the element (e.g., press a button)
    /// - Parameter action: The name of the action to perform
    /// - Returns: Whether the action was successful
    public func performAction(_ action: String) -> Bool {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxElement = self.haxElement as? HAXElement {
            if action == "press" && haxElement is HAXButton {
                (haxElement as? HAXButton)?.press()
                return true
            }
        }
        #endif
        return false
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
        // to get the focused element
        // For now, return a mock element
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