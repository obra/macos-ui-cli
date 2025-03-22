// ABOUTME: This file contains commands for interacting with UI elements.
// ABOUTME: These commands allow users to manipulate windows, press buttons, input text, etc.

import Foundation
import ArgumentParser
import CoreGraphics
import Haxcessibility

/// Group for all interaction-related commands
public struct InteractionCommands: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "interact",
        abstract: "Commands for interacting with UI elements",
        discussion: """
        The interaction commands allow you to manipulate UI elements like windows, buttons, 
        and text fields, and simulate keyboard input.
        
        Examples:
          macos-ui-cli interact button --app "Calculator" --title "=" --press
          macos-ui-cli interact text --app "Notes" --field "Body" --value "Hello, World!"
          macos-ui-cli interact window --app "Safari" --position "100,100" --size "800,600"
          macos-ui-cli interact keyboard --text "Hello, World!"
        """,
        subcommands: [
            ButtonCommand.self,
            TextCommand.self,
            WindowCommand.self,
            KeyboardCommand.self
        ],
        defaultSubcommand: nil
    )
    
    public init() {}
}

/// Command for button operations
public struct ButtonCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "button",
        abstract: "Interact with buttons",
        discussion: """
        Find and press buttons in applications.
        
        Examples:
          macos-ui-cli interact button --app "Calculator" --title "=" --press
          macos-ui-cli interact button --app "Safari" --title "Go" --press
        """
    )
    
    @Flag(name: .shortAndLong, help: "Press the button")
    var press = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .shortAndLong, help: "The title of the button")
    var title: String
    
    public init() {}
    
    public func run() throws {
        let errorHandler = ErrorHandler.shared
        
        // Validate arguments
        do {
            try Validation.validateApplicationName(app)
            try Validation.validateElementTitle(title)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        // Get the application
        var application: Application?
        do {
            application = try ApplicationManager.getApplicationByName(app)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        guard let appInstance = application else {
            print(errorHandler.handle(ApplicationManagerError.applicationNotFound(description: "Application with name '\(app)'")))
            return
        }
        
        // Get the focused window
        var focusedWindow: Window?
        do {
            focusedWindow = try appInstance.getFocusedWindow()
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        guard let window = focusedWindow else {
            print(errorHandler.handle(WindowError.windowNotFound(description: "Focused window for \(app)")))
            return
        }
        
        // Get elements in the window
        var windowElements: [Element] = []
        do {
            windowElements = try window.getElements()
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        let rootElement = windowElements.first ?? Element(role: "window", title: window.title)
        
        // Find button by title
        var matchingButtons: [Element] = []
        do {
            matchingButtons = try ElementFinder.findElements(in: rootElement, byRole: "button", byTitle: title)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        if matchingButtons.isEmpty {
            print(errorHandler.handle(UIElementError.elementNotFound(description: "Button with title '\(title)'")))
            return
        }
        
        // Convert to ButtonElement
        let buttonElement = ButtonElement.fromElement(matchingButtons.first!)
        
        guard let button = buttonElement else {
            print(errorHandler.handle(UIElementError.invalidElementState(
                description: "Element with title '\(title)'",
                state: "Not a valid button element"
            )))
            return
        }
        
        // Press the button
        if press {
            do {
                try withTimeout(5.0) {
                    try button.press()
                }
                print("Successfully pressed button '\(title)'")
            } catch {
                print(errorHandler.handle(error))
            }
        } else {
            print("Button '\(title)' found but no action specified")
            print("Use --press to press the button")
        }
    }
}

/// Command for text field operations
public struct TextCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Read from or write to text fields",
        discussion: """
        Read or write text in text fields.
        
        Examples:
          macos-ui-cli interact text --app "Notes" --field "Body" --value "Hello, World!"
          macos-ui-cli interact text --app "Safari" --field "Search" --read
        """
    )
    
    @Flag(name: .shortAndLong, help: "Read text from the field instead of writing")
    var read = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .shortAndLong, help: "The title of the text field")
    var field: String
    
    @Option(name: .shortAndLong, help: "The text to write (required for write operation)")
    var value: String?
    
    public init() {}
    
    public func run() throws {
        let errorHandler = ErrorHandler.shared
        
        // Validate arguments
        do {
            try Validation.validateApplicationName(app)
            try Validation.validateElementTitle(field)
            
            if !read && value == nil {
                throw ValidationError.invalidArgument(
                    name: "value",
                    reason: "Text value is required for write operation"
                )
            }
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        // Get the application
        var application: Application?
        do {
            application = try ApplicationManager.getApplicationByName(app)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        guard let appInstance = application else {
            print(errorHandler.handle(ApplicationManagerError.applicationNotFound(description: "Application with name '\(app)'")))
            return
        }
        
        // Get the focused window
        var focusedWindow: Window?
        do {
            focusedWindow = try appInstance.getFocusedWindow()
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        guard let window = focusedWindow else {
            print(errorHandler.handle(WindowError.windowNotFound(description: "Focused window for \(app)")))
            return
        }
        
        // Get elements in the window
        var windowElements: [Element] = []
        do {
            windowElements = try window.getElements()
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        let rootElement = windowElements.first ?? Element(role: "window", title: window.title)
        
        // Find text field by title
        var matchingTextFields: [Element] = []
        do {
            matchingTextFields = try ElementFinder.findElements(in: rootElement, byRole: "textField", byTitle: field)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        if matchingTextFields.isEmpty {
            print(errorHandler.handle(UIElementError.elementNotFound(description: "Text field with title '\(field)'")))
            return
        }
        
        // Convert to TextFieldElement
        let textFieldElement = TextFieldElement.fromElement(matchingTextFields.first!)
        
        guard let textField = textFieldElement else {
            print(errorHandler.handle(UIElementError.invalidElementState(
                description: "Element with title '\(field)'",
                state: "Not a valid text field element"
            )))
            return
        }
        
        // Perform read or write operation
        if read {
            do {
                let textValue = try withTimeout(5.0) {
                    try textField.getValue()
                }
                print("Value of text field '\(field)': \(textValue)")
            } catch {
                print(errorHandler.handle(error))
            }
        } else {
            guard let newValue = value else {
                // This should never happen due to validation above
                return
            }
            
            do {
                try withTimeout(5.0) {
                    try textField.setValue(newValue)
                }
                print("Successfully set text field '\(field)' to: \(newValue)")
            } catch {
                print(errorHandler.handle(error))
            }
        }
    }
}

/// Command for window manipulation
public struct WindowCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "window",
        abstract: "Manipulate windows",
        discussion: """
        Move, resize, focus, or otherwise manipulate windows.
        
        Examples:
          macos-ui-cli interact window --app "Safari" --position "100,100" --size "800,600"
          macos-ui-cli interact window --app "Finder" --focus
          macos-ui-cli interact window --app "Terminal" --minimize
          macos-ui-cli interact window --app "Photos" --fullscreen
        """
    )
    
    @Flag(name: .long, help: "Focus the window")
    var focus = false
    
    @Flag(name: .long, help: "Raise the window to the front")
    var raise = false
    
    @Flag(name: .long, help: "Close the window")
    var close = false
    
    @Flag(name: .long, help: "Minimize the window")
    var minimize = false
    
    @Flag(name: .long, help: "Restore a minimized window")
    var restore = false
    
    @Flag(name: .long, help: "Toggle fullscreen mode")
    var fullscreen = false
    
    @Option(name: .shortAndLong, help: "The application to target", completion: .list(["Safari", "Notes", "Terminal"]))
    var app: String
    
    @Option(name: .long, help: "The title of the window (defaults to focused window)")
    var title: String?
    
    @Option(name: .long, help: "New position (format: 'x,y')")
    var position: String?
    
    @Option(name: .long, help: "New size (format: 'width,height')")
    var size: String?
    
    public init() {}
    
    public func run() throws {
        let errorHandler = ErrorHandler.shared
        
        // Validate arguments
        do {
            try Validation.validateApplicationName(app)
            
            if let positionString = position {
                try Validation.validatePositionFormat(positionString)
            }
            
            if let sizeString = size {
                try Validation.validateSizeFormat(sizeString)
            }
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        // Get the application
        var application: Application?
        do {
            application = try ApplicationManager.getApplicationByName(app)
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        guard let appInstance = application else {
            print(errorHandler.handle(ApplicationManagerError.applicationNotFound(description: "Application with name '\(app)'")))
            return
        }
        
        // Get the window
        var window: Window? = nil
        
        if let windowTitle = title {
            // Try to find a window with the specified title
            var windows: [Window] = []
            do {
                windows = try appInstance.getWindows()
            } catch {
                print(errorHandler.handle(error))
                return
            }
            
            window = windows.first { $0.title == windowTitle }
            
            if window == nil {
                print(errorHandler.handle(WindowError.windowNotFound(description: "Window with title '\(windowTitle)'")))
                return
            }
        } else {
            // Try to get the focused window
            do {
                window = try appInstance.getFocusedWindow()
            } catch {
                print(errorHandler.handle(error))
                return
            }
            
            if window == nil {
                print(errorHandler.handle(WindowError.windowNotFound(description: "Focused window for \(app)")))
                return
            }
        }
        
        guard let targetWindow = window else { return }
        print("Window: \(targetWindow.title)")
        
        // Handle position change
        if let positionString = position {
            let components = positionString.split(separator: ",")
            if components.count == 2,
               let x = Double(components[0]),
               let y = Double(components[1]) {
                
                let newPosition = CGPoint(x: x, y: y)
                do {
                    try withTimeout(5.0) {
                        try targetWindow.setPosition(newPosition)
                    }
                    print("Successfully moved window to position: \(newPosition)")
                } catch {
                    print(errorHandler.handle(error))
                }
            }
        }
        
        // Handle size change
        if let sizeString = size {
            let components = sizeString.split(separator: ",")
            if components.count == 2,
               let width = Double(components[0]),
               let height = Double(components[1]) {
                
                let newSize = CGSize(width: width, height: height)
                do {
                    try withTimeout(5.0) {
                        try targetWindow.setSize(newSize)
                    }
                    print("Successfully resized window to: \(newSize)")
                } catch {
                    print(errorHandler.handle(error))
                }
            }
        }
        
        // Handle other window operations
        if focus {
            do {
                try withTimeout(5.0) {
                    try targetWindow.focus()
                }
                print("Successfully focused window")
            } catch {
                print(errorHandler.handle(error))
            }
        }
        
        if raise {
            do {
                try withTimeout(5.0) {
                    try targetWindow.raise()
                }
                print("Successfully raised window")
            } catch {
                print(errorHandler.handle(error))
            }
        }
        
        if minimize {
            do {
                try withTimeout(5.0) {
                    try targetWindow.minimize()
                }
                print("Successfully minimized window")
            } catch {
                print(errorHandler.handle(error))
            }
        }
        
        if restore {
            do {
                try withTimeout(5.0) {
                    try targetWindow.restore()
                }
                print("Successfully restored window")
            } catch {
                print(errorHandler.handle(error))
            }
        }
        
        if fullscreen {
            do {
                try withTimeout(5.0) {
                    try targetWindow.toggleFullscreen()
                }
                print("Successfully toggled fullscreen mode")
            } catch {
                print(errorHandler.handle(error))
            }
        }
        
        if close {
            do {
                try withTimeout(5.0) {
                    try targetWindow.close()
                }
                print("Successfully closed window")
            } catch {
                print(errorHandler.handle(error))
            }
        }
    }
}

/// Command for keyboard input
public struct KeyboardCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "keyboard",
        abstract: "Simulate keyboard input",
        discussion: """
        Simulate typing text or pressing key combinations.
        
        Examples:
          macos-ui-cli interact keyboard --text "Hello, World!"
          macos-ui-cli interact keyboard --combo "cmd+c"
          macos-ui-cli interact keyboard --combo "cmd+option+esc"
        """
    )
    
    @Option(name: .shortAndLong, help: "Text to type")
    var text: String?
    
    @Option(name: .shortAndLong, help: "Key combination to press (e.g., cmd+c, cmd+option+esc)")
    var combo: String?
    
    public init() {}
    
    public func run() throws {
        let errorHandler = ErrorHandler.shared
        
        // Validate arguments
        do {
            if text == nil && combo == nil {
                throw ValidationError.invalidArgument(
                    name: "input",
                    reason: "Either text or combo must be specified"
                )
            }
            
            if text != nil && combo != nil {
                throw ValidationError.invalidArgument(
                    name: "input",
                    reason: "Cannot specify both text and combo at the same time"
                )
            }
            
            if let combination = combo {
                // Validate the combination format
                let parts = combination.lowercased().split(separator: "+")
                if parts.count < 2 {
                    throw ValidationError.invalidArgument(
                        name: "combo",
                        reason: "Invalid key combination format. Use format like 'cmd+c'"
                    )
                }
                
                // Validate modifiers
                for i in 0..<parts.count-1 {
                    let part = String(parts[i])
                    let validModifiers = ["cmd", "command", "opt", "option", "alt", "ctrl", "control", "shift"]
                    if !validModifiers.contains(part) {
                        throw ValidationError.invalidArgument(
                            name: "combo",
                            reason: "Unknown modifier: \(part)"
                        )
                    }
                }
            }
        } catch {
            print(errorHandler.handle(error))
            return
        }
        
        // Check accessibility permissions
        let permissionStatus = AccessibilityPermissions.checkPermission()
        if permissionStatus != .granted {
            print(errorHandler.handle(AccessibilityError.permissionDenied))
            return
        }
        
        // Handle text typing
        if let textInput = text {
            do {
                try withTimeout(10.0) {
                    try KeyboardInput.typeString(textInput)
                }
                print("Successfully typed text")
            } catch {
                print(errorHandler.handle(error))
            }
            return
        }
        
        // Handle key combination
        if let combination = combo {
            do {
                // Parse the combination (e.g., "cmd+c", "cmd+option+esc")
                let parts = combination.lowercased().split(separator: "+")
                var modifiers: [KeyboardInput.Modifier] = []
                
                // The last part is the key, everything else is a modifier
                for i in 0..<parts.count-1 {
                    let part = String(parts[i])
                    switch part {
                    case "cmd", "command":
                        modifiers.append(.command)
                    case "opt", "option", "alt":
                        modifiers.append(.option)
                    case "ctrl", "control":
                        modifiers.append(.control)
                    case "shift":
                        modifiers.append(.shift)
                    default:
                        // Should never happen due to validation above
                        break
                    }
                }
                
                // The last part is the key
                let key = String(parts.last!)
                
                try withTimeout(5.0) {
                    try KeyboardInput.pressKeyCombination(modifiers, key: key)
                }
                print("Successfully pressed key combination")
            } catch {
                print(errorHandler.handle(error))
            }
            return
        }
    }
}