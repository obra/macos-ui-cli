// ABOUTME: This file contains tests for basic UI interaction functionality.
// ABOUTME: It verifies capabilities to interact with buttons, text fields, and windows.

import XCTest
@testable import MacOSUICLI

final class UIInteractionTests: XCTestCase {
    func testButtonInteraction() {
        // Test button pressing functionality using a mock button
        let button = MockButtonElement(title: "OK")
        
        XCTAssertFalse(button.wasPressed, "Button should not be pressed initially")
        
        let success = button.press()
        XCTAssertTrue(success, "Button press should succeed")
        XCTAssertTrue(button.wasPressed, "Button should be pressed after press() method")
    }
    
    func testTextFieldInteraction() {
        // Test text field reading and writing
        let textField = MockTextFieldElement(title: "Name", value: "Initial Text")
        
        // Test reading
        XCTAssertEqual(textField.getValue(), "Initial Text", "Text field should return its value")
        
        // Test writing
        let writeSuccess = textField.setValue("New Text")
        XCTAssertTrue(writeSuccess, "Setting text field value should succeed")
        XCTAssertEqual(textField.getValue(), "New Text", "Text field should have new value")
    }
    
    func testWindowManipulation() {
        // Test window manipulation (move, resize, focus)
        let window = MockWindow(title: "Test Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        
        // Test window position change
        let moveSuccess = window.setPosition(CGPoint(x: 100, y: 100))
        XCTAssertTrue(moveSuccess, "Setting window position should succeed")
        XCTAssertEqual(window.frame.origin.x, 100, "Window x position should be updated")
        XCTAssertEqual(window.frame.origin.y, 100, "Window y position should be updated")
        
        // Test window size change
        let resizeSuccess = window.setSize(CGSize(width: 1000, height: 800))
        XCTAssertTrue(resizeSuccess, "Setting window size should succeed")
        XCTAssertEqual(window.frame.size.width, 1000, "Window width should be updated")
        XCTAssertEqual(window.frame.size.height, 800, "Window height should be updated")
        
        // Test focus
        let focusSuccess = window.focus()
        XCTAssertTrue(focusSuccess, "Setting window focus should succeed")
        XCTAssertTrue(window.isFocused, "Window should be focused after focus() method")
    }
    
    func testKeyboardInput() {
        // Test keyboard input simulation
        let success = KeyboardInput.typeString("Hello, World!")
        XCTAssertTrue(success, "Keyboard input should succeed")
        
        // Test key combination
        let combinationSuccess = KeyboardInput.pressKeyCombination([.command, .option], key: "c")
        XCTAssertTrue(combinationSuccess, "Key combination should succeed")
    }
    
    func testElementActionDiscovery() {
        // Test discovering available actions on elements
        let button = MockButtonElement(title: "OK")
        let textField = MockTextFieldElement(title: "Name", value: "Text")
        
        let buttonActions = button.getAvailableActions()
        XCTAssertTrue(buttonActions.contains("press"), "Button should support press action")
        
        let textFieldActions = textField.getAvailableActions()
        XCTAssertTrue(textFieldActions.contains("setValue"), "TextField should support setValue action")
    }
    
    static var allTests = [
        ("testButtonInteraction", testButtonInteraction),
        ("testTextFieldInteraction", testTextFieldInteraction),
        ("testWindowManipulation", testWindowManipulation),
        ("testKeyboardInput", testKeyboardInput),
        ("testElementActionDiscovery", testElementActionDiscovery)
    ]
}