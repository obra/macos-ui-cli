// ABOUTME: This file provides a Swift wrapper around the HAXElement class.
// ABOUTME: It enables traversal and interaction with UI elements.

import Foundation
import Haxcessibility

/// Represents a UI element from a macOS application
public class Element: Equatable {
    // Additional properties to capture more useful accessibility information
    public var roleDescription: String = ""
    public var subRole: String = ""
    
    /// A user-friendly description of this element
    public var description: String {
        var desc = role
        
        // Include subrole if available (like AXMinimizeButton)
        if !subRole.isEmpty {
            desc += ":\(subRole)"
        }
        
        // If we have a title, use it
        if !title.isEmpty {
            desc += "[\(title)]"
            // Show role description in parentheses if both are available and different
            if !roleDescription.isEmpty && title != roleDescription {
                desc += " (\(roleDescription))"
            }
        } 
        // Otherwise, if we have a role description, use that instead
        else if !roleDescription.isEmpty {
            desc += "[\(roleDescription)]"
        }
        
        return desc
    }
    
    /// Implement Equatable to allow comparing elements
    public static func == (lhs: Element, rhs: Element) -> Bool {
        // Compare by reference if both have haxElement
        if let lhsElement = lhs.haxElement, let rhsElement = rhs.haxElement {
            return lhsElement === rhsElement
        }
        
        // Always compare by reference for interactive mode element tracking
        // This ensures that elements with the same role and title are still treated as distinct
        return lhs === rhs
    }
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
    
    /// Custom data for element - used for additional storage like raw AXUIElement references
    public var customData: [String: Any] = [:]
    
