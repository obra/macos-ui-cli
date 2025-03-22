// ABOUTME: This file provides utilities for handling timeouts and retries.
// ABOUTME: It implements mechanisms to prevent operations from hanging and retry flaky operations.

import Foundation

/// Executes a block with a timeout
/// - Parameters:
///   - seconds: The timeout in seconds
///   - operation: The block to execute
/// - Throws: OperationError.timeout if the operation times out
public func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () throws -> T) throws -> T {
    // Validate the timeout value
    try Validation.validateTimeout(seconds)
    
    // Create a dispatch group to wait for the operation
    let group = DispatchGroup()
    group.enter()
    
    // Variables to hold the result or error
    var result: T?
    var operationError: Error?
    
    // Create a concurrent queue for the operation
    let queue = DispatchQueue(label: "com.macosuicli.timeout", attributes: .concurrent)
    
    // Run the operation on the queue
    queue.async {
        do {
            result = try operation()
        } catch {
            operationError = error
        }
        group.leave()
    }
    
    // Wait for the operation to complete with a timeout
    let waitResult = group.wait(timeout: .now() + seconds)
    
    // Check the result of the wait
    switch waitResult {
    case .success:
        // Operation completed within timeout
        if let error = operationError {
            throw error
        }
        if let value = result {
            return value
        }
        // This should never happen if the operation completed successfully
        throw OperationError.failed(operation: "Timeout operation", reason: "Operation completed but produced no result")
        
    case .timedOut:
        // Operation timed out
        throw OperationError.timeout(operation: "Operation", duration: seconds)
    }
}

/// Executes a block with retry logic
/// - Parameters:
///   - maxAttempts: Maximum number of attempts
///   - delay: Delay between retries in seconds
///   - operation: The block to execute
/// - Throws: The last error encountered if all attempts fail
public func withRetry(maxAttempts: Int = 3, delay: TimeInterval = 1.0, operation: @escaping () throws -> Void) throws {
    // Validate the retry parameters
    try Validation.validateRetryCount(maxAttempts)
    try Validation.validateRetryDelay(delay)
    
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            try operation()
            return // Success, exit the function
        } catch {
            lastError = error
            
            // Log the failure but continue if we have more attempts
            if attempt < maxAttempts {
                NSLog("Attempt \(attempt) failed: \(error.localizedDescription). Retrying in \(delay) seconds...")
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }
    
    // If we get here, all attempts failed
    if let error = lastError {
        throw error
    } else {
        // This should never happen if the operation failed
        throw OperationError.failed(operation: "Retry operation", reason: "All attempts failed but no error was captured")
    }
}

/// Executes a block with both timeout and retry logic
/// - Parameters:
///   - timeout: The timeout for each attempt in seconds
///   - maxAttempts: Maximum number of retry attempts
///   - delay: Delay between retries in seconds
///   - operation: The block to execute
/// - Throws: OperationError if the operation fails after all retries
public func withTimeoutAndRetry<T>(
    timeout: TimeInterval = 10.0,
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: @escaping () throws -> T
) throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            // Execute the operation with a timeout
            return try withTimeout(timeout) {
                try operation()
            }
        } catch {
            lastError = error
            
            // Log the failure but continue if we have more attempts
            if attempt < maxAttempts {
                NSLog("Attempt \(attempt) failed: \(error.localizedDescription). Retrying in \(delay) seconds...")
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }
    
    // If we get here, all attempts failed
    if let error = lastError {
        if let operationError = error as? OperationError {
            return try { throw operationError }()
        } else {
            throw OperationError.failed(
                operation: "Operation with timeout and retry",
                reason: error.localizedDescription
            )
        }
    } else {
        // This should never happen if the operation failed
        throw OperationError.failed(
            operation: "Operation with timeout and retry",
            reason: "All attempts failed but no error was captured"
        )
    }
}