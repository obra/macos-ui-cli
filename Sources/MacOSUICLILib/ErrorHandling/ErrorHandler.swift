// ABOUTME: This file implements centralized error handling for the application.
// ABOUTME: It provides a way to handle and report errors with proper formatting.

import Foundation

/// Centralized handler for application errors
public class ErrorHandler {
    /// Shared instance of the error handler
    public static let shared = ErrorHandler()
    
    /// The debug logger
    private let logger = DebugLogger.shared
    
    /// The formatter to use for error messages
    private var formatter: OutputFormatter?
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Set default logging level
        #if DEBUG
        logger.logLevel = .debug
        #else
        logger.logLevel = .error
        #endif
    }
    
    /// Sets the formatter to use for error messages
    /// - Parameter formatter: The formatter to use
    public func setFormatter(_ formatter: OutputFormatter) {
        self.formatter = formatter
        logger.setFormatter(formatter)
    }
    
    /// Handles an error and returns a formatted error message
    /// - Parameters:
    ///   - error: The error to handle
    ///   - file: The file where the error occurred
    ///   - function: The function where the error occurred
    ///   - line: The line where the error occurred
    /// - Returns: A formatted error message
    public func handle(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> String {
        // Log the error
        logger.logError(error, file: file, function: function, line: line)
        
        // Return a formatted error message
        if let formatter = formatter {
            return formatter.formatError(error)
        } else {
            // Fallback if no formatter is available
            return "Error: \(error.localizedDescription)"
        }
    }
    
    /// Handles an error, prints it to the console, and exits with a non-zero status code
    /// - Parameters:
    ///   - error: The error to handle
    ///   - exitCode: The exit code to use
    ///   - file: The file where the error occurred
    ///   - function: The function where the error occurred
    ///   - line: The line where the error occurred
    public func handleFatal(
        _ error: Error,
        exitCode: Int32 = 1,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Never {
        // Log the error
        logger.logError(error, file: file, function: function, line: line)
        
        // Print the error to the console
        if let formatter = formatter {
            print(formatter.formatError(error))
        } else {
            // Fallback if no formatter is available
            print("Fatal Error: \(error.localizedDescription)")
            
            // Print additional information for ApplicationError types
            if let appError = error as? ApplicationError {
                print("Error Code: \(appError.errorCode)")
                print("Recovery Suggestion: \(appError.recoverySuggestion)")
                if let debugInfo = appError.debugInfo {
                    print("Debug Info: \(debugInfo)")
                }
            }
        }
        
        // Exit with a non-zero status code
        exit(exitCode)
    }
    
    /// Attempt to run an operation that might throw and handle any errors
    /// - Parameters:
    ///   - operation: The operation to run
    ///   - errorHandler: A closure to handle any errors
    /// - Returns: The result of the operation if successful, nil otherwise
    public func attempt<T>(
        _ operation: () throws -> T,
        errorHandler: ((Error) -> Void)? = nil
    ) -> T? {
        do {
            return try operation()
        } catch {
            if let handler = errorHandler {
                handler(error)
            } else {
                print(handle(error))
            }
            return nil
        }
    }
}