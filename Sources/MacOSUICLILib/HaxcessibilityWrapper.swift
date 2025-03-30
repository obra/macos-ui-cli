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
        // First try using HAXSystem's focusedApplication
        if let focusedApp = HAXSystem().focusedApplication {
            return focusedApp
        }
        
        // Fallback to NSWorkspace's frontmostApplication
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let pid = frontApp.processIdentifier
            if pid > 0 {
                return HAXApplication(pid: pid)
            }
        }
        
        return nil
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
        // Use NSWorkspace to get all running applications
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        // Log how many apps NSWorkspace reports
        DebugLogger.shared.logInfo("NSWorkspace reports \(runningApps.count) running applications")
        
        // Filter to only include actual GUI applications
        let guiApps = runningApps.filter { app in
            // Only include apps that:
            // 1. Have a non-empty bundleIdentifier
            // 2. Have an activationPolicy of .regular (are regular GUI apps)
            // 3. Are not background-only
            return app.bundleIdentifier != nil &&
                   app.activationPolicy == .regular
        }
        
        DebugLogger.shared.logInfo("Found \(guiApps.count) GUI applications after filtering")
        
        // Convert to HAXApplication instances
        var haxApps: [HAXApplication] = []
        for app in guiApps {
            let pid = app.processIdentifier
            if pid > 0, let haxApp = HAXApplication(pid: pid) {
                haxApps.append(haxApp)
            }
        }
        
        DebugLogger.shared.logInfo("Successfully created \(haxApps.count) HAXApplication instances")
        return haxApps
    }
}