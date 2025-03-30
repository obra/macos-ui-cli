// ABOUTME: This file contains isolated tests for error handling functionality.
// ABOUTME: It verifies that the core error handling functions work correctly.

import Foundation
import MacOSUICLI

// Test error handling without other dependencies
final class IsolatedErrorHandlingTests {
    // Test that our error types can be properly created and contain the right information
    static func testErrorTypeCreation() {
        // Test AccessibilityError
        let permissionError = AccessibilityError.permissionDenied
        assert(permissionError.errorCode == ErrorCode.permissionDenied.rawValue)
        assert(!permissionError.localizedDescription.isEmpty)
        
        // Test UIElementError
        let elementNotFoundError = UIElementError.elementNotFound(description: "Button with title 'OK'")
        assert(elementNotFoundError.errorCode == ErrorCode.elementNotFound.rawValue)
        assert(elementNotFoundError.localizedDescription.contains("Button with title 'OK'"))
        
        // Test OperationError
        let timeoutError = OperationError.timeout(operation: "Click button", duration: 5.0)
        assert(timeoutError.errorCode == ErrorCode.operationTimeout.rawValue)
        assert(timeoutError.localizedDescription.contains("5.0 seconds"))
    }
    
    // Test the timeout mechanism works correctly
    static func testTimeoutMechanism() {
        var didTimeout = false
        
        do {
            try withTimeout(0.1) {
                // Simulate a long-running operation
                Thread.sleep(forTimeInterval: 0.5)
            }
            assert(false, "Should have timed out")
        } catch let error as OperationError {
            assert(error.errorCode == ErrorCode.operationTimeout.rawValue)
            didTimeout = true
        } catch {
            assert(false, "Unexpected error: \(error)")
        }
        
        assert(didTimeout, "Operation should have timed out")
    }
    
    // Test retry mechanism for operations
    static func testRetryMechanism() {
        var attempts = 0
        
        do {
            // Try an operation that will succeed on the 3rd attempt
            try withRetry(maxAttempts: 5, delay: 0.05) {
                attempts += 1
                if attempts < 3 {
                    throw OperationError.failed(operation: "Test operation", reason: "Simulated failure")
                }
            }
            assert(attempts == 3, "Should have succeeded on the 3rd attempt")
        } catch {
            assert(false, "Should not have failed: \(error)")
        }
        
        // Reset and test a failing operation
        attempts = 0
        var didFail = false
        
        do {
            try withRetry(maxAttempts: 2, delay: 0.05) {
                attempts += 1
                throw OperationError.failed(operation: "Test operation", reason: "Simulated failure")
            }
            assert(false, "Should have failed")
        } catch let error as OperationError {
            assert(attempts == 2, "Should have attempted exactly 2 times")
            assert(error.errorCode == ErrorCode.operationFailed.rawValue)
            didFail = true
        } catch {
            assert(false, "Unexpected error: \(error)")
        }
        
        assert(didFail, "Operation should have failed")
    }
    
    // Test validation mechanisms
    static func testArgumentValidation() {
        // Test valid application name
        do {
            try Validation.validateApplicationName("Safari")
        } catch {
            assert(false, "Should not throw for valid name")
        }
        
        // Test empty application name
        var didThrowValidationError = false
        do {
            try Validation.validateApplicationName("")
            assert(false, "Should throw for empty name")
        } catch let error as ValidationError {
            assert(error.errorCode == ErrorCode.invalidArgument.rawValue)
            didThrowValidationError = true
        } catch {
            assert(false, "Unexpected error type: \(error)")
        }
        
        assert(didThrowValidationError, "Should have thrown validation error")
        
        // Test valid timeout value
        do {
            try Validation.validateTimeout(5.0)
        } catch {
            assert(false, "Should not throw for valid timeout")
        }
        
        // Test negative timeout value
        didThrowValidationError = false
        do {
            try Validation.validateTimeout(-1.0)
            assert(false, "Should throw for negative timeout")
        } catch let error as ValidationError {
            assert(error.errorCode == ErrorCode.invalidArgument.rawValue)
            didThrowValidationError = true
        } catch {
            assert(false, "Unexpected error type: \(error)")
        }
        
        assert(didThrowValidationError, "Should have thrown validation error")
    }
    
    // Run all tests
    static func runAllTests() {
        print("Running error handling tests...")
        
        testErrorTypeCreation()
        print("✓ testErrorTypeCreation")
        
        testTimeoutMechanism()
        print("✓ testTimeoutMechanism")
        
        testRetryMechanism()
        print("✓ testRetryMechanism")
        
        testArgumentValidation()
        print("✓ testArgumentValidation")
        
        print("All error handling tests passed!")
    }
}

// Main entry point for the test
IsolatedErrorHandlingTests.runAllTests()