    /// Creates an Element instance from a HAXElement instance
    /// - Parameter haxElement: The HAXElement instance
    init(haxElement: HAXElement?) {
        self.haxElement = haxElement
        self.role = haxElement?.role ?? "unknown"
        self.title = haxElement?.title ?? ""
        self.hasChildren = haxElement?.hasChildren ?? false
        self.pid = haxElement?.processIdentifier ?? 0
        
        // Get additional properties for better descriptions
        if let haxElement = haxElement {
            // Get role description (like "minimize button")
            do {
                if let roleDesc = try haxElement.getAttributeValue(forKey: "AXRoleDescription") as? String {
                    self.roleDescription = roleDesc
                }
            } catch {
                // Just silently fail if we can't get it
            }
            
            // Get subrole (like AXMinimizeButton)
            do {
                if let subRole = try haxElement.getAttributeValue(forKey: "AXSubrole") as? String {
                    self.subRole = subRole
                }
            } catch {
                // Just silently fail if we can't get it
            }
        }
        
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
    ///   - roleDescription: Optional role description for the element
    ///   - subRole: Optional subrole for the element
    public init(role: String, title: String, hasChildren: Bool = false, 
         roleDescription: String = "", subRole: String = "") {
        self.role = role
        self.title = title
        self.hasChildren = hasChildren
        self.roleDescription = roleDescription
        self.subRole = subRole
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
    
    /// Loads children for this element if not already loaded.
    /// - Returns: True if children were loaded successfully or already loaded, false otherwise.
    @discardableResult
    public func loadChildrenIfNeeded() -> Bool {
        // Skip if children are already loaded
        if !self.children.isEmpty {
            return true
        }
        
        // Skip if not expected to have children
        if !self.hasChildren {
            return false
        }
        
        DebugLogger.shared.logInfo("Loading children for \(self.description)")
        
        // Try all available methods to load children
        
        // Method 1: Using HAXElement's children property
        if let haxElement = self.haxElement, let haxChildren = haxElement.children, !haxChildren.isEmpty {
            DebugLogger.shared.logInfo("Found \(haxChildren.count) children using HAXElement.children")
            for haxChild in haxChildren {
                let childElement = Element(haxElement: haxChild)
                childElement.parent = self
                self.children.append(childElement)
            }
            return true
        }
        
        // Method 2: Using HAXElement's getAttribute for AXChildren
        if let haxElement = self.haxElement {
            do {
                if let children = try haxElement.getAttributeValue(forKey: "AXChildren") as? [HAXElement], !children.isEmpty {
                    DebugLogger.shared.logInfo("Found \(children.count) children using HAXElement.getAttributeValue")
                    for child in children {
                        let childElement = Element(haxElement: child)
                        childElement.parent = self
                        self.children.append(childElement)
                    }
                    return true
                }
            } catch {
                DebugLogger.shared.logWarning("Failed to get AXChildren attribute: \(error)")
            }
        }
        
        // Method 3: Using direct AXUIElement API if we have a stored reference
        if let axRef = self.customData["axuielement"] {
            let axObject = axRef as AnyObject
            guard CFGetTypeID(axObject) == AXUIElementGetTypeID() else { return false }
            let axElement = axRef as! AXUIElement
            DebugLogger.shared.logInfo("Trying direct AXUIElement children access")
            
            var childrenRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(axElement, "AXChildren" as CFString, &childrenRef)
            
            if result == .success, let childArray = childrenRef as? NSArray, childArray.count > 0 {
                DebugLogger.shared.logInfo("Found \(childArray.count) children using AXUIElementCopyAttributeValue")
                
                for i in 0..<childArray.count {
                    let item = childArray[i] as AnyObject
                    guard CFGetTypeID(item) == AXUIElementGetTypeID() else { continue }
                    let childAXElement = childArray[i] as! AXUIElement
                    // Create element from raw AXUIElement
                    let childElement = createElementFromAXUIElement(childAXElement)
                    childElement.parent = self
                    self.children.append(childElement)
                }
                return true
            }
        }
        
        // No children found through any method
        DebugLogger.shared.logWarning("No children found for \(self.description) despite hasChildren=true")
        return false
    }
    
    /// Helper to create an Element from a raw AXUIElement
    private func createElementFromAXUIElement(_ axElement: AXUIElement) -> Element {
        // Get basic properties directly from AXUIElement
        var roleRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var roleDescRef: CFTypeRef?
        var subRoleRef: CFTypeRef?
        
        let role = AXUIElementCopyAttributeValue(axElement, "AXRole" as CFString, &roleRef) == .success ? 
            (roleRef as? String ?? "unknown") : "unknown"
        
        let title = AXUIElementCopyAttributeValue(axElement, "AXTitle" as CFString, &titleRef) == .success ?
            (titleRef as? String ?? "") : ""
        
        let roleDesc = AXUIElementCopyAttributeValue(axElement, "AXRoleDescription" as CFString, &roleDescRef) == .success ?
            (roleDescRef as? String ?? "") : ""
        
        let subRole = AXUIElementCopyAttributeValue(axElement, "AXSubrole" as CFString, &subRoleRef) == .success ?
            (subRoleRef as? String ?? "") : ""
        
        // Check if it has children
        var childrenRef: CFTypeRef?
        let hasChildren = AXUIElementCopyAttributeValue(axElement, "AXChildren" as CFString, &childrenRef) == .success &&
            (childrenRef as? NSArray)?.count ?? 0 > 0
        
        // Create element
        let element = Element(role: role, title: title, hasChildren: hasChildren,
                             roleDescription: roleDesc, subRole: subRole)
        
        // Store the AXUIElement for later use
        element.customData["axuielement"] = axElement
        
        return element
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
        
        if let role = role {
            // Check both main role and subrole
            if self.role.lowercased() != role.lowercased() && self.subRole.lowercased() != role.lowercased() {
                matches = false
            }
        }
        
        if let title = title {
            // Check title first
            let titleMatches = self.title.lowercased().contains(title.lowercased())
            
            // Check roleDescription regardless of whether title is empty
            // This allows finding elements by role description even when they have titles
            let descMatches = !self.roleDescription.isEmpty && 
                             self.roleDescription.lowercased().contains(title.lowercased())
            
            if !titleMatches && !descMatches {
                matches = false
            }
        }
        
        if matches {
            results.append(self)
        }
        
        // Ensure children are loaded if this element has children
        if self.hasChildren {
            self.loadChildrenIfNeeded()
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
        // If we don't have a HAX element, don't try to get attributes
        if self.haxElement == nil {
            return [:]
        }
        
        do {
            // Attempt to get attributes with a short timeout to prevent UI freezes
            var attributes: [String: Any] = [:]
            try withTimeout(0.5) {
                attributes = try self.getAttributes()
            }
            return attributes
        } catch let error as OperationError where error.errorCode == ErrorCode.operationTimeout.rawValue {
            // Silently return empty dictionary on timeout - this is common and not worth logging
            return [:]
        } catch {
            // Log other errors but don't display them in UI
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