// ABOUTME: This file defines the test manifest for the MacOSUICLI tests.
// ABOUTME: It ensures all test cases are registered and discoverable.

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MacOSUICLITests.allTests),
        testCase(AccessibilityPermissionsTests.allTests),
        testCase(ApplicationAccessTests.allTests)
    ]
}
#endif