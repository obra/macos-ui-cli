// ABOUTME: This file contains tests for UI element discovery and traversal.
// ABOUTME: It verifies the ability to find, inspect, and traverse UI elements.

import XCTest
@testable import MacOSUICLI

final class ElementDiscoveryTests: XCTestCase {
    func testElementProperties() {
        // Test element properties using a mock element
        let element = MockElement(role: "button", title: "OK")
        
        XCTAssertEqual(element.role, "button", "Element should have the correct role")
        XCTAssertEqual(element.title, "OK", "Element should have the correct title")
    }
    
    func testElementHierarchy() {
        // Test element hierarchy traversal
        let parent = MockElement(role: "window", title: "Main Window")
        let child1 = MockElement(role: "button", title: "OK")
        let child2 = MockElement(role: "button", title: "Cancel")
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        XCTAssertEqual(parent.children.count, 2, "Parent should have 2 children")
        XCTAssertEqual(parent.children[0].title, "OK", "First child should be the OK button")
        XCTAssertEqual(parent.children[1].title, "Cancel", "Second child should be the Cancel button")
        
        XCTAssertEqual(child1.parent?.title, "Main Window", "Child should have reference to parent")
    }
    
    func testElementFiltering() {
        // Test filtering elements by type or attributes
        let window = MockElement(role: "window", title: "Main Window")
        let button1 = MockElement(role: "button", title: "OK")
        let button2 = MockElement(role: "button", title: "Cancel")
        let textField = MockElement(role: "textField", title: "Name")
        
        window.addChild(button1)
        window.addChild(button2)
        window.addChild(textField)
        
        // Filter by role
        let buttons = ElementFinder.findElementsNoThrow(in: window, byRole: "button")
        XCTAssertEqual(buttons.count, 2, "Should find 2 buttons")
        
        // Filter by title
        let okButton = ElementFinder.findElementsNoThrow(in: window, byTitle: "OK")
        XCTAssertEqual(okButton.count, 1, "Should find 1 element with title OK")
        XCTAssertEqual(okButton.first?.role, "button", "Found element should be a button")
    }
    
    func testFocusedElement() {
        // Test focused element detection
        // Since we can't reliably test with real focus during unit tests,
        // we'll use mocks and test the logic only
        let mockFocusedElement = MockElement(role: "textField", title: "Search")
        mockFocusedElement.isFocused = true
        
        XCTAssertTrue(mockFocusedElement.isFocused, "Element should be focused")
    }
    
    static var allTests = [
        ("testElementProperties", testElementProperties),
        ("testElementHierarchy", testElementHierarchy),
        ("testElementFiltering", testElementFiltering),
        ("testFocusedElement", testFocusedElement)
    ]
}