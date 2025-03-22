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
    
    /// Creates a Window instance from a HAXWindow instance
    /// - Parameter haxWindow: The HAXWindow instance
    init(haxWindow: HAXWindow?) {
        self.haxWindow = haxWindow
        self.title = haxWindow?.title ?? "Untitled Window"
        self.frame = haxWindow?.frame ?? .zero
        self.isFullscreen = haxWindow?.isFullscreen ?? false
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
    /// - Returns: Whether the operation was successful
    public func raise() -> Bool {
        if let haxWindow = self.haxWindow {
            return haxWindow.raise()
        }
        return false
    }
    
    /// Closes the window
    /// - Returns: Whether the operation was successful
    public func close() -> Bool {
        if let haxWindow = self.haxWindow {
            return haxWindow.close()
        }
        return false
    }
    
    /// Gets the CoreGraphics window ID
    /// - Returns: The window ID or 0 if not available
    public func getCGWindowID() -> CGWindowID {
        if let haxWindow = self.haxWindow {
            return haxWindow.cgWindowID()
        }
        return 0
    }
    
    /// Gets the UI elements in the window
    /// - Returns: An array of UI elements in the window
    public func getElements() -> [Element] {
        if let haxWindow = self.haxWindow, let views = haxWindow.views {
            // Since HAXView is a subclass of HAXElement, we can cast directly
            return views.map { Element(haxElement: $0) }
        }
        return []
    }
}

// Extend Application to use the Window class
extension Application {
    /// Gets the windows of the application
    /// - Returns: An array of windows
    public func getWindows() -> [Window] {
        // Access the HAXApplication through SystemAccessibility
        if let haxApp = SystemAccessibility.getApplicationWithPID(self.pid) {
            return haxApp.windows.map { Window(haxWindow: $0) }
        }
        return []
    }
    
    /// Gets the focused window of the application
    /// - Returns: The focused window, or nil if none
    public func getFocusedWindow() -> Window? {
        // Access the HAXApplication through SystemAccessibility
        if let haxApp = SystemAccessibility.getApplicationWithPID(self.pid),
           let focusedWindow = haxApp.focusedWindow {
            return Window(haxWindow: focusedWindow)
        }
        return nil
    }
}