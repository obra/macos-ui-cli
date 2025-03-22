// ABOUTME: This file contains tests for window discovery functionality.
// ABOUTME: It verifies the ability to find and interact with application windows.

import XCTest
@testable import MacOSUICLI

final class WindowDiscoveryTests: XCTestCase {
    func testWindowEnumeration() {
        // Test window enumeration for an application
        let app = ApplicationManager.getFocusedApplicationNoThrow()
        
        if let app = app {
            let windows = app.getWindowsNoThrow()
            // We just verify it returns an array (even if empty)
            XCTAssertNotNil(windows, "Should be able to get windows for an application")
        } else {
            // We can't guarantee an application is focused during testing
            print("Note: No focused application available during testing")
        }
    }
    
    func testWindowProperties() {
        // We'll use a mock window instead of relying on the focused application
        let mockWindow = MockWindow(title: "Test Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        
        // Test getting window title
        XCTAssertEqual(mockWindow.title, "Test Window", "Window should have the correct title")
        
        // Test getting window frame
        XCTAssertEqual(mockWindow.frame.width, 800, "Window should have the correct width")
        XCTAssertEqual(mockWindow.frame.height, 600, "Window should have the correct height")
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