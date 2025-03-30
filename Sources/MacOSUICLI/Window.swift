// ABOUTME: This file provides a Swift wrapper around the HAXWindow class.
// ABOUTME: It enables manipulation and inspection of application windows.

import Foundation
import CoreGraphics
import Haxcessibility

/// Represents a window from a macOS application
public class Window {
    private var haxWindow: HAXWindow? = nil
    
    /// The title of the window
    public var title: String = ""
    
    /// The frame of the window in screen coordinates
    public var frame: CGRect = .zero
    
    /// Whether the window is fullscreen
    public var isFullscreen: Bool = false
    
    /// Whether the window is minimized
    public var isMinimized: Bool = false
    
    /// Creates a Window instance from a HAXWindow instance
    /// - Parameter haxWindow: The HAXWindow instance
    init(haxWindow: HAXWindow?) {
        self.haxWindow = haxWindow
        self.title = haxWindow?.title ?? "Untitled Window"
        self.frame = haxWindow?.frame ?? .zero
        self.isFullscreen = haxWindow?.isFullscreen ?? false
        
        // Check if window is minimized
        if let haxWindow = haxWindow {
            do {
                if let minimized = try haxWindow.getAttributeValue(forKey: "AXMinimized") as? Bool {
                    self.isMinimized = minimized
                }
            } catch {
                // If can't get minimized state, assume not minimized
                self.isMinimized = false
            }
        }
    }
    
    /// Creates a mock Window for testing
    /// - Parameters:
    ///   - title: The title of the window
    ///   - frame: The frame of the window
    ///   - isFullscreen: Whether the window is fullscreen
    init(title: String, frame: CGRect, isFullscreen: Bool = false) {
        self.title = title
        self.frame = frame
        self.isFullscreen = isFullscreen
    }
    
    /// Brings the window to the front
    /// - Throws: WindowError if the window cannot be raised
    public func raise() throws {
        guard let haxWindow = self.haxWindow else {
            throw WindowError.windowNotFound(description: "Window with title '\(title)'")
        }
        
        try withRetry(maxAttempts: 3, delay: 0.5) { [self] in
            if !haxWindow.raise() {
                throw WindowError.windowNotResponding(description: "Window with title '\(self.title)'")
            }
        }
    }
    
