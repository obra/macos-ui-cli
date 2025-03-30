// ABOUTME: This file provides a Swift wrapper around the HAXButton class.
// ABOUTME: It enables interaction with button elements in the UI.

import Foundation
import Haxcessibility

/// Represents a button element from a macOS application
public class ButtonElement: Element {
    /// The underlying HAXButton instance
    private var haxButton: HAXButton? = nil
    
    /// Creates a ButtonElement instance from a HAXButton instance
    /// - Parameter haxButton: The HAXButton instance
    init(haxButton: HAXButton?) {
        super.init(haxElement: haxButton)
        self.haxButton = haxButton
    }
    
    /// Creates a ButtonElement instance from an Element instance
    /// - Parameter element: The Element instance
    /// - Returns: A ButtonElement instance, or nil if the element is not a button
    public static func fromElement(_ element: Element) -> ButtonElement? {
        guard element.role == "AXButton" || element.role == "button",
              let haxElement = element.getHaxElement() else {
            return nil
        }
        
        if let haxButton = haxElement as? HAXButton {
            return ButtonElement(haxButton: haxButton)
        }
        
        // If the element is a button but not a HAXButton, create a HAXButton from it
        return nil
    }
    
    /// Presses the button
    /// - Throws: UIElementError if the button cannot be pressed
    public func press() throws {
        guard let button = self.haxButton else {
            throw UIElementError.invalidElementState(
                description: "Button with title '\(title)'", 
                state: "No underlying HAXButton element"
            )
        }
        
        do {
            try withTimeoutAndRetry(timeout: 3.0, maxAttempts: 2) {
                button.press()
            }
        } catch let error as OperationError {
            // Rethrow timeout or retry errors
            throw error
        } catch {
            // Convert other errors to UIElementError
            throw UIElementError.invalidElementState(
                description: "Button with title '\(title)'", 
                state: "Failed to press: \(error.localizedDescription)"
            )
        }
    }
    
    /// Safe version of press that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func pressNoThrow() -> Bool {
        do {
            try press()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Gets available actions for this button
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    public override func getAvailableActions() throws -> [String] {
        var actions = try super.getAvailableActions()
        actions.append("press")
        return actions
    }
}