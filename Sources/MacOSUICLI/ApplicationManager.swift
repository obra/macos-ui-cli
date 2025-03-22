// ABOUTME: This file provides an interface for discovering and accessing applications.
// ABOUTME: It wraps Haxcessibility library functions for application discovery and access.

import Foundation
import Haxcessibility

/// Represents a macOS application with accessibility information
public class Application {
    private var haxApplication: HAXApplication? = nil
    
    /// The PID of the application
    public var pid: Int32 = 0
    
    /// The name of the application
    public var name: String = ""
    
    /// The bundle identifier of the application if available
    public var bundleIdentifier: String? = nil
    
    /// Whether the application is frontmost
    public var isFrontmost: Bool = false
    
    /// Creates an Application instance from a HAXApplication instance
    /// - Parameter haxApp: The HAXApplication instance
    init(haxApp: HAXApplication?) {
        self.haxApplication = haxApp
        self.name = haxApp?.localizedName ?? "Unknown"
        // In a real implementation, we would get PID, bundle ID, etc.
        // from the HAXApplication instance, but for now we'll use placeholders
        self.pid = haxApp?.processIdentifier ?? 0
        self.bundleIdentifier = nil
        self.isFrontmost = false
    }
    
    /// Creates a mock Application instance for testing
    /// - Parameters:
    ///   - name: The name of the mock application
    ///   - pid: The process ID of the mock application
    init(mockWithName name: String, pid: Int32) {
        self.name = name
        self.pid = pid
        self.bundleIdentifier = "com.example.\(name.lowercased())"
        self.isFrontmost = false
    }
    
    /// Gets a simple list of window descriptions
    /// - Returns: An array of window descriptions
    public func getWindowDescriptions() -> [String] {
        // Access the HAXApplication through SystemAccessibility
        if let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) {
            return haxApp.windows.map { window in
                // In a real implementation, we would convert HAXWindow to a
                // window model, but for now we'll just return the description
                return window.description
            }
        }
        return []
    }
}

/// Manager for accessing and controlling applications via accessibility
public class ApplicationManager {
    
    /// Gets the currently focused application
    /// - Returns: An Application instance representing the focused application, or nil if none
    /// - Throws: AccessibilityError if accessibility is not available
    public static func getFocusedApplication() throws -> Application? {
        // First check if accessibility is enabled
        if !AccessibilityPermissions.isEnabled() {
            throw AccessibilityError.accessibilityNotEnabled
        }
        
        if !AccessibilityPermissions.checkPermission().isGranted {
            throw AccessibilityError.permissionDenied
        }
        
        if let haxApp = SystemAccessibility.getFocusedApplication() {
            return Application(haxApp: haxApp)
        }
        
        return nil
    }
    
    /// Safe version of getFocusedApplication that doesn't throw
    /// - Returns: An Application instance representing the focused application, or nil if none or if there was an error
    public static func getFocusedApplicationNoThrow() -> Application? {
        do {
            return try getFocusedApplication()
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
    
    /// Gets an application by PID
    /// - Parameter pid: The process ID of the application
    /// - Returns: An Application instance
    /// - Throws: ApplicationManagerError if the application cannot be found
    public static func getApplicationByPID(_ pid: Int32) throws -> Application {
        // First check if accessibility is enabled
        if !AccessibilityPermissions.isEnabled() {
            throw AccessibilityError.accessibilityNotEnabled
        }
        
        if !AccessibilityPermissions.checkPermission().isGranted {
            throw AccessibilityError.permissionDenied
        }
        
        guard let haxApp = SystemAccessibility.getApplicationWithPID(pid) else {
            throw ApplicationManagerError.applicationNotFound(description: "Application with PID \(pid)")
        }
        
        return Application(haxApp: haxApp)
    }
    
    /// Safe version of getApplicationByPID that doesn't throw
    /// - Parameter pid: The process ID of the application
    /// - Returns: An Application instance, or nil if not found or if there was an error
    public static func getApplicationByPIDNoThrow(_ pid: Int32) -> Application? {
        do {
            return try getApplicationByPID(pid)
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
    
    /// Gets an application by name
    /// - Parameter name: The name of the application to find
    /// - Returns: An Application instance
    /// - Throws: ApplicationManagerError if the application cannot be found
    public static func getApplicationByName(_ name: String) throws -> Application {
        // First check if accessibility is enabled
        if !AccessibilityPermissions.isEnabled() {
            throw AccessibilityError.accessibilityNotEnabled
        }
        
        if !AccessibilityPermissions.checkPermission().isGranted {
            throw AccessibilityError.permissionDenied
        }
        
        // Validate name
        if name.isEmpty {
            throw ValidationError.invalidArgument(name: "name", reason: "Application name cannot be empty")
        }
        
        // Get all applications
        let allApps = try getAllApplications()
        
        // Find the first one with a matching name
        for app in allApps {
            if app.name.caseInsensitiveCompare(name) == .orderedSame {
                return app
            }
            
            // Also check if name is a substring of the application name
            if app.name.lowercased().contains(name.lowercased()) {
                return app
            }
        }
        
        throw ApplicationManagerError.applicationNotFound(description: "Application with name '\(name)'")
    }
    
    /// Safe version of getApplicationByName that doesn't throw
    /// - Parameter name: The name of the application to find
    /// - Returns: An Application instance, or nil if not found or if there was an error
    public static func getApplicationByNameNoThrow(_ name: String) -> Application? {
        do {
            return try getApplicationByName(name)
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
    
    /// Lists all running applications with accessibility access
    /// - Returns: An array of Application instances
    /// - Throws: AccessibilityError if accessibility is not available
    public static func getAllApplications() throws -> [Application] {
        // First check if accessibility is enabled
        if !AccessibilityPermissions.isEnabled() {
            throw AccessibilityError.accessibilityNotEnabled
        }
        
        if !AccessibilityPermissions.checkPermission().isGranted {
            throw AccessibilityError.permissionDenied
        }
        
        let haxApps = SystemAccessibility.getAllApplications()
        return haxApps.map { app in
            return Application(haxApp: app)
        }
    }
    
    /// Safe version of getAllApplications that doesn't throw
    /// - Returns: An array of Application instances, empty array if there was an error
    public static func getAllApplicationsNoThrow() -> [Application] {
        do {
            return try getAllApplications()
        } catch {
            DebugLogger.shared.logError(error)
            return []
        }
    }
}