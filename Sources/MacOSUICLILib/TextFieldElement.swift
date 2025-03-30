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
    /// - Returns: The current text value
    /// - Throws: UIElementError if the value cannot be retrieved
    public func getValue() throws -> String {
        guard let haxElement = self.getHaxElement() else {
            throw UIElementError.invalidElementState(
                description: "Text field with title '\(title)'", 
                state: "No underlying accessibility element"
            )
        }
        
        // Get the value attribute from the element with timeout
        do {
            return try withTimeout(3.0) {
                if let value = try haxElement.getAttributeValue(forKey: "AXValue") as? String {
                    return value
                } else {
                    throw UIElementError.invalidElementState(
                        description: "Text field with title '\(self.title)'", 
                        state: "Value attribute is not a string"
                    )
                }
            }
        } catch let error as OperationError {
            // Rethrow timeout errors
            throw error
        } catch let error as UIElementError {
            // Rethrow UIElementError
            throw error
        } catch {
            // Convert other errors to UIElementError
            throw UIElementError.invalidElementState(
                description: "Text field with title '\(title)'", 
                state: "Failed to get value: \(error.localizedDescription)"
            )
        }
    }
    
    /// Safe version of getValue that doesn't throw
    /// - Returns: The current text value, or nil if not available
    public func getValueNoThrow() -> String? {
        do {
            return try getValue()
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
    
    /// Sets the value of the text field
    /// - Parameter newValue: The new text value
    /// - Throws: UIElementError if the value cannot be set
    public func setValue(_ newValue: String) throws {
        guard let haxElement = self.getHaxElement() else {
            throw UIElementError.invalidElementState(
                description: "Text field with title '\(title)'", 
                state: "No underlying accessibility element"
            )
        }
        
        // Set the value attribute with timeout and retry
        do {
            try withTimeoutAndRetry(timeout: 3.0, maxAttempts: 2) {
                try haxElement.setAttributeValue(newValue as CFTypeRef, forKey: "AXValue")
            }
        } catch let error as OperationError {
            // Rethrow timeout or retry errors
            throw error
        } catch {
            // Convert other errors to UIElementError
            throw UIElementError.invalidElementState(
                description: "Text field with title '\(title)'", 
                state: "Failed to set value: \(error.localizedDescription)"
            )
        }
    }
    
    /// Safe version of setValue that doesn't throw
    /// - Parameter newValue: The new text value
    /// - Returns: True if successful, false otherwise
    public func setValueNoThrow(_ newValue: String) -> Bool {
        do {
            try setValue(newValue)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Gets available actions for this text field
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    public override func getAvailableActions() throws -> [String] {
        var actions = try super.getAvailableActions()
        actions.append(contentsOf: ["getValue", "setValue"])
        return actions
    }
    
    /// Safe version of getAvailableActions that doesn't throw
    /// - Returns: Array of action names, default actions if there was an error
    public override func getAvailableActionsNoThrow() -> [String] {
        do {
            return try getAvailableActions()
        } catch {
            DebugLogger.shared.logError(error)
            return ["focus", "getValue", "setValue"]
        }
    }
}