// ABOUTME: This file contains tests for basic UI interaction functionality.
// ABOUTME: It verifies capabilities to interact with buttons, text fields, and windows.

import XCTest
@testable import MacOSUICLI

final class UIInteractionTests: XCTestCase {
    func testButtonInteraction() {
        // Test button pressing functionality using a mock button
        let button = MockButtonElement(title: "OK")
        
        XCTAssertFalse(button.wasPressed, "Button should not be pressed initially")
        
        do {
            try button.press()
            XCTAssertTrue(button.wasPressed, "Button should be pressed after press() method")
        } catch {
            XCTFail("Button press should not throw error: \(error)")
        }
    }
    
    func testTextFieldInteraction() {
        // Test text field reading and writing
        let textField = MockTextFieldElement(title: "Name", value: "Initial Text")
        
        // Test reading
        do {
            let value = try textField.getValue()
            XCTAssertEqual(value, "Initial Text", "Text field should return its value")
            
            // Test writing
            try textField.setValue("New Text")
            let newValue = try textField.getValue()
            XCTAssertEqual(newValue, "New Text", "Text field should have new value")
        } catch {
            XCTFail("Text field operations should not throw error: \(error)")
        }
    }
    
    func testWindowManipulation() {
        // Test window manipulation (move, resize, focus)
        let window = MockWindow(title: "Test Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        
        do {
            // Test window position change
            try window.setPosition(CGPoint(x: 100, y: 100))
            XCTAssertEqual(window.frame.origin.x, 100, "Window x position should be updated")
            XCTAssertEqual(window.frame.origin.y, 100, "Window y position should be updated")
            
            // Test window size change
            try window.setSize(CGSize(width: 1000, height: 800))
            XCTAssertEqual(window.frame.size.width, 1000, "Window width should be updated")
            XCTAssertEqual(window.frame.size.height, 800, "Window height should be updated")
            
            // Test focus
            try window.focus()
            XCTAssertTrue(window.isFocused, "Window should be focused after focus() method")
        } catch {
            XCTFail("Window operations should not throw error: \(error)")
        }
    }
    
    func testKeyboardInput() {
        // Test keyboard input simulation
        do {
            // Test throwing version
            try KeyboardInput.typeString("Hello, World!")
            
            // Test non-throwing version
            let success = KeyboardInput.typeStringNoThrow("Hello, World!")
            XCTAssertTrue(success, "Non-throwing version should return true")
        } catch {
            XCTFail("Keyboard input should not throw error: \(error)")
        }
        
        // Test key combination
        do {
            // Test throwing version
            try KeyboardInput.pressKeyCombination([.command, .option], key: "c")
            
            // Test non-throwing version
            let success = KeyboardInput.pressKeyCombinationNoThrow([.command, .option], key: "c")
            XCTAssertTrue(success, "Non-throwing version should return true")
        } catch {
            XCTFail("Key combination should not throw error: \(error)")
        }
    }
    
    func testElementActionDiscovery() {
        // Test discovering available actions on elements
        let button = MockButtonElement(title: "OK")
        let textField = MockTextFieldElement(title: "Name", value: "Text")
        
        do {
            let buttonActions = try button.getAvailableActions()
            XCTAssertTrue(buttonActions.contains("press"), "Button should support press action")
            
            let textFieldActions = try textField.getAvailableActions()
            XCTAssertTrue(textFieldActions.contains("setValue"), "TextField should support setValue action")
        } catch {
            XCTFail("Getting available actions should not throw error: \(error)")
        }
    }
    
    func testErrorHandlingForInvalidAction() {
        // Test that performing an invalid action throws the correct error
        let button = MockButtonElement(title: "OK")
        
        do {
            try button.performAction("invalidAction")
            XCTFail("Performing invalid action should throw error")
        } catch let error as UIElementError {
            XCTAssertEqual(error.errorCode, ErrorCode.elementDoesNotSupportAction.rawValue)
            XCTAssertTrue(error.description.contains("invalidAction"), "Error should mention the invalid action")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    static var allTests = [
        ("testButtonInteraction", testButtonInteraction),
        ("testTextFieldInteraction", testTextFieldInteraction),
        ("testWindowManipulation", testWindowManipulation),
        ("testKeyboardInput", testKeyboardInput),
        ("testElementActionDiscovery", testElementActionDiscovery),
        ("testErrorHandlingForInvalidAction", testErrorHandlingForInvalidAction)
    ]
}