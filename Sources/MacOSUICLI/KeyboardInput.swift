// ABOUTME: This file provides utilities for simulating keyboard input.
// ABOUTME: It enables typing text and key combinations into applications.

import Foundation
import CoreGraphics

/// Utility for simulating keyboard input
public class KeyboardInput {
    /// The available modifier keys
    public enum Modifier {
        case command
        case option
        case control
        case shift
        
        /// Gets the CGEventFlags for this modifier
        var flag: CGEventFlags {
            switch self {
            case .command:
                return .maskCommand
            case .option:
                return .maskAlternate
            case .control:
                return .maskControl
            case .shift:
                return .maskShift
            }
        }
    }
    
    /// Simulates typing a string
    /// - Parameter string: The string to type
    /// - Throws: InputError if typing fails, AccessibilityError if permissions are not granted
    public static func typeString(_ string: String) throws {
        // Use CGEvent to simulate keyboard input
        // Implementation based on accessibility permissions
        
        // Make sure we have accessibility permissions
        guard AccessibilityPermissions.checkPermission() == .granted else {
            throw AccessibilityError.permissionDenied
        }
        
        // Type each character in the string
        try withTimeout(10.0) {
            for char in string {
                try typeCharacter(char)
            }
        }
    }
    
    /// Types a single character
    /// - Parameter char: The character to type
    /// - Throws: InputError if typing fails
    private static func typeCharacter(_ char: Character) throws {
        // Get the key code for the character
        guard let keyCode = keyCodeFor(char) else {
            throw InputError.keyboardInputFailed(key: String(char), reason: "Unknown key code")
        }
        
        // Check if we need shift for this character
        let needsShift = char.isUppercase || "~!@#$%^&*()_+{}|:\"<>?".contains(char)
        
        // Create the key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, 
                                        virtualKey: keyCode, 
                                        keyDown: true) else {
            throw InputError.keyboardInputFailed(key: String(char), reason: "Failed to create key down event")
        }
        
        // Apply shift if needed
        if needsShift {
            keyDownEvent.flags = .maskShift
        }
        
        // Post the key down event
        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
        
        // Create the key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, 
                                      virtualKey: keyCode, 
                                      keyDown: false) else {
            throw InputError.keyboardInputFailed(key: String(char), reason: "Failed to create key up event")
        }
        
        // Apply shift if needed
        if needsShift {
            keyUpEvent.flags = .maskShift
        }
        
        // Post the key up event
        keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    /// Gets the virtual key code for a character
    /// - Parameter char: The character
    /// - Returns: The key code, or nil if unknown
    private static func keyCodeFor(_ char: Character) -> CGKeyCode? {
        // This is a simplified mapping - a real implementation would have a complete map
        let lowercased = String(char).lowercased()
        
        if lowercased.count == 1 {
            switch lowercased.first! {
            case "a": return 0
            case "s": return 1
            case "d": return 2
            case "f": return 3
            case "h": return 4
            case "g": return 5
            case "z": return 6
            case "x": return 7
            case "c": return 8
            case "v": return 9
            case "b": return 11
            case "q": return 12
            case "w": return 13
            case "e": return 14
            case "r": return 15
            case "y": return 16
            case "t": return 17
            case "1", "!": return 18
            case "2", "@": return 19
            case "3", "#": return 20
            case "4", "$": return 21
            case "6", "^": return 22
            case "5", "%": return 23
            case "=", "+": return 24
            case "9", "(": return 25
            case "7", "&": return 26
            case "-", "_": return 27
            case "8", "*": return 28
            case "0", ")": return 29
            case "]", "}": return 30
            case "o": return 31
            case "u": return 32
            case "[", "{": return 33
            case "i": return 34
            case "p": return 35
            case "l": return 37
            case "j": return 38
            case "'", "\"": return 39
            case "k": return 40
            case ";", ":": return 41
            case "\\", "|": return 42
            case ",", "<": return 43
            case "/", "?": return 44
            case "n": return 45
            case "m": return 46
            case ".", ">": return 47
            case " ": return 49
            default: return nil
            }
        }
        
        return nil
    }
    
    /// Simulates pressing a key combination
    /// - Parameters:
    ///   - modifiers: Array of modifier keys to press
    ///   - key: The main key to press
    /// - Throws: InputError if key combination fails, AccessibilityError if permissions are not granted
    public static func pressKeyCombination(_ modifiers: [Modifier], key: String) throws {
        // Make sure we have accessibility permissions
        guard AccessibilityPermissions.checkPermission() == .granted else {
            throw AccessibilityError.permissionDenied
        }
        
        // Make sure the key is not empty
        guard !key.isEmpty else {
            throw InputError.keyboardInputFailed(key: "empty", reason: "Key cannot be empty")
        }
        
        // Get the key code for the character
        guard let keyChar = key.first,
              let keyCode = keyCodeFor(keyChar) else {
            throw InputError.keyboardInputFailed(key: key, reason: "Unknown key code")
        }
        
        // Combine modifier flags
        var flags: CGEventFlags = []
        for modifier in modifiers {
            flags.insert(modifier.flag)
        }
        
        try withTimeout(5.0) {
            // Create the key down event
            guard let keyDownEvent = CGEvent(keyboardEventSource: nil, 
                                           virtualKey: keyCode, 
                                           keyDown: true) else {
                throw InputError.keyboardInputFailed(key: key, reason: "Failed to create key down event")
            }
            
            // Apply modifiers
            keyDownEvent.flags = flags
            
            // Post the key down event
            keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
            
            // Create the key up event
            guard let keyUpEvent = CGEvent(keyboardEventSource: nil, 
                                         virtualKey: keyCode, 
                                         keyDown: false) else {
                throw InputError.keyboardInputFailed(key: key, reason: "Failed to create key up event")
            }
            
            // Apply modifiers
            keyUpEvent.flags = flags
            
            // Post the key up event
            keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
    
    /// Safe version of typeString that doesn't throw
    /// - Parameter string: The string to type
    /// - Returns: True if successful, false otherwise
    public static func typeStringNoThrow(_ string: String) -> Bool {
        do {
            try typeString(string)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
    
    /// Safe version of pressKeyCombination that doesn't throw
    /// - Parameters:
    ///   - modifiers: Array of modifier keys to press
    ///   - key: The main key to press
    /// - Returns: True if successful, false otherwise
    public static func pressKeyCombinationNoThrow(_ modifiers: [Modifier], key: String) -> Bool {
        do {
            try pressKeyCombination(modifiers, key: key)
            return true
        } catch {
            DebugLogger.shared.logError(error)
            return false
        }
    }
}