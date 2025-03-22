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
    /// - Returns: True if successful, false otherwise
    public func press() -> Bool {
        if let button = self.haxButton {
            button.press()
            return true
        }
        return false
    }
    
    /// Gets available actions for this button
    /// - Returns: Array of action names
    public override func getAvailableActions() -> [String] {
        var actions = super.getAvailableActions()
        actions.append("press")
        return actions
    }
}