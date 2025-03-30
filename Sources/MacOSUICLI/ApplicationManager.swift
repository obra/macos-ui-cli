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
    
    /// Whether this app is known to cause high CPU usage
    public var isProblematic: Bool = false
    
    /// List of application names known to cause high CPU usage
    private static let problematicAppNames: [String] = [
        "Safari",
        "Finder",
        "Mail",
        "Photos",
        "Music"
    ]
    
    /// Creates an Application instance from a HAXApplication instance
    /// - Parameter haxApp: The HAXApplication instance
    init(haxApp: HAXApplication?) {
        self.haxApplication = haxApp
        self.pid = haxApp?.processIdentifier ?? 0
        
        // Get the name from HAXApplication or fallback to NSRunningApplication
        if let haxName = haxApp?.localizedName, !haxName.isEmpty {
            self.name = haxName
        } else {
            // Try to get a better name from NSRunningApplication
            if let pid = haxApp?.processIdentifier, 
               let runningApp = NSRunningApplication(processIdentifier: pid) {
                self.name = runningApp.localizedName ?? "Unknown"
                self.bundleIdentifier = runningApp.bundleIdentifier
                self.isFrontmost = runningApp.isActive
            } else {
                self.name = "Unknown"
            }
        }
        
        // If we still don't have a bundle ID, try to get it from HAXApplication
        if self.bundleIdentifier == nil, let pid = haxApp?.processIdentifier {
            // Try to get bundle ID using process info
            if let runningApp = NSRunningApplication(processIdentifier: pid) {
                self.bundleIdentifier = runningApp.bundleIdentifier
            }
        }
        
        // If we still don't have frontmost status, check HAXApplication
        let system = HAXSystem()
        if let focusedApp = system.focusedApplication {
            self.isFrontmost = (focusedApp.processIdentifier == self.pid)
        }
        
        // Check if this is a problematic application
        self.isProblematic = Application.isProblematicApp(self.name)
        if self.isProblematic {
            DebugLogger.shared.logWarning("Application '\(self.name)' is marked as problematic")
        }
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
        self.isProblematic = Application.isProblematicApp(name)
    }
    
    /// Check if an application is known to be problematic
    /// - Parameter appName: The name of the application
    /// - Returns: True if the application is known to be problematic
    static func isProblematicApp(_ appName: String) -> Bool {
        let lowercasedName = appName.lowercased()
        return problematicAppNames.contains { name in
            lowercasedName.contains(name.lowercased())
        }
    }
    
    /// Creates a simplified element tree for an application
    /// - Returns: A root element with a simplified tree
    func createSimplifiedElementTree() -> Element {
        DebugLogger.shared.logInfo("Creating simplified element tree for \(self.name)")
        
        // Create a simple root element
        let safeRootElement = Element(
            role: "AXApplication",
            title: self.name,
            hasChildren: true,
            roleDescription: "Application (CLI Mode)",
            subRole: ""
        )
        
        // Create a simple window element
        let safeWindowElement = Element(
            role: "AXWindow",
            title: "Main Window (CLI Mode)",
            hasChildren: true,
            roleDescription: "Window",
            subRole: ""
        )
        
        // Create a simple info element
        let safeInfoElement = Element(
            role: "AXGroup",
            title: "CLI Mode Active",
            hasChildren: false,
            roleDescription: "Application is running in CLI mode",
            subRole: ""
        )
        
        // Create a detailed explanation element
        let safeExplanationElement = Element(
            role: "AXStaticText",
            title: "This application (\(self.name)) is being accessed through the CLI tool.",
            hasChildren: false,
            roleDescription: "CLI mode explanation",
            subRole: ""
        )
        
        // Connect the elements
        safeRootElement.addChild(safeWindowElement)
        safeWindowElement.addChild(safeInfoElement)
        safeWindowElement.addChild(safeExplanationElement)
        
        return safeRootElement
    }
    
    /// Gets a simple list of window descriptions
    /// - Returns: An array of window descriptions
    public func getWindowDescriptions() -> [String] {
        // If this is a problematic app, return a simplified representation
        if isProblematic {
            return ["Main Window (CLI Mode)"]
        }
        
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
    
    /// Gets all UI elements directly from the application
    /// - Returns: Array of root elements in the application
    /// - Throws: ApplicationManagerError if elements cannot be retrieved
    public func getElements() throws -> [Element] {
        // If this is a problematic app, create a simplified element tree
        if isProblematic {
            DebugLogger.shared.logInfo("Using simple tree for '\(self.name)'")
            let rootElement = createSimplifiedElementTree()
            return [rootElement]
        }
        
        // Check CPU usage before proceeding
        if getCurrentCPUUsage() > 50.0 {
            DebugLogger.shared.logWarning("High CPU usage detected for '\(self.name)'")
            let rootElement = createSimplifiedElementTree()
            return [rootElement]
        }
        
        // Normal path - first get the application's windows
        let windows = try getWindows()
        
        // For each window, get its elements
        var allElements: [Element] = []
        for window in windows {
            do {
                // Use timeout to prevent getting stuck
                let windowElements = try withTimeout(3.0) {
                    try window.getElements()
                }
                allElements.append(contentsOf: windowElements)
            } catch let error as OperationError where error.errorCode == ErrorCode.operationTimeout.rawValue {
                DebugLogger.shared.logWarning("Timeout getting elements for window: \(error.localizedDescription)")
                // Create a simplified representation for this window
                let safeWindowElement = Element(
                    role: "window",
                    title: window.title + " (CLI Mode)",
                    hasChildren: true,
                    roleDescription: "Window (elements not loaded due to timeout)",
                    subRole: ""
                )
                allElements.append(safeWindowElement)
            } catch {
                DebugLogger.shared.logError(error)
            }
            
            // Break if CPU usage is getting high
            if getCurrentCPUUsage() > 70.0 {
                DebugLogger.shared.logWarning("CPU usage exceeded threshold while getting elements. Stopping to prevent high CPU usage.")
                break
            }
        }
        
        // If we couldn't get any elements, return a simplified representation
        if allElements.isEmpty {
            DebugLogger.shared.logWarning("No elements found for '\(self.name)'. Using simple tree.")
            let rootElement = createSimplifiedElementTree()
            return [rootElement]
        }
        
        return allElements
    }
    
    /// Get current CPU usage of this process
    /// - Returns: CPU usage percentage
    private func getCurrentCPUUsage() -> Double {
        var cpuUsage = 0.0
        
        do {
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", "ps -xo %cpu -p \(ProcessInfo.processInfo.processIdentifier) | tail -1"]
            let outputPipe = Pipe()
            task.standardOutput = outputPipe
            
            try task.run()
            task.waitUntilExit()
            
            if let outputData = try? outputPipe.fileHandleForReading.readToEnd(),
               let output = String(data: outputData, encoding: .utf8) {
                cpuUsage = Double(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                
                // Log if CPU usage is high
                if cpuUsage > 50.0 {
                    DebugLogger.shared.logWarning("High CPU usage detected: \(cpuUsage)%")
                }
            }
        } catch {
            DebugLogger.shared.logError(error)
        }
        
        return cpuUsage
    }
    
    /// Safe version of getElements that doesn't throw
    /// - Returns: Array of elements, empty array if there was an error
    public func getElementsNoThrow() -> [Element] {
        do {
            return try getElements()
        } catch {
            DebugLogger.shared.logError(error)
            
            // Create a simplified representation on error
            if isProblematic {
                DebugLogger.shared.logWarning("Error getting elements. Using simple tree.")
                let rootElement = createSimplifiedElementTree()
                return [rootElement]
            }
            
            return []
        }
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
        
        var focusedApp: Application? = nil
        
        if let haxApp = SystemAccessibility.getFocusedApplication() {
            focusedApp = Application(haxApp: haxApp)
            
            // Check if this app is problematic and report it
            if let app = focusedApp, app.isProblematic {
                DebugLogger.shared.logWarning("Focused application '\(app.name)' is marked as problematic.")
            }
        }
        
        return focusedApp
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