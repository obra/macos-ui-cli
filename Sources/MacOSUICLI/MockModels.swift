// ABOUTME: This file provides mock models for testing UI element discovery functionality.
// ABOUTME: It enables testing without requiring actual UI elements or accessibility permissions.

import Foundation
import CoreGraphics

/// Mock implementation of Window for testing
public class MockWindow: Window {
    /// Whether the window is currently focused
    public var isFocused: Bool = false
    
    /// Creates a mock window with the specified properties
    /// - Parameters:
    ///   - title: The title of the mock window
    ///   - frame: The frame of the mock window
    ///   - isFullscreen: Whether the mock window is fullscreen
    override init(title: String, frame: CGRect, isFullscreen: Bool = false) {
        super.init(title: title, frame: frame, isFullscreen: isFullscreen)
    }
    
    /// Brings the window to the front
    /// - Throws: WindowError if the window cannot be raised
    override public func raise() throws {
        // In mock, we don't need to do anything
        return
    }
    
    /// Closes the window
    /// - Throws: WindowError if the window cannot be closed
    override public func close() throws {
        // In mock, we don't need to do anything
        return
    }
    
    /// Gets the UI elements in the window
    /// - Returns: An array of UI elements in the window
    /// - Throws: WindowError if elements cannot be retrieved
    override public func getElements() throws -> [Element] {
        // Return an empty array for testing
        return []
    }
    
    /// Sets focus to this window
    /// - Throws: WindowError if focus cannot be set
    override public func focus() throws {
        self.isFocused = true
    }
}

/// Mock implementation of Element for testing
public class MockElement: Element {
    /// Creates a mock element with the specified properties
    /// - Parameters:
    ///   - role: The role of the mock element
    ///   - title: The title of the mock element
    ///   - hasChildren: Whether the mock element has children
    ///   - roleDescription: Optional role description for the element
    ///   - subRole: Optional subrole for the element
    override init(role: String, title: String, hasChildren: Bool = false,
                  roleDescription: String = "", subRole: String = "") {
        super.init(role: role, title: title, hasChildren: hasChildren,
                   roleDescription: roleDescription, subRole: subRole)
    }
    
    /// Gets mock attributes
    /// - Returns: A dictionary with mock attributes
    /// - Throws: UIElementError if attributes cannot be retrieved
    override public func getAttributes() throws -> [String: Any] {
        return [
            "role": self.role,
            "title": self.title,
            "enabled": true,
            "visible": true
        ]
    }
    
    /// Simulates performing an action on the element
    /// - Parameter action: The name of the action to perform
    /// - Throws: UIElementError if the action cannot be performed
    override public func performAction(_ action: String) throws {
        if action != "press" {
            throw UIElementError.elementDoesNotSupportAction(description: "Element with title '\(title)'", action: action)
        }
    }
    
    /// Gets available actions for this element
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    override public func getAvailableActions() throws -> [String] {
        return ["press"]
    }
    
    /// Safe version of getAvailableActions that doesn't throw
    /// - Returns: Array of action names
    override public func getAvailableActionsNoThrow() -> [String] {
        return ["press"]
    }
}

/// Mock implementation of a button element
public class MockButtonElement: MockElement {
    /// Whether the button has been pressed
    public var wasPressed: Bool = false
    
    /// Creates a mock button with the specified title
    /// - Parameter title: The title of the button
    init(title: String) {
        super.init(role: "button", title: title, hasChildren: false, 
                  roleDescription: "button", subRole: "")
    }
    
    /// Simulates pressing the button
    /// - Throws: UIElementError if the button cannot be pressed
    public func press() throws {
        self.wasPressed = true
    }
    
    /// Gets available actions for this button
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    public override func getAvailableActions() throws -> [String] {
        return ["press"]
    }
    
    /// Safe version of getAvailableActions that doesn't throw
    /// - Returns: Array of action names
    public override func getAvailableActionsNoThrow() -> [String] {
        return ["press"]
    }
}

/// Mock implementation of a text field element
public class MockTextFieldElement: MockElement {
    /// The current value of the text field
    private var value: String
    
    /// Creates a mock text field with the specified title and value
    /// - Parameters:
    ///   - title: The title of the text field
    ///   - value: The initial value of the text field
    init(title: String, value: String) {
        self.value = value
        super.init(role: "textField", title: title, hasChildren: false,
                  roleDescription: "text field", subRole: "")
    }
    
    /// Gets the current value of the text field
    /// - Returns: The current text value
    /// - Throws: UIElementError if the value cannot be retrieved
    public func getValue() throws -> String {
        return self.value
    }
    
    /// Sets the value of the text field
    /// - Parameter newValue: The new text value
    /// - Throws: UIElementError if the value cannot be set
    public func setValue(_ newValue: String) throws {
        self.value = newValue
    }
    
    /// Gets available actions for this text field
    /// - Returns: Array of action names
    /// - Throws: UIElementError if actions cannot be retrieved
    public override func getAvailableActions() throws -> [String] {
        return ["getValue", "setValue"]
    }
    
    /// Safe version of getAvailableActions that doesn't throw
    /// - Returns: Array of action names
    public override func getAvailableActionsNoThrow() -> [String] {
        return ["getValue", "setValue"]
    }
}

// For our testing purposes, we'll just rely on the actual implementations
// and use the mocks for Window and Element classes only