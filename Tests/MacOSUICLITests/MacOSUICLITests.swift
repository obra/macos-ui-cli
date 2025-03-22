// ABOUTME: This file contains unit tests for the MacOSUICLI application.
// ABOUTME: It tests core functionality and command-line argument parsing.

import XCTest
import ArgumentParser
@testable import MacOSUICLI
@testable import Haxcessibility

final class MacOSUICLITests: XCTestCase {
    func testVersionFlag() throws {
        // Test the version flag
        XCTAssertEqual(MacOSUICLI.configuration.version, "0.2.0")
    }
    
    func testHaxcessibilityAvailability() throws {
        // This test verifies that the Haxcessibility module is available
        let available = SystemAccessibility.isAvailable()
        XCTAssertTrue(available, "Haxcessibility should be available")
        
        // Verify that we can create a HAXSystem object
        let system = HAXSystem()
        XCTAssertNotNil(system, "Should be able to create a HAXSystem instance")
    }
    
    static var allTests = [
        ("testVersionFlag", testVersionFlag),
        ("testHaxcessibilityAvailability", testHaxcessibilityAvailability)
    ]
}