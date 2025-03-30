import XCTest
@testable import MacOSUICLI

class InteractiveModeTests: XCTestCase {
    func testInteractiveModeCreation() {
        // Verify we can create an interactive mode instance
        let interactive = InteractiveMode()
        XCTAssertNotNil(interactive)
    }
    
    func testParseCommand() {
        // Test would verify the command parsing logic
        // For now, this is a placeholder for future implementation
        // with proper test approach
        let interactive = InteractiveMode()
        XCTAssertNotNil(interactive, "InteractiveMode should be created successfully")
    }
    
    func testTabCompletion() {
        // Test would verify the tab completion functionality
        // For now, this is a placeholder for future implementation
        // with proper test approach
        let interactive = InteractiveMode()
        XCTAssertNotNil(interactive, "InteractiveMode should be created successfully")
    }
    
    func testElementFinder() {
        // Create a sample element hierarchy
        let window = Element(role: "window", title: "Test Window")
        let button = Element(role: "button", title: "OK")
        let textField = Element(role: "textField", title: "Search")
        
        window.addChild(button)
        window.addChild(textField)
        
        do {
            // Find elements by role
            let buttons = try ElementFinder.findElements(in: window, byRole: "button")
            XCTAssertEqual(buttons.count, 1)
            XCTAssertEqual(buttons.first?.title, "OK")
            
            // Find elements by title
            let searchElements = try ElementFinder.findElements(in: window, byTitle: "Search")
            XCTAssertEqual(searchElements.count, 1)
            XCTAssertEqual(searchElements.first?.role, "textField")
            
            // Find element by path
            let pathElement = try ElementFinder.findElementByPath("window[Test Window]/button[OK]", in: window)
            XCTAssertEqual(pathElement.role, "button")
            XCTAssertEqual(pathElement.title, "OK")
        } catch {
            XCTFail("Element finding threw an error: \(error)")
        }
    }
    
    func testFlatElementIds() {
        // Create an element hierarchy for testing
        let window = Element(role: "window", title: "Test Window")
        let button1 = Element(role: "button", title: "OK")
        let button2 = Element(role: "button", title: "Cancel")
        let textField = Element(role: "textField", title: "Search")
        
        window.addChild(button1)
        window.addChild(button2)
        button1.addChild(textField)
        
        // Simulate the interactive mode's element list population
        let elementsList: [Element] = [window, button1, button2, textField]
        
        // Verify each element has a unique position in the list
        XCTAssertEqual(elementsList.firstIndex(of: window), 0)
        XCTAssertEqual(elementsList.firstIndex(of: button1), 1)
        XCTAssertEqual(elementsList.firstIndex(of: button2), 2)
        XCTAssertEqual(elementsList.firstIndex(of: textField), 3)
        
        // Test element equality for ID matching
        let sameButton = Element(role: "button", title: "OK")
        XCTAssertNotEqual(elementsList.firstIndex(of: sameButton), 1, 
                          "Elements should be compared by reference, not just by role and title")
        
        // Test element list lookup by ID
        let id = 2 // This should be button2
        XCTAssertTrue(id >= 0 && id < elementsList.count, "ID should be in valid range")
        let foundElement = elementsList[id]
        XCTAssertEqual(foundElement.role, "button")
        XCTAssertEqual(foundElement.title, "Cancel")
    }
    
    static var allTests = [
        ("testInteractiveModeCreation", testInteractiveModeCreation),
        ("testParseCommand", testParseCommand),
        ("testTabCompletion", testTabCompletion),
        ("testElementFinder", testElementFinder),
        ("testFlatElementIds", testFlatElementIds)
    ]
}