// ABOUTME: This file provides utilities for finding UI elements in the interactive mode.
// ABOUTME: It supports searching by role, title, path, and other attributes for REPL operations.

import Foundation
import Haxcessibility

/// Utility class for finding and filtering UI elements in the interactive mode
public class InteractiveElementFinder {
    /// Error type for element finding operations
    public enum InteractiveElementFinderError: Error, LocalizedError {
        case elementNotFound(String)
        case invalidPath(String)
        case noFocusedElement
        
        public var errorDescription: String? {
            switch self {
            case .elementNotFound(let details):
                return "Element not found: \(details)"
            case .invalidPath(let details):
                return "Invalid element path: \(details)"
            case .noFocusedElement:
                return "No focused element found"
            }
        }
    }
    
    /// Get the currently focused UI element
    /// - Returns: The focused element, if any
    /// - Throws: InteractiveElementFinderError if no focused element is found
    public static func getFocusedElement() throws -> Element {
        guard let app = try ApplicationManager.getFocusedApplication() else {
            throw InteractiveElementFinderError.noFocusedElement
        }
        
        guard let window = try app.getFocusedWindow() else {
            throw InteractiveElementFinderError.noFocusedElement
        }
        
        // Placeholder: In a real implementation, we would use the accessibility API to find the focused element
        // within the window. For now, return the window as the focused element.
        return Element(role: "window", title: window.title)
    }
    
    /// Find elements that match the given criteria
    /// - Parameters:
    ///   - element: The root element to search within
    ///   - role: Optional role to filter by
    ///   - title: Optional title to filter by
    /// - Returns: Array of matching elements
    /// - Throws: InteractiveElementFinderError if an error occurs during the search
    public static func findElements(
        in element: Element,
        byRole role: String? = nil,
        byTitle title: String? = nil
    ) throws -> [Element] {
        var elements: [Element] = []
        
        // Add the current element if it matches
        if matchesFilters(element, role: role, title: title) {
            elements.append(element)
        }
        
        // Add children recursively
        for child in element.children {
            let childResults = try findElements(in: child, byRole: role, byTitle: title)
            elements.append(contentsOf: childResults)
        }
        
        return elements
    }
    
    /// Find a specific element by its path expression
    /// - Parameters:
    ///   - path: Path expression (e.g., "window[Main]/button[OK]")
    ///   - rootElement: The root element to start the search from
    /// - Returns: The found element
    /// - Throws: InteractiveElementFinderError if the element cannot be found or the path is invalid
    public static func findElementByPath(_ path: String, in rootElement: Element) throws -> Element {
        let pathComponents = parsePath(path)
        guard !pathComponents.isEmpty else {
            throw InteractiveElementFinderError.invalidPath("Path cannot be empty")
        }
        
        var currentElement = rootElement
        
        // Skip the first component if it matches the root element
        let startIndex = (matchesPathComponent(currentElement, component: pathComponents[0])) ? 1 : 0
        
        for i in startIndex..<pathComponents.count {
            let component = pathComponents[i]
            
            // Look for a child that matches this path component
            if let matchingChild = currentElement.children.first(where: { matchesPathComponent($0, component: component) }) {
                currentElement = matchingChild
            } else {
                throw InteractiveElementFinderError.elementNotFound("No element found for path component: \(component)")
            }
        }
        
        return currentElement
    }
    
    /// Parse a path expression into components
    /// - Parameter path: Path expression (e.g., "window[Main]/button[OK]")
    /// - Returns: Array of (role, identifier) tuples
    private static func parsePath(_ path: String) -> [(role: String, identifier: String?)] {
        var components: [(role: String, identifier: String?)] = []
        
        // Split by "/" to get individual path components
        let parts = path.split(separator: "/")
        
        for part in parts {
            let partString = String(part)
            
            // Match "role[identifier]" pattern
            if let regex = try? NSRegularExpression(pattern: "([a-zA-Z]+)\\[([^\\]]+)\\]", options: []) {
                let nsString = partString as NSString
                let matches = regex.matches(in: partString, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges >= 3 {
                    let role = nsString.substring(with: match.range(at: 1))
                    let identifier = nsString.substring(with: match.range(at: 2))
                    components.append((role: role, identifier: identifier))
                } else {
                    // If no brackets, treat as just a role
                    components.append((role: partString, identifier: nil))
                }
            } else {
                // Fallback if regex fails
                components.append((role: partString, identifier: nil))
            }
        }
        
        return components
    }
    
    /// Check if an element matches a path component
    /// - Parameters:
    ///   - element: The element to check
    ///   - component: Path component (role, identifier)
    /// - Returns: Whether the element matches the component
    private static func matchesPathComponent(_ element: Element, component: (role: String, identifier: String?)) -> Bool {
        // Role must match
        if element.role.lowercased() != component.role.lowercased() {
            return false
        }
        
        // If identifier is specified, it must match the title
        if let identifier = component.identifier {
            return element.title.lowercased() == identifier.lowercased()
        }
        
        // If no identifier, just matching the role is enough
        return true
    }
    
    /// Check if an element matches the given filters
    /// - Parameters:
    ///   - element: The element to check
    ///   - role: Optional role filter
    ///   - title: Optional title filter
    /// - Returns: Whether the element matches all specified filters
    private static func matchesFilters(_ element: Element, role: String?, title: String?) -> Bool {
        // Check role if specified, including subrole
        if let roleFilter = role {
            let normalizedRole = roleFilter.lowercased()
            // Check main role
            if element.role.lowercased() == normalizedRole {
                // Match - continue to title check
            }
            // Check subrole
            else if !element.subRole.isEmpty && element.subRole.lowercased() == normalizedRole {
                // Match - continue to title check  
            }
            // No role match
            else {
                return false
            }
        }
        
        // Check title if specified, including role description for untitled elements
        if let titleFilter = title {
            let normalizedTitle = titleFilter.lowercased()
            
            // Check in the title
            if element.title.lowercased().contains(normalizedTitle) {
                return true
            }
            
            // Check in role description regardless of whether title is empty
            // This allows matching on role descriptions even for elements with titles
            if !element.roleDescription.isEmpty {
                if element.roleDescription.lowercased().contains(normalizedTitle) {
                    return true
                }
            }
            
            // No match on title or role description
            return false
        }
        
        // If we got here, all specified filters matched
        return true
    }
}