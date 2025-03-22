// ABOUTME: This file handles macOS accessibility permission checks and requests.
// ABOUTME: It provides utilities for verifying and requesting accessibility access.

import Foundation
import AppKit

public enum AccessibilityPermissionStatus {
    case granted
    case denied
    case unknown
}

public class AccessibilityPermissions {
    
    /// Checks if the application has permission to use accessibility features
    /// - Returns: The current permission status
    public static func checkPermission() -> AccessibilityPermissionStatus {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if accessibilityEnabled {
            return .granted
        } else {
            return .denied
        }
    }
    
    /// Prompts the user to enable accessibility permissions if not already granted
    /// - Returns: The updated permission status after prompting
    public static func requestPermission() -> AccessibilityPermissionStatus {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if accessibilityEnabled {
            return .granted
        } else {
            return .denied
        }
    }
    
    /// Gets a descriptive error message about accessibility permissions
    /// - Returns: A string with instructions for enabling accessibility
    public static func getPermissionError() -> String {
        return """
        Accessibility permissions are required but not granted.
        
        Please enable them in System Preferences:
        1. Open System Preferences > Security & Privacy > Privacy
        2. Select 'Accessibility' from the sidebar
        3. Click the lock icon to make changes
        4. Add or check this application in the list
        5. Restart the application
        """
    }
    
    /// Opens the Security & Privacy preferences panel to the Accessibility section
    public static func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}