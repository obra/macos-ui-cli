// ABOUTME: This file provides a Swift wrapper around the HAXWindow class.
// ABOUTME: It enables manipulation and inspection of application windows.

import Foundation
import CoreGraphics

#if HAXCESSIBILITY_AVAILABLE
import Haxcessibility
#endif

/// Represents a window from a macOS application
public class Window {
    private var haxWindow: Any? = nil
    
    /// The title of the window
    public var title: String = ""
    
    /// The frame of the window in screen coordinates
    public var frame: CGRect = .zero
    
    /// Whether the window is fullscreen
    public var isFullscreen: Bool = false
    
    /// Creates a Window instance from a HAXWindow instance
    /// - Parameter haxWindow: The HAXWindow instance
    init(haxWindow: Any?) {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxWindow = haxWindow as? HAXWindow {
            self.haxWindow = haxWindow
            self.title = haxWindow.title ?? "Untitled Window"
            self.frame = haxWindow.frame
            self.isFullscreen = haxWindow.isFullscreen
        }
        #else
        self.haxWindow = nil
        #endif
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
        #if HAXCESSIBILITY_AVAILABLE
        if let haxWindow = self.haxWindow as? HAXWindow {
            return haxWindow.raise()
        }
        #endif
        return false
    }
    
    /// Closes the window
    /// - Returns: Whether the operation was successful
    public func close() -> Bool {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxWindow = self.haxWindow as? HAXWindow {
            return haxWindow.close()
        }
        #endif
        return false
    }
    
    /// Gets the CoreGraphics window ID
    /// - Returns: The window ID or 0 if not available
    public func getCGWindowID() -> CGWindowID {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxWindow = self.haxWindow as? HAXWindow {
            return haxWindow.cgWindowID()
        }
        #endif
        return 0
    }
    
    /// Gets the UI elements in the window
    /// - Returns: An array of UI elements in the window
    public func getElements() -> [Element] {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxWindow = self.haxWindow as? HAXWindow, 
           let views = haxWindow.views {
            return views.compactMap { Element(haxElement: $0) }
        }
        #endif
        return []
    }
}

// Extend Application to use the Window class
extension Application {
    /// Gets the windows of the application
    /// - Returns: An array of windows
    public func getWindows() -> [Window] {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxApp = self.haxApplication as? HAXApplication {
            return haxApp.windows.map { Window(haxWindow: $0) }
        }
        #endif
        return []
    }
    
    /// Gets the focused window of the application
    /// - Returns: The focused window, or nil if none
    public func getFocusedWindow() -> Window? {
        #if HAXCESSIBILITY_AVAILABLE
        if let haxApp = self.haxApplication as? HAXApplication,
           let focusedWindow = haxApp.focusedWindow {
            return Window(haxWindow: focusedWindow)
        }
        #endif
        return nil
    }
}