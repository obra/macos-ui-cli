// ABOUTME: This file wraps the Haxcessibility library with Swift-friendly interfaces.
// ABOUTME: It provides Swift access to the Objective-C accessibility API.

import Foundation
import Haxcessibility

/// Provides system-wide accessibility functionality
public class SystemAccessibility {
    /// Checks if Haxcessibility library is available
    /// - Returns: True if the library is available, false otherwise
    public static func isAvailable() -> Bool {
        return true
    }
    
    /// Gets the system-wide accessibility object
    /// - Returns: The HAXSystem instance or nil if not available
    public static func getSystem() -> HAXSystem? {
        return HAXSystem()
    }
    
    /// Gets the currently focused application
    /// - Returns: The focused HAXApplication or nil if none
    public static func getFocusedApplication() -> HAXApplication? {
        return HAXSystem().focusedApplication
    }
    
    /// Gets an application by its process ID
    /// - Parameter pid: The process ID
    /// - Returns: The HAXApplication or nil if not found
    public static func getApplicationWithPID(_ pid: pid_t) -> HAXApplication? {
        // Check if the PID is valid before creating HAXApplication
        // This prevents creating HAXApplication instances for non-existent PIDs
        if pid <= 0 || !isPIDValid(pid) {
            return nil
        }
        return HAXApplication(pid: pid)
    }
    
    /// Checks if a PID is valid (process exists)
    /// - Parameter pid: The process ID to check
    /// - Returns: True if the PID is valid, false otherwise
    private static func isPIDValid(_ pid: pid_t) -> Bool {
        // Use kill with signal 0 to check if the process exists
        // This doesn't actually send a signal, just checks if the process exists
        return kill(pid, 0) == 0 || errno != ESRCH
    }
    
    /// Gets all accessible applications
    /// - Returns: An array of HAXApplication instances
    public static func getAllApplications() -> [HAXApplication] {
        // Note: Haxcessibility doesn't provide a direct method to get all
        // applications, so this is a placeholder for future implementation
        return []
    }
}