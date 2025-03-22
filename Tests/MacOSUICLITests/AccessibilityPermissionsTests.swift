// ABOUTME: This file contains tests for accessibility permissions and application access.
// ABOUTME: It verifies functions for checking permissions and connecting to applications.

import XCTest
@testable import MacOSUICLI

final class AccessibilityPermissionsTests: XCTestCase {
    func testPermissionChecking() {
        // This test verifies that we can check if accessibility permissions are granted
        let permissionStatus = AccessibilityPermissions.checkPermission()
        // We can't automatically verify the actual status, but we can verify the function doesn't crash
        XCTAssertNotNil(permissionStatus, "Permission check should return a status")
    }
    
    func testPermissionErrorHandling() {
        // This test verifies that we handle permission errors gracefully
        let error = AccessibilityPermissions.getPermissionError()
        // The error message should not be empty
        XCTAssertNotNil(error, "Permission error handler should return an error message")
    }
    
    static var allTests = [
        ("testPermissionChecking", testPermissionChecking),
        ("testPermissionErrorHandling", testPermissionErrorHandling)
    ]
}