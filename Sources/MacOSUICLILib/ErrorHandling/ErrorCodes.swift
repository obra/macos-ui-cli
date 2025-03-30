// ABOUTME: This file defines error codes used throughout the application.
// ABOUTME: It provides a central registry of error codes for consistent error reporting.

import Foundation

/// Error codes for all types of errors in the application
public enum ErrorCode: Int, Codable {
    // General errors (1-99)
    case unknown = 1
    case invalidArgument = 2
    case internalError = 3
    
    // Accessibility errors (100-199)
    case accessibilityNotEnabled = 100
    case permissionDenied = 101
    case apiMisuse = 102
    
    // UI Element errors (200-299)
    case elementNotFound = 200
    case elementNotVisible = 201
    case elementNotEnabled = 202
    case invalidElementState = 203
    case elementDoesNotSupportAction = 204
    
    // Operation errors (300-399)
    case operationTimeout = 300
    case operationFailed = 301
    case operationNotSupported = 302
    case operationCancelled = 303
    
    // Application errors (400-499)
    case applicationNotFound = 400
    case applicationNotResponding = 401
    case applicationCrashed = 402
    
    // Window errors (500-599)
    case windowNotFound = 500
    case windowNotResponding = 501
    
    // Input errors (600-699)
    case keyboardInputFailed = 600
    case mouseInputFailed = 601
}