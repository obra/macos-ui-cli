// ABOUTME: This file provides validation utilities for command arguments.
// ABOUTME: It ensures user inputs meet required criteria before processing.

import Foundation
import AppKit

/// Utilities for validating command arguments
public struct Validation {
    /// Validates an application name
    /// - Parameter name: The application name to validate
    /// - Throws: ValidationError if the name is invalid
    public static func validateApplicationName(_ name: String) throws {
        guard !name.isEmpty else {
            throw ValidationError.invalidArgument(
                name: "applicationName",
                reason: "Application name cannot be empty"
            )
        }
    }
    
    /// Validates a window title
    /// - Parameter title: The window title to validate
    /// - Throws: ValidationError if the title is invalid
    public static func validateWindowTitle(_ title: String) throws {
        guard !title.isEmpty else {
            throw ValidationError.invalidArgument(
                name: "windowTitle",
                reason: "Window title cannot be empty"
            )
        }
    }
    
    /// Validates a UI element role
    /// - Parameter role: The role to validate
    /// - Throws: ValidationError if the role is invalid
    public static func validateElementRole(_ role: String) throws {
        guard !role.isEmpty else {
            throw ValidationError.invalidArgument(
                name: "role",
                reason: "Element role cannot be empty"
            )
        }
        
        // List of common accessibility roles
        let validRoles = [
            "button", "checkbox", "combobox", "disclosureTriangle", 
            "group", "image", "link", "menu", "menuBar", "menuItem", 
            "popUpButton", "progressIndicator", "radioButton", "radioGroup", 
            "scrollArea", "scrollBar", "slider", "staticText", "stepper", 
            "tab", "tabGroup", "table", "text", "textField", "toolbar", 
            "window"
        ]
        
        if !validRoles.contains(role.lowercased()) {
            // Don't throw an error, just output a warning in the debug information
            print("Warning: '\(role)' is not a standard accessibility role. Continuing anyway.")
        }
    }
    
    /// Validates a UI element identifier
    /// - Parameter identifier: The identifier to validate
    /// - Throws: ValidationError if the identifier is invalid
    public static func validateElementIdentifier(_ identifier: String) throws {
        guard !identifier.isEmpty else {
            throw ValidationError.invalidArgument(
                name: "identifier",
                reason: "Element identifier cannot be empty"
            )
        }
    }
    
    /// Validates a UI element title
    /// - Parameter title: The title to validate
    /// - Throws: ValidationError if the title is invalid
    public static func validateElementTitle(_ title: String) throws {
        guard !title.isEmpty else {
            throw ValidationError.invalidArgument(
                name: "title",
                reason: "Element title cannot be empty"
            )
        }
    }
    
    /// Validates a timeout value
    /// - Parameter timeout: The timeout value in seconds
    /// - Throws: ValidationError if the timeout is invalid
    public static func validateTimeout(_ timeout: TimeInterval) throws {
        guard timeout > 0 else {
            throw ValidationError.invalidArgument(
                name: "timeout",
                reason: "Timeout must be greater than 0"
            )
        }
        
        guard timeout <= 300 else {
            throw ValidationError.invalidArgument(
                name: "timeout",
                reason: "Timeout must not exceed 300 seconds (5 minutes)"
            )
        }
    }
    
    /// Validates a retry count
    /// - Parameter count: The number of retries
    /// - Throws: ValidationError if the retry count is invalid
    public static func validateRetryCount(_ count: Int) throws {
        guard count >= 0 else {
            throw ValidationError.invalidArgument(
                name: "retryCount",
                reason: "Retry count must be a non-negative integer"
            )
        }
        
        guard count <= 10 else {
            throw ValidationError.invalidArgument(
                name: "retryCount",
                reason: "Retry count must not exceed 10"
            )
        }
    }
    
