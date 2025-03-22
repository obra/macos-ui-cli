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
            throw WindowError.windowNotFound(description: "Window with title '\(title)'")
        }
        
        return try withTimeoutAndRetry(timeout: 5.0, maxAttempts: 2, delay: 0.5) { [self] in
            guard let views = haxWindow.views else {
                throw WindowError.windowNotResponding(description: "Window with title '\(self.title)' - cannot get views")
            }
            
            // Since HAXView is a subclass of HAXElement, we can cast directly
            return views.map { Element(haxElement: $0) }
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
        // Access the HAXApplication through SystemAccessibility
        guard let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) else {
            throw ApplicationManagerError.applicationNotFound(description: "Application with name '\(self.name)' (pid: \(self.pid))")
        }
        
        if haxApp.windows.isEmpty {
            throw ApplicationManagerError.applicationNotResponding(name: self.name)
        }
        
        return haxApp.windows.map { Window(haxWindow: $0) }
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
        // Access the HAXApplication through SystemAccessibility
        guard let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) else {
            throw ApplicationManagerError.applicationNotFound(description: "Application with name '\(self.name)' (pid: \(self.pid))")
        }
        
        return haxApp.focusedWindow.map { Window(haxWindow: $0) }
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