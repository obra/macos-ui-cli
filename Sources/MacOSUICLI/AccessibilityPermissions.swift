// ABOUTME: This file handles macOS accessibility permission checks and requests.
// ABOUTME: It provides utilities for verifying and requesting accessibility access.

import Foundation
import AppKit

public enum AccessibilityPermissionStatus {
    case granted
    case denied
    case unknown
    
    /// Whether this status represents granted permissions
    public var isGranted: Bool {
        return self == .granted
    }
}

public class AccessibilityPermissions {
    
    /// Checks if accessibility is enabled system-wide
    /// - Returns: True if accessibility is enabled, false otherwise
    public static func isEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Checks if the application has permission to use accessibility features
    /// - Returns: The current permission status
    public static func checkPermission() -> AccessibilityPermissionStatus {
        let logger = DebugLogger.shared
        logger.logDebug("Checking permission status...")
        
        // First check if accessibility is enabled globally
        let globallyEnabled = AXIsProcessTrusted()
        logger.logDebug("AXIsProcessTrusted() returned: \(globallyEnabled)")
        
        if globallyEnabled {
            logger.logDebug("Process is trusted globally")
            return .granted
        }
        
        // Try to verify with no prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        logger.logDebug("AXIsProcessTrustedWithOptions() returned: \(accessibilityEnabled)")
        
        if accessibilityEnabled {
            logger.logDebug("Process is trusted with options")
            return .granted
        }
        
        // Try one more approach - try to access a test element
        let testSuccess = testAccessibilityAccess()
        logger.logDebug("Test accessibility access returned: \(testSuccess)")
        
        if testSuccess {
            logger.logDebug("Accessibility access test successful")
            return .granted
        }
        
        // Last resort - try to get a list of windows
        let testWindowsSuccess = testWindowAccess()
        logger.logDebug("Test window access returned: \(testWindowsSuccess)")
        
        if testWindowsSuccess {
            logger.logDebug("Window access test successful")
            return .granted
        }
        
        logger.logDebug("All permission checks failed")
        return .denied
    }
    
    /// Tests accessibility access by trying to get a simple accessibility attribute
    /// - Returns: True if successful, false otherwise
    private static func testAccessibilityAccess() -> Bool {
        // Try to access a simple accessibility attribute as a test
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        print("Debug: AXUIElementCopyAttributeValue result: \(result.rawValue)")
        
        // If we can successfully get the focused element, accessibility is working
        return result == .success
    }
    
    /// Tests accessibility by trying to access window information
    /// - Returns: True if successful, false otherwise
    private static func testWindowAccess() -> Bool {
        // Try to get the list of windows
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]
        
        if let windows = windowList, !windows.isEmpty {
            print("Debug: Successfully got window list with \(windows.count) windows")
            return true
        } else {
            print("Debug: Got empty window list")
            return false
        }
    }
    
    /// Prompts the user to enable accessibility permissions if not already granted
    /// - Returns: The updated permission status after prompting
    public static func requestPermission() -> AccessibilityPermissionStatus {
        // If already granted, don't prompt again
        if checkPermission() == .granted {
            return .granted
        }
        
        // Show prompt and check again
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        // Wait a bit for the permission to be granted
        if !accessibilityEnabled {
            // Open the preferences to make it easier
            openAccessibilityPreferences()
            
            // Print instructions
            print(getPermissionError())
            
            // Wait for a moment to let user interact with dialog
            Thread.sleep(forTimeInterval: 1.0)
            
            // Check one more time
            return checkPermission()
        }
        
        return .granted
    }
    
    /// Gets a descriptive error message about accessibility permissions
    /// - Returns: A string with instructions for enabling accessibility
    public static func getPermissionError() -> String {
        let appPath = Bundle.main.bundlePath
        
        return """
        Accessibility permissions are required but not granted.
        
        It appears you're already using the app wrapper but permissions still aren't working.
        Try these troubleshooting steps:
        
        1. Check that the app wrapper exists and is properly configured:
           ls -la /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli
        
        2. Create a new wrapper with the --create-wrapper flag:
           ./macos-ui-cli permissions --create-wrapper
           
        3. Make sure to properly grant permission in System Preferences:
           - Open System Preferences > Security & Privacy > Privacy
           - Select 'Accessibility' from the sidebar
           - Click the lock icon to make changes
           - Verify that /Applications/macos-ui-cli.app is checked in the list
           - If it's already checked, try unchecking and rechecking it
           - Close System Preferences completely
           
        4. Try logging out and logging back in to refresh permissions
        
        5. Try a Terminal app wrapper:
           - Open Automator
           - Create a new Application
           - Add the "Run Shell Script" action
           - Enter the path to your command: /path/to/macos-ui-cli permissions
           - Save it as an app in Applications
           - Grant that app accessibility permissions
        
        Current application path: \(appPath)
        """
    }
    
    /// Opens the Security & Privacy preferences panel to the Accessibility section
    public static func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}