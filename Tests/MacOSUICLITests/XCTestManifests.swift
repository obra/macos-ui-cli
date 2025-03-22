// ABOUTME: This file defines the test manifest for the MacOSUICLI tests.
// ABOUTME: It ensures all test cases are registered and discoverable.

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MacOSUICLITests.allTests),
        testCase(AccessibilityPermissionsTests.allTests),
        testCase(ApplicationAccessTests.allTests),
        testCase(WindowDiscoveryTests.allTests),
        testCase(ElementDiscoveryTests.allTests),
        testCase(UIInteractionTests.allTests),
        testCase(CommandStructureTests.allTests),
        testCase(OutputFormattingTests.allTests),
        testCase(ErrorHandlingTests.allTests)
    ]
}
#endif