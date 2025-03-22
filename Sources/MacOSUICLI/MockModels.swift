// ABOUTME: This file provides mock models for testing UI element discovery functionality.
// ABOUTME: It enables testing without requiring actual UI elements or accessibility permissions.

import Foundation
import CoreGraphics

/// Mock implementation of Window for testing
public class MockWindow: Window {
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
}