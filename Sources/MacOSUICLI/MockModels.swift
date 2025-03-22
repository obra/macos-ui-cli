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
    
    /// Simulates raising the window
    /// - Returns: Always returns true for mocks
    override public func raise() -> Bool {
        return true
    }
    
    /// Simulates closing the window
    /// - Returns: Always returns true for mocks
    override public func close() -> Bool {
        return true
    }
    
    /// Simulates focusing the window
    /// - Returns: Always returns true for mocks
    public func focus() -> Bool {
        self.isFocused = true
        return true
    }
    
    /// Simulates setting the window position
    /// - Parameter position: The new position
    /// - Returns: Always returns true for mocks
    public func setPosition(_ position: CGPoint) -> Bool {
        self.frame.origin = position
        return true
    }
    
    /// Simulates setting the window size
    /// - Parameter size: The new size
    /// - Returns: Always returns true for mocks
    public func setSize(_ size: CGSize) -> Bool {
        self.frame.size = size
        return true
    }
}

/// Mock implementation of Element for testing
public class MockElement: Element {
    /// Creates a mock element with the specified properties
    /// - Parameters:
    ///   - role: The role of the mock element
    ///   - title: The title of the mock element
    ///   - hasChildren: Whether the mock element has children
    override init(role: String, title: String, hasChildren: Bool = false) {
        super.init(role: role, title: title, hasChildren: hasChildren)
    }
    
    /// Gets mock attributes
    /// - Returns: A dictionary with mock attributes
    override public func getAttributes() -> [String: Any] {
        return [
            "role": self.role,
            "title": self.title,
            "enabled": true,
            "visible": true
        ]
    }
    
    /// Simulates performing an action on the element
    /// - Parameter action: The name of the action to perform
    /// - Returns: True if the action is "press", false otherwise
    override public func performAction(_ action: String) -> Bool {
        return action == "press"
    }
    
    /// Gets available actions for this element
    /// - Returns: Array of action names
    public func getAvailableActions() -> [String] {
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
        super.init(role: "button", title: title)
    }
    
    /// Simulates pressing the button
    /// - Returns: Always returns true for mocks
    public func press() -> Bool {
        self.wasPressed = true
        return true
    }
    
    /// Gets available actions for this button
    /// - Returns: Array of action names
    override public func getAvailableActions() -> [String] {
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
        super.init(role: "textField", title: title)
    }
    
    /// Gets the current value of the text field
    /// - Returns: The current text value
    public func getValue() -> String {
        return self.value
    }
    
    /// Sets the value of the text field
    /// - Parameter newValue: The new text value
    /// - Returns: Always returns true for mocks
    public func setValue(_ newValue: String) -> Bool {
        self.value = newValue
        return true
    }
    
    /// Gets available actions for this text field
    /// - Returns: Array of action names
    override public func getAvailableActions() -> [String] {
        return ["getValue", "setValue"]
    }
}

/// Utility for simulating keyboard input
public class KeyboardInput {
    /// The available modifier keys
    public enum Modifier {
        case command
        case option
        case control
        case shift
    }
    
    /// Simulates typing a string
    /// - Parameter string: The string to type
    /// - Returns: Always returns true in mock implementation
    public static func typeString(_ string: String) -> Bool {
        return true
    }
    
    /// Simulates pressing a key combination
    /// - Parameters:
    ///   - modifiers: Array of modifier keys to press
    ///   - key: The main key to press
    /// - Returns: Always returns true in mock implementation
    public static func pressKeyCombination(_ modifiers: [Modifier], key: String) -> Bool {
        return true
    }
}