    /// Validates a retry delay
    /// - Parameter delay: The delay between retries in seconds
    /// - Throws: ValidationError if the delay is invalid
    public static func validateRetryDelay(_ delay: TimeInterval) throws {
        guard delay >= 0 else {
            throw ValidationError.invalidArgument(
                name: "retryDelay",
                reason: "Retry delay must be a non-negative value"
            )
        }
        
        guard delay <= 10 else {
            throw ValidationError.invalidArgument(
                name: "retryDelay",
                reason: "Retry delay must not exceed 10 seconds"
            )
        }
    }
    
    /// Validates screen coordinates
    /// - Parameters:
    ///   - x: The x coordinate
    ///   - y: The y coordinate
    /// - Throws: ValidationError if the coordinates are invalid
    public static func validateScreenCoordinates(x: CGFloat, y: CGFloat) throws {
        guard x >= 0 && y >= 0 else {
            throw ValidationError.invalidArgument(
                name: "coordinates",
                reason: "Screen coordinates must be non-negative"
            )
        }
        
        // Get the main screen bounds
        if let mainScreenBounds = NSScreen.main?.frame {
            guard x <= mainScreenBounds.width && y <= mainScreenBounds.height else {
                throw ValidationError.invalidArgument(
                    name: "coordinates",
                    reason: "Coordinates (\(x), \(y)) are outside the main screen bounds (\(mainScreenBounds.width), \(mainScreenBounds.height))"
                )
            }
        }
    }
    
    /// Validates an output format string
    /// - Parameter format: The format string to validate
    /// - Throws: ValidationError if the format is invalid
    public static func validateOutputFormat(_ format: String) throws {
        let validFormats = ["text", "json", "xml"]
        guard validFormats.contains(format.lowercased()) else {
            throw ValidationError.invalidArgument(
                name: "format",
                reason: "Invalid output format '\(format)'. Valid formats are: \(validFormats.joined(separator: ", "))"
            )
        }
    }
    
    /// Validates a verbosity level
    /// - Parameter level: The verbosity level to validate
    /// - Throws: ValidationError if the level is invalid
    public static func validateVerbosityLevel(_ level: Int) throws {
        guard level >= 0 && level <= 3 else {
            throw ValidationError.invalidArgument(
                name: "verbosity",
                reason: "Verbosity level must be between 0 and 3"
            )
        }
    }
    
    /// Validates a position format string (x,y)
    /// - Parameter positionString: The position string to validate
    /// - Throws: ValidationError if the position format is invalid
    public static func validatePositionFormat(_ positionString: String) throws {
        let components = positionString.split(separator: ",")
        
        guard components.count == 2 else {
            throw ValidationError.invalidArgument(
                name: "position",
                reason: "Position must be in format 'x,y'"
            )
        }
        
        guard let x = Double(components[0]), let y = Double(components[1]) else {
            throw ValidationError.invalidArgument(
                name: "position",
                reason: "Position coordinates must be valid numbers"
            )
        }
        
        // Validate that the coordinates are within screen bounds
        try validateScreenCoordinates(x: CGFloat(x), y: CGFloat(y))
    }
    
    /// Validates a size format string (width,height)
    /// - Parameter sizeString: The size string to validate
    /// - Throws: ValidationError if the size format is invalid
    public static func validateSizeFormat(_ sizeString: String) throws {
        let components = sizeString.split(separator: ",")
        
        guard components.count == 2 else {
            throw ValidationError.invalidArgument(
                name: "size",
                reason: "Size must be in format 'width,height'"
            )
        }
        
        guard let width = Double(components[0]), let height = Double(components[1]) else {
            throw ValidationError.invalidArgument(
                name: "size",
                reason: "Size dimensions must be valid numbers"
            )
        }
        
        guard width > 0 && height > 0 else {
            throw ValidationError.invalidArgument(
                name: "size",
                reason: "Width and height must be positive values"
            )
        }
        
        // Get the main screen bounds and validate that the size is reasonable
        if let mainScreenBounds = NSScreen.main?.frame {
            if width > mainScreenBounds.width * 2 || height > mainScreenBounds.height * 2 {
                print("Warning: Requested window size (\(width)x\(height)) is larger than the screen bounds (\(mainScreenBounds.width)x\(mainScreenBounds.height))")
            }
        }
    }
}