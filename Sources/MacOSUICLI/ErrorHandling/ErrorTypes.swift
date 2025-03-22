// ABOUTME: This file defines the error types for different error categories.
// ABOUTME: It provides structured error types with description, codes, and recovery suggestions.

import Foundation

/// Protocol for all application errors
public protocol ApplicationError: Error, CustomStringConvertible {
    /// The error code
    var errorCode: Int { get }
    
    /// A suggestion for recovering from this error
    var recoverySuggestion: String { get }
    
    /// Additional debug information (if available)
    var debugInfo: String? { get }
}

/// Accessibility-related errors
public enum AccessibilityError: ApplicationError {
    case accessibilityNotEnabled
    case permissionDenied
    case apiMisuse(description: String)
    
    public var errorCode: Int {
        switch self {
        case .accessibilityNotEnabled:
            return ErrorCode.accessibilityNotEnabled.rawValue
        case .permissionDenied:
            return ErrorCode.permissionDenied.rawValue
        case .apiMisuse:
            return ErrorCode.apiMisuse.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .accessibilityNotEnabled:
            return "Accessibility is not enabled"
        case .permissionDenied:
            return "Permission denied for accessibility access"
        case .apiMisuse(let description):
            return "Accessibility API misuse: \(description)"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .accessibilityNotEnabled:
            return "Enable accessibility in System Preferences → Security & Privacy → Privacy → Accessibility"
        case .permissionDenied:
            return "Grant permission for this application in System Preferences → Security & Privacy → Privacy → Accessibility"
        case .apiMisuse:
            return "This is a programming error. Please report this issue to the developers."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// UI Element-related errors
public enum UIElementError: ApplicationError {
    case elementNotFound(description: String)
    case elementNotVisible(description: String)
    case elementNotEnabled(description: String)
    case invalidElementState(description: String, state: String)
    case elementDoesNotSupportAction(description: String, action: String)
    
    public var errorCode: Int {
        switch self {
        case .elementNotFound:
            return ErrorCode.elementNotFound.rawValue
        case .elementNotVisible:
            return ErrorCode.elementNotVisible.rawValue
        case .elementNotEnabled:
            return ErrorCode.elementNotEnabled.rawValue
        case .invalidElementState:
            return ErrorCode.invalidElementState.rawValue
        case .elementDoesNotSupportAction:
            return ErrorCode.elementDoesNotSupportAction.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .elementNotFound(let description):
            return "UI Element not found: \(description)"
        case .elementNotVisible(let description):
            return "UI Element not visible: \(description)"
        case .elementNotEnabled(let description):
            return "UI Element not enabled: \(description)"
        case .invalidElementState(let description, let state):
            return "UI Element '\(description)' in invalid state: \(state)"
        case .elementDoesNotSupportAction(let description, let action):
            return "UI Element '\(description)' does not support action: \(action)"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .elementNotFound:
            return "Make sure the element exists and is correctly identified. Try using a different identifier or accessibility role."
        case .elementNotVisible:
            return "Make sure the element is visible on screen. It might be scrolled out of view or hidden."
        case .elementNotEnabled:
            return "The element is disabled and cannot be interacted with. Wait for the application to enable it."
        case .invalidElementState:
            return "The element is in a state that prevents the requested operation. Check the application's current state."
        case .elementDoesNotSupportAction:
            return "This type of element does not support the requested action. Try a different approach."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// Operation-related errors
public enum OperationError: ApplicationError {
    case timeout(operation: String, duration: TimeInterval)
    case failed(operation: String, reason: String)
    case notSupported(operation: String)
    case cancelled(operation: String)
    
    public var errorCode: Int {
        switch self {
        case .timeout:
            return ErrorCode.operationTimeout.rawValue
        case .failed:
            return ErrorCode.operationFailed.rawValue
        case .notSupported:
            return ErrorCode.operationNotSupported.rawValue
        case .cancelled:
            return ErrorCode.operationCancelled.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .timeout(let operation, let duration):
            return "Operation '\(operation)' timed out after \(duration) seconds"
        case .failed(let operation, let reason):
            return "Operation '\(operation)' failed: \(reason)"
        case .notSupported(let operation):
            return "Operation '\(operation)' is not supported"
        case .cancelled(let operation):
            return "Operation '\(operation)' was cancelled"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .timeout:
            return "Try increasing the timeout duration or check if the application is responding correctly."
        case .failed:
            return "Check the error details for specific issues that caused the failure."
        case .notSupported:
            return "This operation is not supported for this type of element or application."
        case .cancelled:
            return "The operation was cancelled. You can try again if needed."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// Application-specific errors
public enum ApplicationManagerError: ApplicationError {
    case applicationNotFound(description: String)
    case applicationNotResponding(name: String)
    case applicationCrashed(name: String, pid: Int32?)
    
    public var errorCode: Int {
        switch self {
        case .applicationNotFound:
            return ErrorCode.applicationNotFound.rawValue
        case .applicationNotResponding:
            return ErrorCode.applicationNotResponding.rawValue
        case .applicationCrashed:
            return ErrorCode.applicationCrashed.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .applicationNotFound(let description):
            return "Application not found: \(description)"
        case .applicationNotResponding(let name):
            return "Application '\(name)' is not responding"
        case .applicationCrashed(let name, let pid):
            if let pid = pid {
                return "Application '\(name)' (PID: \(pid)) has crashed"
            } else {
                return "Application '\(name)' has crashed"
            }
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .applicationNotFound:
            return "Make sure the application is running and the name or PID is correct."
        case .applicationNotResponding:
            return "The application may be busy or hung. Try waiting or force-quitting the application and starting it again."
        case .applicationCrashed:
            return "The application has crashed. Try launching it again and check for any error reports."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// Window-related errors
public enum WindowError: ApplicationError {
    case windowNotFound(description: String)
    case windowNotResponding(description: String)
    
    public var errorCode: Int {
        switch self {
        case .windowNotFound:
            return ErrorCode.windowNotFound.rawValue
        case .windowNotResponding:
            return ErrorCode.windowNotResponding.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .windowNotFound(let description):
            return "Window not found: \(description)"
        case .windowNotResponding(let description):
            return "Window not responding: \(description)"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .windowNotFound:
            return "Make sure the window exists and is correctly identified. The window might be closed or in a different state."
        case .windowNotResponding:
            return "The window is not responding to commands. The application may be busy or frozen."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// Input-related errors
public enum InputError: ApplicationError {
    case keyboardInputFailed(key: String, reason: String)
    case mouseInputFailed(action: String, reason: String)
    
    public var errorCode: Int {
        switch self {
        case .keyboardInputFailed:
            return ErrorCode.keyboardInputFailed.rawValue
        case .mouseInputFailed:
            return ErrorCode.mouseInputFailed.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .keyboardInputFailed(let key, let reason):
            return "Keyboard input failed for key '\(key)': \(reason)"
        case .mouseInputFailed(let action, let reason):
            return "Mouse input failed for action '\(action)': \(reason)"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .keyboardInputFailed:
            return "Check that the target application has focus and is accepting keyboard input."
        case .mouseInputFailed:
            return "Ensure the mouse coordinates are within the visible screen area and the element can receive mouse events."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}

/// Validation-related errors
public enum ValidationError: ApplicationError {
    case invalidArgument(name: String, reason: String)
    
    public var errorCode: Int {
        return ErrorCode.invalidArgument.rawValue
    }
    
    public var description: String {
        switch self {
        case .invalidArgument(let name, let reason):
            return "Invalid argument '\(name)': \(reason)"
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .invalidArgument:
            return "Check the command usage and provide a valid value for this argument."
        }
    }
    
    public var debugInfo: String? {
        return nil
    }
}