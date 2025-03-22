// ABOUTME: This file contains tests for application discovery and access.
// ABOUTME: It verifies the functionality for finding and connecting to applications.

import XCTest
@testable import MacOSUICLI

final class ApplicationAccessTests: XCTestCase {
    func testFocusedApplication() {
        // This test verifies that we can get the currently focused application
        let app = ApplicationManager.getFocusedApplication()
        // We're not asserting specific values as they depend on runtime state
        // but we can check that the function returns without crashing
        XCTAssertNotNil(app, "Should be able to get a reference to the focused application")
    }
    
    func testApplicationByPID() {
        // This test verifies that we can get application by PID
        let nonExistentPID: Int32 = 999999 // Unlikely to be a valid PID
        let app = ApplicationManager.getApplicationByPID(nonExistentPID)
        
        // We expect this to be nil since we're using a non-existent PID
        XCTAssertNil(app, "Application with non-existent PID should return nil")
    }
    
    func testApplicationByName() {
        // This test verifies that we can get application by name
        let nonExistentName = "NonExistentApplicationName"
        let app = ApplicationManager.getApplicationByName(nonExistentName)
        
        // We expect this to be nil since we're using a non-existent name
        XCTAssertNil(app, "Application with non-existent name should return nil")
    }
    
    func testApplicationProperties() {
        // This test verifies that we can get application properties
        let app = ApplicationManager.getFocusedApplication()
        
        if let app = app {
            // We should be able to get application name
            let name = app.name
            XCTAssertNotNil(name, "Application should have a name")
            
            // We should be able to get application PID
            let pid = app.pid
            XCTAssertGreaterThan(pid, 0, "Application should have a valid PID")
        } else {
            XCTFail("Should be able to get a reference to the focused application")
        }
    }
    
    static var allTests = [
        ("testFocusedApplication", testFocusedApplication),
        ("testApplicationByPID", testApplicationByPID),
        ("testApplicationByName", testApplicationByName),
        ("testApplicationProperties", testApplicationProperties)
    ]
}