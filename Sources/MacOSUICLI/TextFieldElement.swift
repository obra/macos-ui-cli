// ABOUTME: This file provides a Swift wrapper for text field UI elements.
// ABOUTME: It enables reading and writing text in UI text fields.

import Foundation
import Haxcessibility

/// Represents a text field element from a macOS application
public class TextFieldElement: Element {
    /// Creates a TextFieldElement instance from a HAXElement instance
    /// - Parameter haxElement: The HAXElement instance
    override init(haxElement: HAXElement?) {
        super.init(haxElement: haxElement)
    }
    
    /// Creates a TextFieldElement instance from an Element instance
    /// - Parameter element: The Element instance
    /// - Returns: A TextFieldElement instance, or nil if the element is not a text field
    public static func fromElement(_ element: Element) -> TextFieldElement? {
        // Check if the element is a text field
        guard element.role == "AXTextField" || element.role == "textField",
              let haxElement = element.getHaxElement() else {
            return nil
        }
        
        return TextFieldElement(haxElement: haxElement)
    }
    
    /// Gets the current value of the text field
    /// - Returns: The current text value, or nil if not available
    public func getValue() -> String? {
        guard let haxElement = self.getHaxElement() else {
            return nil
        }
        
        // Get the value attribute from the element
        do {
            if let value = try haxElement.getAttributeValue(forKey: "AXValue") as? String {
                return value
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// Sets the value of the text field
    /// - Parameter newValue: The new text value
    /// - Returns: True if successful, false otherwise
    public func setValue(_ newValue: String) -> Bool {
        guard let haxElement = self.getHaxElement() else {
            return false
        }
        
        // Set the value attribute
        do {
            try haxElement.setAttributeValue(newValue as CFTypeRef, forKey: "AXValue")
            return true
        } catch {
            return false
        }
    }
    
    /// Gets available actions for this text field
    /// - Returns: Array of action names
    public override func getAvailableActions() -> [String] {
        var actions = super.getAvailableActions()
        actions.append(contentsOf: ["getValue", "setValue"])
        return actions
    }
}