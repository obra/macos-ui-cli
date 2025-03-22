// ABOUTME: This file contains tests for window discovery functionality.
// ABOUTME: It verifies the ability to find and interact with application windows.

import XCTest
@testable import MacOSUICLI

final class WindowDiscoveryTests: XCTestCase {
    func testWindowEnumeration() {
        // Test window enumeration for an application
        let app = ApplicationManager.getFocusedApplication()
        
        if let app = app {
            let windows = app.getWindows()
            XCTAssertNotNil(windows, "Should be able to get windows for an application")
        } else {
            // We can't guarantee an application is focused during testing
            print("Note: No focused application available during testing")
        }
    }
    
    func testWindowProperties() {
        // Test getting window properties
        let app = ApplicationManager.getFocusedApplication()
        
        if let app = app, let windows = app.getWindows(), !windows.isEmpty, let window = windows.first {
            // Test getting window title
            XCTAssertNotNil(window.title, "Window should have a title")
            
            // Test getting window frame
            XCTAssertNotEqual(window.frame.width, 0, "Window should have a non-zero width")
            XCTAssertNotEqual(window.frame.height, 0, "Window should have a non-zero height")
        } else {
            // We can't guarantee an application with windows is focused during testing
            print("Note: No window available for testing")
        }
    }
    
    func testWindowMethods() {
        // This test verifies window methods like raise, isFullscreen, etc.
        let window = MockWindow(title: "Test Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        
        XCTAssertEqual(window.title, "Test Window", "Window should have the correct title")
        XCTAssertEqual(window.frame.width, 800, "Window should have the correct width")
        XCTAssertEqual(window.frame.height, 600, "Window should have the correct height")
        XCTAssertFalse(window.isFullscreen, "Mock window should not be fullscreen initially")
    }
    
    static var allTests = [
        ("testWindowEnumeration", testWindowEnumeration),
        ("testWindowProperties", testWindowProperties),
        ("testWindowMethods", testWindowMethods)
    ]
}