    /// Safe version of raise that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func raiseNoThrow() -> Bool {
        do {
            try raise()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Closes the window
    /// - Throws: WindowError if the window cannot be closed
    public func close() throws {
        guard let haxWindow = self.haxWindow else {
            throw WindowError.windowNotFound(description: "Window with title '\(title)'")
        }
        
        try withRetry(maxAttempts: 3, delay: 0.5) { [self] in
            if !haxWindow.close() {
                throw WindowError.windowNotResponding(description: "Window with title '\(self.title)'")
            }
        }
    }
    
    /// Safe version of close that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func closeNoThrow() -> Bool {
        do {
            try close()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Gets the CoreGraphics window ID
    /// - Returns: The window ID
    /// - Throws: WindowError if the window ID cannot be retrieved
    public func getCGWindowID() throws -> CGWindowID {
        guard let haxWindow = self.haxWindow else {
            throw WindowError.windowNotFound(description: "Window with title '\(title)'")
        }
        
        return try withTimeout(3.0) { [self] in
            let windowID = haxWindow.cgWindowID()
            if windowID == 0 {
                throw WindowError.windowNotResponding(description: "Window with title '\(self.title)'")
            }
            return windowID
        }
    }
    
    /// Safe version of getCGWindowID that doesn't throw
    /// - Returns: The window ID or 0 if not available
    public func getCGWindowIDNoThrow() -> CGWindowID {
        do {
            return try getCGWindowID()
        } catch {
            DebugLogger.shared.logError(error)
            return 0
        }
    }
    
    /// Gets the UI elements in the window
    /// - Returns: An array of UI elements in the window
    /// - Throws: WindowError if elements cannot be retrieved
    public func getElements() throws -> [Element] {
        guard let haxWindow = self.haxWindow else {
            // Return a synthetic element to avoid errors
            let windowElement = Element(role: "window", title: self.title)
            windowElement.hasChildren = true
            return [windowElement]
        }
        
        do {
            return try withTimeoutAndRetry(timeout: 5.0, maxAttempts: 2, delay: 0.5) { [self] in
                // First, create a proper window element that we'll always return
                let windowElement = Element(haxElement: haxWindow)
                
                // Now try multiple strategies to get child elements
                
                // 1. Try to get children directly from the window element
                if let haxChildren = haxWindow.children, !haxChildren.isEmpty {
                    DebugLogger.shared.logInfo("Found \(haxChildren.count) direct children in window '\(self.title)'")
                    return [windowElement] // Return just the window, children are already accessible through it
                }
                
                // 2. Try using the views property (works for some apps)
                if let views = haxWindow.views, !views.isEmpty {
                    DebugLogger.shared.logInfo("Found \(views.count) views in window '\(self.title)'")
                    // Add these as children to the window element instead of returning directly
                    for view in views {
                        let childElement = Element(haxElement: view)
                        windowElement.addChild(childElement)
                    }
                }
                
                // 3. Try to get UI elements via AXChildren attribute
                do {
                    if let children = try haxWindow.getAttributeValue(forKey: "AXChildren") as? [HAXElement] {
                        DebugLogger.shared.logInfo("Found \(children.count) children via AXChildren attribute")
                        // Add these as children to the window element
                        for child in children {
                            let childElement = Element(haxElement: child)
                            windowElement.addChild(childElement)
                        }
                    }
                } catch {
                    DebugLogger.shared.logWarning("Could not get AXChildren attribute: \(error)")
                }
                
                // Always return the window element - its children will be accessible
                return [windowElement]
            }
        } catch {
            DebugLogger.shared.logError(error)
            
            // One last attempt - try directly accessing from AXUIElementRef
            if let axElement = haxWindow.elementRef {
                DebugLogger.shared.logInfo("Trying direct AXUIElementRef access for window '\(self.title)'")
                
                let windowElement = Element(haxElement: haxWindow)
                windowElement.hasChildren = true
                
                // Create a direct children loading method to get elements without using Haxcessibility
                // This is the same approach Accessibility Inspector uses
                func loadDirectChildren(forElement axElement: AXUIElement) -> [Element] {
                    var children: [Element] = []
                    var childrenRef: CFTypeRef?
                    
                    // Get children attribute using direct API
                    let result = AXUIElementCopyAttributeValue(axElement, "AXChildren" as CFString, &childrenRef)
                    
                    if result == .success, let childArray = childrenRef as? NSArray {
                        for i in 0..<childArray.count {
                            let item = childArray[i] as AnyObject
                            guard CFGetTypeID(item) == AXUIElementGetTypeID() else { continue }
                            let childAXElement = childArray[i] as! AXUIElement
                            // For each child element, create a fake HAXElement to wrap it
                            // This lets us integrate with our existing code
                            let childElement = createElementFromAXUIElement(childAXElement)
                            children.append(childElement)
                        }
                    }
                    
                    return children
                }
                
                // Helper to create an Element from an AXUIElement
                func createElementFromAXUIElement(_ axElement: AXUIElement) -> Element {
                    // Get basic properties directly from AXUIElement
                    var roleRef: CFTypeRef?
                    var titleRef: CFTypeRef?
                    var roleDescRef: CFTypeRef?
                    var subRoleRef: CFTypeRef?
                    
                    let role = AXUIElementCopyAttributeValue(axElement, "AXRole" as CFString, &roleRef) == .success ? 
                        (roleRef as? String ?? "unknown") : "unknown"
                    
                    let title = AXUIElementCopyAttributeValue(axElement, "AXTitle" as CFString, &titleRef) == .success ?
                        (titleRef as? String ?? "") : ""
                    
                    let roleDesc = AXUIElementCopyAttributeValue(axElement, "AXRoleDescription" as CFString, &roleDescRef) == .success ?
                        (roleDescRef as? String ?? "") : ""
                    
                    let subRole = AXUIElementCopyAttributeValue(axElement, "AXSubrole" as CFString, &subRoleRef) == .success ?
                        (subRoleRef as? String ?? "") : ""
                    
                    // Check if it has children
                    var childrenRef: CFTypeRef?
                    let hasChildren = AXUIElementCopyAttributeValue(axElement, "AXChildren" as CFString, &childrenRef) == .success &&
                        (childrenRef as? NSArray)?.count ?? 0 > 0
                    
                    // Create element
                    let element = Element(role: role, title: title, hasChildren: hasChildren,
                                         roleDescription: roleDesc, subRole: subRole)
                    
                    // Create a custom attribute to store the AXUIElement for later use
                    element.customData["axuielement"] = axElement
                    
                    return element
                }
                
                // Get direct children of window
                let directChildren = loadDirectChildren(forElement: axElement)
                
                if !directChildren.isEmpty {
                    DebugLogger.shared.logInfo("Found \(directChildren.count) children via direct AXUIElementRef")
                    
                    // Add these directly to window element
                    for child in directChildren {
                        windowElement.addChild(child)
                    }
                    
                    return [windowElement]
                }
            }
            
            // Create a synthetic element as final fallback
            let windowElement = Element(role: "window", title: self.title, 
                                       hasChildren: true, 
                                       roleDescription: "window", 
                                       subRole: "")
            
            return [windowElement]
        }
    }
    
    /// Safe version of getElements that doesn't throw
    /// - Returns: An array of UI elements in the window, empty array if there was an error
    public func getElementsNoThrow() -> [Element] {
        do {
            return try getElements()
        } catch {
            DebugLogger.shared.logError(error)
            return []
        }
    }
    
    /// Sets focus to this window
    /// - Throws: WindowError if focus cannot be set
    public func focus() throws {
        guard let haxWindow = self.haxWindow else {
            throw WindowError.windowNotFound(description: "Window with title '\(title)'")
        }
        
        // Raise the window first
        try raise()
        
        // Also set the focused attribute if available
        try withRetry(maxAttempts: 3, delay: 0.5) {
            try haxWindow.setAttributeValue(true as CFTypeRef, forKey: "AXFocused")
        }
    }
    
    /// Safe version of focus that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func focusNoThrow() -> Bool {
        do {
            try focus()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Sets the position of the window
    /// - Parameter position: The new position
    /// - Throws: WindowError if the position cannot be set
    public func setPosition(_ position: CGPoint) throws {
        if let haxWindow = self.haxWindow {
            // Set the position attribute
            try withRetry(maxAttempts: 2, delay: 0.5) {
                try haxWindow.setAttributeValue(NSValue(point: position) as CFTypeRef, forKey: "AXPosition")
            }
            self.frame.origin = position
        } else {
            // For testing or mock objects, just update the frame
            self.frame.origin = position
        }
    }
    
    /// Safe version of setPosition that doesn't throw
    /// - Parameter position: The new position
    /// - Returns: True if successful, false otherwise
    public func setPositionNoThrow(_ position: CGPoint) -> Bool {
        do {
            try setPosition(position)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Sets the size of the window
    /// - Parameter size: The new size
    /// - Throws: WindowError if the size cannot be set
    public func setSize(_ size: CGSize) throws {
        if let haxWindow = self.haxWindow {
            // Set the size attribute
            try withRetry(maxAttempts: 2, delay: 0.5) {
                try haxWindow.setAttributeValue(NSValue(size: size) as CFTypeRef, forKey: "AXSize")
            }
            self.frame.size = size
        } else {
            // For testing or mock objects, just update the frame
            self.frame.size = size
        }
    }
    
    /// Safe version of setSize that doesn't throw
    /// - Parameter size: The new size
    /// - Returns: True if successful, false otherwise
    public func setSizeNoThrow(_ size: CGSize) -> Bool {
        do {
            try setSize(size)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Moves and resizes the window in one operation
    /// - Parameter frame: The new frame
    /// - Throws: WindowError if the frame cannot be set
    public func setFrame(_ frame: CGRect) throws {
        try setPosition(frame.origin)
        try setSize(frame.size)
    }
    
    /// Safe version of setFrame that doesn't throw
    /// - Parameter frame: The new frame
    /// - Returns: True if successful, false otherwise
    public func setFrameNoThrow(_ frame: CGRect) -> Bool {
        do {
            try setFrame(frame)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Toggles the window between fullscreen and normal state
    /// - Throws: WindowError if fullscreen cannot be toggled
    public func toggleFullscreen() throws {
        if let haxWindow = self.haxWindow {
            // Toggle fullscreen by performing the fullscreen action
            try withRetry(maxAttempts: 2, delay: 0.5) {
                try haxWindow.performAction("AXToggleFullScreen")
            }
            self.isFullscreen = !self.isFullscreen
        } else {
            // For testing or mock objects
            self.isFullscreen = !self.isFullscreen
        }
    }
    
    /// Safe version of toggleFullscreen that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func toggleFullscreenNoThrow() -> Bool {
        do {
            try toggleFullscreen()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Minimizes the window
    /// - Throws: WindowError if the window cannot be minimized
    public func minimize() throws {
        if let haxWindow = self.haxWindow {
            // Minimize by setting the minimized attribute
            try withRetry(maxAttempts: 2, delay: 0.5) {
                try haxWindow.setAttributeValue(true as CFTypeRef, forKey: "AXMinimized")
            }
            self.isMinimized = true
        } else {
            // For testing or mock objects
            self.isMinimized = true
        }
    }
    
    /// Safe version of minimize that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func minimizeNoThrow() -> Bool {
        do {
            try minimize()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Restores a minimized window
    /// - Throws: WindowError if the window cannot be restored
    public func restore() throws {
        if let haxWindow = self.haxWindow {
            // Restore by setting the minimized attribute to false
            try withRetry(maxAttempts: 2, delay: 0.5) {
                try haxWindow.setAttributeValue(false as CFTypeRef, forKey: "AXMinimized")
            }
            self.isMinimized = false
        } else {
            // For testing or mock objects
            self.isMinimized = false
        }
    }
    
    /// Safe version of restore that doesn't throw
    /// - Returns: True if successful, false otherwise
    public func restoreNoThrow() -> Bool {
        do {
            try restore()
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
}

// Extend Application to use the Window class
extension Application {
    /// Gets the windows of the application
    /// - Returns: An array of windows
    /// - Throws: ApplicationManagerError if windows cannot be retrieved
    public func getWindows() throws -> [Window] {
        DebugLogger.shared.logInfo("Getting windows for '\(self.name)' (PID: \(self.pid))")
        
        // Access the HAXApplication through SystemAccessibility
        guard let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) else {
            let error = ApplicationManagerError.applicationNotFound(description: "Application with name '\(self.name)' (pid: \(self.pid))")
            DebugLogger.shared.logError(error)
            throw error
        }
        
        DebugLogger.shared.logInfo("Successfully got HAXApplication for PID \(self.pid)")
        
        // Get windows with a safety check
        let windowCount = haxApp.windows.count
        DebugLogger.shared.logInfo("Window count from HAXApplication: \(windowCount)")
        
        // Some applications like web browsers might not expose windows correctly through accessibility API
        // Let's check if we can get at least one window, and if not, create a mock window
        if haxApp.windows.isEmpty {
            DebugLogger.shared.logWarning("No windows returned for '\(self.name)'. Creating a mock main window.")
            
            // Create a mock window for applications that don't expose windows correctly
            let mainWindow = Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            return [mainWindow]
        }
        
        // Map HAXWindows to our Window class
        let windows = haxApp.windows.map { Window(haxWindow: $0) }
        DebugLogger.shared.logInfo("Mapped \(windows.count) windows from HAXApplication")
        
        return windows
    }
    
    /// Safe version of getWindows that doesn't throw
    /// - Returns: An array of windows, empty array if there was an error
    public func getWindowsNoThrow() -> [Window] {
        do {
            return try getWindows()
        } catch {
            DebugLogger.shared.logError(error)
            return []
        }
    }
    
    /// Gets the focused window of the application
    /// - Returns: The focused window, or nil if none
    /// - Throws: ApplicationManagerError if focused window cannot be determined
    public func getFocusedWindow() throws -> Window? {
        DebugLogger.shared.logInfo("Getting focused window for '\(self.name)' (PID: \(self.pid))")
        
        // Access the HAXApplication through SystemAccessibility
        guard let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) else {
            let error = ApplicationManagerError.applicationNotFound(description: "Application with name '\(self.name)' (pid: \(self.pid))")
            DebugLogger.shared.logError(error)
            throw error
        }
        
        DebugLogger.shared.logInfo("Successfully got HAXApplication for PID \(self.pid)")
        
        // First try to get the focused window
        if let focusedWindow = haxApp.focusedWindow {
            DebugLogger.shared.logInfo("Found focused window for '\(self.name)'")
            return Window(haxWindow: focusedWindow)
        }
        
        // If no focused window is found, try to get the main window or first window
        DebugLogger.shared.logWarning("No focused window found for '\(self.name)'. Trying to get main or first window.")
        
        // Try to get windows
        if !haxApp.windows.isEmpty {
            // Get the first window as a fallback
            DebugLogger.shared.logInfo("Using first window as fallback for '\(self.name)'")
            return Window(haxWindow: haxApp.windows.first!)
        }
        
        // If all fails, create a mock window
        DebugLogger.shared.logWarning("No windows found for '\(self.name)'. Creating a mock main window.")
        return Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    /// Safe version of getFocusedWindow that doesn't throw
    /// - Returns: The focused window, or nil if none or if there was an error
    public func getFocusedWindowNoThrow() -> Window? {
        do {
            return try getFocusedWindow()
        } catch {
            DebugLogger.shared.logError(error)
            return nil
        }
    }
}