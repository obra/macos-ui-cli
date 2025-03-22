// ABOUTME: This file wraps the Haxcessibility library with Swift-friendly interfaces.
// ABOUTME: It provides Swift access to the Objective-C accessibility API.

import Foundation

#if HAXCESSIBILITY_AVAILABLE
import Haxcessibility
#endif

/// Provides system-wide accessibility functionality
public class SystemAccessibility {
    /// Checks if Haxcessibility library is available
    /// - Returns: True if the library is available, false otherwise
    public static func isAvailable() -> Bool {
        #if HAXCESSIBILITY_AVAILABLE
        return true
        #else
        return false
        #endif
    }
    
    #if HAXCESSIBILITY_AVAILABLE
    /// Gets the system-wide accessibility object
    /// - Returns: The HAXSystem instance or nil if not available
    public static func getSystem() -> HAXSystem? {
        return HAXSystem.system()
    }
    
    /// Gets the currently focused application
    /// - Returns: The focused HAXApplication or nil if none
    public static func getFocusedApplication() -> HAXApplication? {
        return HAXSystem.system().focusedApplication
    }
    
    /// Gets an application by its process ID
    /// - Parameter pid: The process ID
    /// - Returns: The HAXApplication or nil if not found
    public static func getApplicationWithPID(_ pid: pid_t) -> HAXApplication? {
        return HAXApplication.application(withPID: pid)
    }
    
    /// Gets all accessible applications
    /// - Returns: An array of HAXApplication instances
    public static func getAllApplications() -> [HAXApplication] {
        // Note: Haxcessibility doesn't provide a direct method to get all
        // applications, so this is a placeholder for future implementation
        return []
    }
    #endif
}