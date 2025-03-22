// ABOUTME: This file is the entry point for running tests on Linux platforms.
// ABOUTME: It imports test manifests and runs all registered tests.

import XCTest

import MacOSUICLITests

var tests = [XCTestCaseEntry]()
tests += MacOSUICLITests.allTests()
XCTMain(tests)