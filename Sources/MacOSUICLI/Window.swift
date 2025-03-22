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
    
    /// Sets focus to this window
    /// - Returns: True if successful, false otherwise
    public func focus() -> Bool {
        if let haxWindow = self.haxWindow {
            // Raise the window first
            if raise() {
                // Also set the focused attribute if available
                do {
                    try haxWindow.setAttributeValue(true as CFTypeRef, forKey: "AXFocused")
                } catch {
                    // Ignore errors - the raise() might be sufficient
                }
                return true
            }
        }
        return false
    }
    
    /// Sets the position of the window
    /// - Parameter position: The new position
    /// - Returns: True if successful, false otherwise
    public func setPosition(_ position: CGPoint) -> Bool {
        if let haxWindow = self.haxWindow {
            // Set the position attribute
            do {
                try haxWindow.setAttributeValue(NSValue(point: position) as CFTypeRef, forKey: "AXPosition")
                self.frame.origin = position
                return true
            } catch {
                return false
            }
        }
        
        // For testing or mock objects, just update the frame
        self.frame.origin = position
        return true
    }
    
    /// Sets the size of the window
    /// - Parameter size: The new size
    /// - Returns: True if successful, false otherwise
    public func setSize(_ size: CGSize) -> Bool {
        if let haxWindow = self.haxWindow {
            // Set the size attribute
            do {
                try haxWindow.setAttributeValue(NSValue(size: size) as CFTypeRef, forKey: "AXSize")
                self.frame.size = size
                return true
            } catch {
                return false
            }
        }
        
        // For testing or mock objects, just update the frame
        self.frame.size = size
        return true
    }
    
    /// Moves and resizes the window in one operation
    /// - Parameter frame: The new frame
    /// - Returns: True if successful, false otherwise
    public func setFrame(_ frame: CGRect) -> Bool {
        let positionSuccess = setPosition(frame.origin)
        let sizeSuccess = setSize(frame.size)
        
        return positionSuccess && sizeSuccess
    }
    
    /// Toggles the window between fullscreen and normal state
    /// - Returns: True if successful, false otherwise
    public func toggleFullscreen() -> Bool {
        if let haxWindow = self.haxWindow {
            // Toggle fullscreen by performing the fullscreen action
            do {
                try haxWindow.performAction("AXToggleFullScreen")
                self.isFullscreen = !self.isFullscreen
                return true
            } catch {
                return false
            }
        }
        
        // For testing or mock objects
        self.isFullscreen = !self.isFullscreen
        return true
    }
    
    /// Minimizes the window
    /// - Returns: True if successful, false otherwise
    public func minimize() -> Bool {
        if let haxWindow = self.haxWindow {
            // Minimize by setting the minimized attribute
            do {
                try haxWindow.setAttributeValue(true as CFTypeRef, forKey: "AXMinimized")
                self.isMinimized = true
                return true
            } catch {
                return false
            }
        }
        
        // For testing or mock objects
        self.isMinimized = true
        return true
    }
    
    /// Restores a minimized window
    /// - Returns: True if successful, false otherwise
    public func restore() -> Bool {
        if let haxWindow = self.haxWindow {
            // Restore by setting the minimized attribute to false
            do {
                try haxWindow.setAttributeValue(false as CFTypeRef, forKey: "AXMinimized")
                self.isMinimized = false
                return true
            } catch {
                return false
            }
        }
        
        // For testing or mock objects
        self.isMinimized = false
        return true
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