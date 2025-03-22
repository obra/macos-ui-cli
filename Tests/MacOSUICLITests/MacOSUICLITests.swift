// ABOUTME: This file contains unit tests for the MacOSUICLI application.
// ABOUTME: It tests core functionality and command-line argument parsing.

import XCTest
import ArgumentParser
@testable import MacOSUICLI

final class MacOSUICLITests: XCTestCase {
    func testVersionFlag() throws {
        // Test the version flag
        XCTAssertEqual(MacOSUICLI.configuration.version, "0.1.0")
    }
    
    static var allTests = [
        ("testVersionFlag", testVersionFlag)
    ]
}