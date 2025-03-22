// ABOUTME: Tests for the output formatting functionality.
// ABOUTME: Validates different output formats and formatting options.

import XCTest
@testable import MacOSUICLI

final class OutputFormattingTests: XCTestCase {
    
    // Formatter creation tests
    func testCreatePlainTextFormatter() {
        let formatter = FormatterFactory.create(format: .plainText)
        XCTAssertTrue(formatter is PlainTextFormatter)
    }
    
    func testCreateJSONFormatter() {
        let formatter = FormatterFactory.create(format: .json)
        XCTAssertTrue(formatter is JSONFormatter)
    }
    
    func testCreateXMLFormatter() {
        let formatter = FormatterFactory.create(format: .xml)
        XCTAssertTrue(formatter is XMLFormatter)
    }
    
    // Basic message formatting tests
    func testMessageFormatting() {
        let formatter = FormatterFactory.create(format: .plainText)
        
        let infoMsg = formatter.formatMessage("Info message", type: .info)
        XCTAssertTrue(infoMsg.contains("Info message"))
        
        let successMsg = formatter.formatMessage("Success message", type: .success)
        XCTAssertTrue(successMsg.contains("Success message"))
        
        let warningMsg = formatter.formatMessage("Warning message", type: .warning)
        XCTAssertTrue(warningMsg.contains("Warning message"))
        
        let errorMsg = formatter.formatMessage("Error message", type: .error)
        XCTAssertTrue(errorMsg.contains("Error message"))
    }
    
    // Output format tests for applications
    func testApplicationsPlainTextOutput() {
        let apps = [
            Application(mockWithName: "Safari", pid: 123),
            Application(mockWithName: "Notes", pid: 456)
        ]
        
        let formatter = FormatterFactory.create(format: .plainText)
        let output = formatter.formatApplications(apps)
        
        XCTAssertTrue(output.contains("Safari"))
        XCTAssertTrue(output.contains("123"))
        XCTAssertTrue(output.contains("Notes"))
        XCTAssertTrue(output.contains("456"))
    }
    
    // Error formatting test
    func testErrorFormatting() {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { return "Test error message" }
        }
        
        let formatter = FormatterFactory.create(format: .plainText)
        let output = formatter.formatError(TestError())
        
        XCTAssertTrue(output.contains("Test error message"))
    }
    
    // Test command response formatting
    func testCommandResponseFormatting() {
        let formatter = FormatterFactory.create(format: .plainText)
        
        let successOutput = formatter.formatCommandResponse("Command succeeded", success: true)
        XCTAssertTrue(successOutput.contains("Command succeeded"))
        
        let failureOutput = formatter.formatCommandResponse("Command failed", success: false)
        XCTAssertTrue(failureOutput.contains("Command failed"))
    }
    
    // MARK: - Test single element formatting
    
    func testElementFormatting() {
        let element = Element(role: "button", title: "OK")
        
        let formatter = FormatterFactory.create(format: .plainText)
        let output = formatter.formatElement(element)
        
        XCTAssertTrue(output.contains("button"))
        XCTAssertTrue(output.contains("OK"))
    }
    
    // MARK: - Test output format options
    
    func testFormatterFactoryOptions() {
        let formatter1 = FormatterFactory.create(format: .plainText, verbosity: .minimal, colorized: false)
        XCTAssertTrue(formatter1 is PlainTextFormatter)
        
        let formatter2 = FormatterFactory.create(format: .json, verbosity: .detailed, colorized: true)
        XCTAssertTrue(formatter2 is JSONFormatter)
        
        // The plain text formatter should store its colorized option
        let plainTextFormatter = FormatterFactory.create(format: .plainText, colorized: true) as! PlainTextFormatter
        XCTAssertTrue(plainTextFormatter.colorized)
    }
    
    // MARK: - Test output format conversion
    
    func testOutputFormatFromString() {
        XCTAssertEqual(OutputFormat.fromString("text"), .plainText)
        XCTAssertEqual(OutputFormat.fromString("json"), .json)
        XCTAssertEqual(OutputFormat.fromString("xml"), .xml)
        
        // Should default to plainText for unknown formats
        XCTAssertEqual(OutputFormat.fromString("unknown"), .plainText)
    }
    
    // MARK: - Test verbosity levels
    
    func testVerbosityLevelFromInt() {
        XCTAssertEqual(VerbosityLevel.fromInt(0), .minimal)
        XCTAssertEqual(VerbosityLevel.fromInt(1), .normal)
        XCTAssertEqual(VerbosityLevel.fromInt(2), .detailed)
        XCTAssertEqual(VerbosityLevel.fromInt(3), .debug)
        
        // Should default to normal for out of range values
        XCTAssertEqual(VerbosityLevel.fromInt(-1), .normal)
        XCTAssertEqual(VerbosityLevel.fromInt(4), .normal)
    }
    
    // MARK: - Test formatting singleton
    
    func testFormattingOptionsSingleton() {
        let options = FormattingOptions.shared
        
        // Default values
        XCTAssertEqual(options.format, .plainText)
        XCTAssertEqual(options.verbosity, .normal)
        XCTAssertFalse(options.colorized)
        
        // Update values
        options.format = .json
        options.verbosity = .detailed
        options.colorized = true
        
        // Check updated values
        XCTAssertEqual(options.format, .json)
        XCTAssertEqual(options.verbosity, .detailed)
        XCTAssertTrue(options.colorized)
        
        // Create formatter from settings
        let formatter = options.createFormatter()
        XCTAssertTrue(formatter is ErrorFormattingDecorator)
        
        // Reset for other tests
        options.format = .plainText
        options.verbosity = .normal
        options.colorized = false
    }
    
    // MARK: - Test global options
    
    func testGlobalOptionsUpdate() {
        var globalOptions = GlobalOptions()
        globalOptions.format = "json"
        globalOptions.verbosity = 2
        globalOptions.color = true
        
        let options = FormattingOptions.shared
        options.update(from: globalOptions)
        
        XCTAssertEqual(options.format, .json)
        XCTAssertEqual(options.verbosity, .detailed)
        XCTAssertTrue(options.colorized)
        
        // Reset for other tests
        options.format = .plainText
        options.verbosity = .normal
        options.colorized = false
    }
    
    static var allTests = [
        ("testCreatePlainTextFormatter", testCreatePlainTextFormatter),
        ("testCreateJSONFormatter", testCreateJSONFormatter),
        ("testCreateXMLFormatter", testCreateXMLFormatter),
        ("testMessageFormatting", testMessageFormatting),
        ("testApplicationsPlainTextOutput", testApplicationsPlainTextOutput),
        ("testErrorFormatting", testErrorFormatting),
        ("testCommandResponseFormatting", testCommandResponseFormatting),
        ("testElementFormatting", testElementFormatting),
        ("testFormatterFactoryOptions", testFormatterFactoryOptions),
        ("testOutputFormatFromString", testOutputFormatFromString),
        ("testVerbosityLevelFromInt", testVerbosityLevelFromInt),
        ("testFormattingOptionsSingleton", testFormattingOptionsSingleton),
        ("testGlobalOptionsUpdate", testGlobalOptionsUpdate)
    ]
}