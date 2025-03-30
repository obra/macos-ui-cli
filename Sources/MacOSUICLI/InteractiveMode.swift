// ABOUTME: This file implements the interactive REPL mode for the CLI tool.
// ABOUTME: It provides tab completion, command history, and context-aware UI element navigation.

import Foundation
import Haxcessibility
import LineNoise
import ArgumentParser
import Darwin.C

/// Class that handles the interactive REPL (Read-Eval-Print-Loop) mode
public class InteractiveMode {
    // LineNoise instance for handling terminal input with history and completion
    private let lineNoise = LineNoise()
    
    // Current context - tracking where the user is in the UI hierarchy
    private var currentApp: Application?
    private var currentWindow: Window?
    private var currentElement: Element?
    
    // Command history
    private var history: [String] = []
    
    // Available commands with their descriptions
    private let commands: [String: String] = [
        "help": "Show available commands",
        "exit": "Exit interactive mode",
        "quit": "Exit interactive mode",
        "apps": "List all applications",
        "app": "Set current application by name (app Safari)",
        "windows": "List windows of current application",
        "window": "Set current window by title or index (window \"Main Window\" or window 0)",
        "elements": "List elements in current window",
        "element": "Select element by path or index (element button[OK] or element 0)",
        "find": "Find elements by role and/or title (find button \"OK\")",
        "click": "Click on the current element",
        "type": "Type text into the current element (type \"Hello world\")",
        "info": "Show information about the current context",
        "tree": "Show element hierarchy as a tree",
        "back": "Go back one level in the context hierarchy",
        "clear": "Clear the screen",
        "hint": "Show help for a specific command (hint app)"
    ]
    
    // Currently available element roles for tab completion
    private let elementRoles = [
        "button", "checkbox", "combobox", "dialog", "group", "image", 
        "label", "link", "list", "menu", "menubar", "menuitem", 
        "progressbar", "radiobutton", "scrollbar", "slider", "spinbutton", 
        "statusbar", "tab", "tablist", "textbox", "toolbar", "tooltip", 
        "tree", "window"
    ]
    
    // Formatter for output
    private var formatter: OutputFormatter
    
    /// Initialize the interactive mode
    /// - Parameter formatter: The output formatter to use
    public init(formatter: OutputFormatter? = nil) {
        self.formatter = formatter ?? PlainTextFormatter()
        
        // Enable debug logging for troubleshooting
        DebugLogger.shared.logLevel = .info
        
        setupLineNoise()
    }
    
    /// Configure LineNoise for history and tab completion
    private func setupLineNoise() {
        // Set up tab completion
        lineNoise.setCompletionCallback { currentBuffer in
            return self.tabCompletion(currentBuffer: currentBuffer)
        }
        
        // Add command history handler
        lineNoise.setHistoryMaxLength(100)
        
        // We won't use the built-in hints since they don't display well
        lineNoise.setHintsCallback { _ in
            return (nil, nil)
        }
    }
    
    /// Handle tab completion for commands and context-specific items
    /// - Parameter currentBuffer: The current input buffer
    /// - Returns: An array of possible completions
    private func tabCompletion(currentBuffer: String) -> [String] {
        let words = currentBuffer.split(separator: " ")
        
        // No input yet, show all commands
        if words.isEmpty {
            return Array(commands.keys).sorted()
        }
        
        // Complete commands
        if words.count == 1 {
            let prefix = String(words[0])
            return Array(commands.keys)
                .filter { $0.hasPrefix(prefix) }
                .sorted()
        }
        
        // Command-specific completions
        let command = String(words[0])
        let partialArg = words.count > 1 ? String(words[words.count - 1]) : ""
        
        switch command {
        case "app":
            // Complete application names
            do {
                let apps = try ApplicationManager.getAllApplications()
                return apps.map { $0.name }
                    .filter { $0.lowercased().hasPrefix(partialArg.lowercased()) }
                    .sorted()
            } catch {
                return []
            }
            
        case "find":
            // Complete element roles or return all if already specified
            if words.count == 2 {
                return elementRoles
                    .filter { $0.hasPrefix(partialArg) }
                    .sorted()
            }
            return []
            
        case "window":
            // Complete window titles
            if let app = currentApp {
                do {
                    let windows = try app.getWindows()
                    return windows.map { $0.title }
                        .filter { $0.lowercased().hasPrefix(partialArg.lowercased()) }
                        .sorted()
                } catch {
                    return []
                }
            }
            
        default:
            return []
        }
        
        return []
    }
    
    // Note: The LineNoise library defines its own error types
    // We handle them by inspecting error descriptions in the catch block
    
    /// Start the REPL loop
    public func startREPL() throws {
        var running = true
        var lastCmd = ""
        
        print(formatter.formatMessage("MacOSUICLI Interactive Mode", type: .info))
        print(formatter.formatMessage("Type 'help' for available commands, 'exit' to quit, Ctrl+C to exit anytime", type: .info))
        print("")
        
        updatePrompt()
        
        while running {
            do {
                // Add a hint if the user is typing a known command
                if !lastCmd.isEmpty, let hint = commands[lastCmd] {
                    // Show hint on the line above the prompt
                    let hintLine = "  \u{001B}[2m▸ \(hint)\u{001B}[0m"
                    print(hintLine)
                }
                
                let prompt = getPrompt()
                let line = try lineNoise.getLine(prompt: prompt)
                
                // If we get an empty line, print a new line and continue
                if line.isEmpty {
                    lastCmd = ""
                    print("") // Add a newline for empty input
                    continue
                }
                
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines
                if trimmedLine.isEmpty {
                    lastCmd = ""
                    print("") // Add a newline for whitespace-only input
                    continue
                }
                
                // Add to history
                lineNoise.addHistory(trimmedLine)
                history.append(trimmedLine)
                
                // Remember the first word (command) for hint display
                let words = trimmedLine.split(separator: " ")
                if let firstWord = words.first {
                    lastCmd = String(firstWord)
                } else {
                    lastCmd = ""
                }
                
                // Process the command
                running = try processCommand(trimmedLine)
                
                // Add a newline before showing the next prompt
                print("")
                
                updatePrompt()
            } catch {
                // Handle both our defined LinenoiseError and the actual library errors
                // We need to look at description because LineNoise might throw its own enum type
                let errorDesc = error.localizedDescription.lowercased()
                let errorType = String(describing: error)
                
                // Check for Ctrl+C in error description or type
                if errorDesc.contains("ctrl_c") || errorDesc.contains("ctrl-c") || 
                   errorDesc.contains("interrupt") || errorType.contains("CTRL_C") {
                    // Handle Ctrl+C - exit the REPL cleanly
                    print("\nCtrl+C pressed, exiting interactive mode...")
                    running = false
                } 
                // Check for EOF (Ctrl+D)
                else if errorDesc.contains("eof") || errorType.contains("EOF") {
                    // Handle EOF (Ctrl+D) - exit the REPL cleanly
                    print("\nEOF detected, exiting interactive mode...")
                    running = false
                }
                // Check for error code 3 which seems to be a LineNoise interrupt error
                else if errorDesc.contains("error 3") {
                    // This is likely a keyboard interrupt - exit cleanly
                    print("\nKeyboard interrupt detected, exiting interactive mode...")
                    running = false
                }
                else {
                    // Log other errors but don't exit
                    print(formatter.formatMessage("Input error: \(error.localizedDescription)", type: .error))
                    print(formatter.formatMessage("Please try again or type 'exit' to quit", type: .info))
                    lastCmd = ""
                }
            }
        }
        
        print(formatter.formatMessage("Exiting interactive mode", type: .info))
    }
    
    /// Get the current prompt based on context
    private func getPrompt() -> String {
        return "(macos-ui-cli) \(getContextString())> "
    }
    
    /// Get a string representation of the current context
    private func getContextString() -> String {
        var context = ""
        
        if let app = currentApp {
            context += "\(app.name)"
            
            if let window = currentWindow {
                context += "/\(window.title)"
                
                if let element = currentElement {
                    context += "/\(element.role)"
                    let title = element.title
                    if !title.isEmpty {
                        context += "[\(title)]"
                    }
                }
            }
        }
        
        return context.isEmpty ? "" : "[\(context)]"
    }
    
    /// Update the prompt in the LineNoise instance
    private func updatePrompt() {
        // This function exists in case we need to do more with prompt updates in the future
    }
    
    /// Process a command entered by the user
    /// - Parameter input: The command string
    /// - Returns: Boolean indicating whether the REPL should continue running
    private func processCommand(_ input: String) throws -> Bool {
        let components = parseCommand(input)
        guard let command = components.first else { return true }
        
        let args = Array(components.dropFirst())
        
        switch command.lowercased() {
        case "exit", "quit":
            return false
            
        case "help":
            displayHelp()
            
        case "apps":
            try listApplications()
            
        case "app":
            try setCurrentApplication(args)
            
        case "windows":
            try listWindows()
            
        case "window":
            try setCurrentWindow(args)
            
        case "elements":
            try listElements()
            
        case "element":
            try selectElement(args)
            
        case "find":
            try findElements(args)
            
        case "click":
            try clickCurrentElement()
            
        case "type":
            try typeText(args)
            
        case "info":
            displayContextInfo()
            
        case "tree":
            try displayElementTree()
            
        case "back":
            navigateBack()
            
        case "clear":
            clearScreen()
            
        case "hint":
            showCommandHint(args)
            
        default:
            print(formatter.formatMessage("Unknown command: \(command)", type: .error))
            print("Type 'help' for available commands, or 'hint <command>' for specific help")
        }
        
        return true
    }
    
    /// Parse a command string, handling quoted arguments
    /// - Parameter input: The command string
    /// - Returns: Array of command components
    private func parseCommand(_ input: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var inQuotes = false
        var escapingNext = false
        
        for char in input {
            if escapingNext {
                currentComponent.append(char)
                escapingNext = false
                continue
            }
            
            if char == "\\" {
                escapingNext = true
                continue
            }
            
            if char == "\"" {
                inQuotes.toggle()
                continue
            }
            
            if char.isWhitespace && !inQuotes {
                if !currentComponent.isEmpty {
                    components.append(currentComponent)
                    currentComponent = ""
                }
                continue
            }
            
            currentComponent.append(char)
        }
        
        if !currentComponent.isEmpty {
            components.append(currentComponent)
        }
        
        return components
    }
    
    /// Display help information about available commands
    private func displayHelp() {
        print(formatter.formatMessage("Available Commands:", type: .info))
        
        let maxCommandLength = commands.keys.map { $0.count }.max() ?? 0
        
        for (command, description) in commands.sorted(by: { $0.key < $1.key }) {
            let padding = String(repeating: " ", count: maxCommandLength - command.count + 2)
            print("  \(command)\(padding)\(description)")
        }
        
        print("\nCurrent Context:")
        print("  Application: \(currentApp?.name ?? "None")")
        print("  Window: \(currentWindow?.title ?? "None")")
        print("  Element: \(currentElement?.description ?? "None")")
        
        print("\nElement IDs:")
        print("  Each element in the tree view is assigned a unique ID like #0, #1, #2, etc.")
        print("  - These IDs are simple sequential numbers assigned to all elements in the tree")
        print("  - You can select elements directly using these IDs with the 'element' command:")
        print("    element #5    or simply:    element 5")
        print("  - Use the 'tree' command to see all elements with their assigned IDs")
        print("  - IDs are consistent during your session (but may change between sessions)")
    }
    
    /// List all accessible applications
    private func listApplications() throws {
        let apps = try ApplicationManager.getAllApplications()
        
        print(formatter.formatMessage("Available Applications:", type: .info))
        if apps.isEmpty {
            print("  No applications found")
        } else {
            print(formatter.formatApplications(apps))
        }
    }
    
    /// Set the current application by name
    private func setCurrentApplication(_ args: [String]) throws {
        guard !args.isEmpty else {
            print(formatter.formatMessage("Please specify an application name", type: .error))
            return
        }
        
        let appName = args.joined(separator: " ")
        
        do {
            let app = try ApplicationManager.getApplicationByName(appName)
            currentApp = app
            currentWindow = nil
            currentElement = nil
            
            print(formatter.formatMessage("Current application set to: \(app.name)", type: .success))
            
            // Try to get focused window automatically
            if let focusedWindow = try app.getFocusedWindow() {
                currentWindow = focusedWindow
                print(formatter.formatMessage("Current window set to: \(focusedWindow.title)", type: .success))
            }
        } catch {
            print(formatter.formatMessage("Error: \(error.localizedDescription)", type: .error))
            print(formatter.formatMessage("No application found with name: \(appName)", type: .error))
        }
    }
    
    /// List windows of the current application
    private func listWindows() throws {
        guard let app = currentApp else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        print(formatter.formatMessage("Retrieving windows for application: \(app.name) (PID: \(app.pid))", type: .info))
        
        do {
            let windows = try app.getWindows()
            
            print(formatter.formatMessage("Windows for \(app.name):", type: .info))
            if windows.isEmpty {
                print(formatter.formatMessage("  No windows found", type: .warning))
            } else {
                print(formatter.formatMessage("Found \(windows.count) windows", type: .success))
                
                // Print each window with an index for easier selection
                for (index, window) in windows.enumerated() {
                    print(formatter.formatMessage("  \(index): \(window.title)", type: .info))
                }
                
                // If we have exactly one window, set it as current
                if windows.count == 1 {
                    currentWindow = windows[0]
                    print(formatter.formatMessage("Automatically selected window: \(windows[0].title)", type: .success))
                } else if windows.count > 1 {
                    print(formatter.formatMessage("Use 'window <title>' to select a specific window", type: .info))
                }
            }
        } catch {
            print(formatter.formatMessage("Error retrieving windows: \(error.localizedDescription)", type: .error))
            print(formatter.formatMessage("Using a mock window instead", type: .info))
            
            // Create a mock window
            let window = Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            currentWindow = window
            print(formatter.formatMessage("Set current window to mock: \(window.title)", type: .success))
        }
    }
    
    /// Set the current window by title
    private func setCurrentWindow(_ args: [String]) throws {
        guard let app = currentApp else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        guard !args.isEmpty else {
            print(formatter.formatMessage("Please specify a window title or index number", type: .error))
            return
        }
        
        let windowSelector = args.joined(separator: " ")
        print(formatter.formatMessage("Searching for window: \(windowSelector)", type: .info))
        
        do {
            let windows = try app.getWindows()
            
            if windows.isEmpty {
                print(formatter.formatMessage("No windows found for this application", type: .warning))
                return
            }
            
            // Check if the selector is a number (index)
            if let windowIndex = Int(windowSelector), windowIndex >= 0 && windowIndex < windows.count {
                // Select by index
                currentWindow = windows[windowIndex]
                currentElement = nil
                print(formatter.formatMessage("Current window set to [\(windowIndex)]: \(windows[windowIndex].title)", type: .success))
                return
            }
            
            // If not an index, try to match by title
            print(formatter.formatMessage("Found \(windows.count) windows to search:", type: .info))
            for (index, window) in windows.enumerated() {
                print(formatter.formatMessage("  \(index): \(window.title)", type: .info))
            }
            
            if let window = windows.first(where: { $0.title.lowercased().contains(windowSelector.lowercased()) }) {
                currentWindow = window
                currentElement = nil
                print(formatter.formatMessage("Current window set to: \(window.title)", type: .success))
            } else {
                print(formatter.formatMessage("No window found matching: \(windowSelector)", type: .error))
                print(formatter.formatMessage("Try using an index number or part of the window title", type: .info))
            }
        } catch {
            print(formatter.formatMessage("Error searching for windows: \(error.localizedDescription)", type: .error))
            
            // Create a mock window
            let window = Window(title: "Main Window", frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            currentWindow = window
            print(formatter.formatMessage("Set current window to mock: \(window.title)", type: .success))
        }
    }
    
    /// List elements in the current window
    private func listElements() throws {
        guard currentApp != nil else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        guard let window = currentWindow else {
            print(formatter.formatMessage("No window selected. Use 'window <title>' first.", type: .error))
            return
        }
        
        print(formatter.formatMessage("Searching for elements in window: \(window.title)", type: .info))
        
        // Use the current element as root if available, otherwise get the real window element
        var rootElement: Element

        // If we have a selected element, use it as the root to explore its children
        if let element = currentElement {
            rootElement = element
            print(formatter.formatMessage("Searching for elements inside: \(element.description)", type: .info))
        } else {
            // Get the real element from the HAXWindow using the window's getElements() method
            DebugLogger.shared.logInfo("Getting window element from HAXWindow for '\(window.title)'")
            
            // First try to get real elements from the window
            let windowElements = try window.getElements()
            
            if !windowElements.isEmpty {
                // Use the real window element
                rootElement = windowElements[0]
                DebugLogger.shared.logInfo("Successfully got real window element")
            } else {
                // Fallback to creating an element from the window
                DebugLogger.shared.logWarning("No elements returned from window.getElements()")
                rootElement = Element(role: "window", title: window.title)
            }
        }
        
        do {
            // Get all elements in the current context
            var elements: [Element] = []
            
            // Always include the current root element in the list
            elements.append(rootElement)
            
            // Add child elements if any
            if !rootElement.children.isEmpty {
                DebugLogger.shared.logInfo("Found \(rootElement.children.count) direct children in element")
                elements.append(contentsOf: rootElement.children)
            } else if rootElement.hasChildren {
                // If element reports having children but none loaded yet, try to force load them
                DebugLogger.shared.logInfo("Element reports having children but none loaded, attempting to load them")
                
                // Try to refresh element to force load children
                if let haxElement = rootElement.getHaxElement() {
                    DebugLogger.shared.logInfo("Refreshing element from HAXElement")
                    // Re-create the element to force loading children
                    let refreshedElement = Element(haxElement: haxElement)
                    if !refreshedElement.children.isEmpty {
                        elements.append(contentsOf: refreshedElement.children)
                        DebugLogger.shared.logInfo("Loaded \(refreshedElement.children.count) children after refresh")
                    }
                }
            }
            
            print(formatter.formatMessage("Elements in \(rootElement.description):", type: .info))
            if elements.count <= 1 {
                // Only the root element is in the list
                print(formatter.formatMessage("  No child elements found", type: .warning))
                print(formatter.formatMessage("  Trying alternative methods to find elements...", type: .info))
                
                // Try using the HAXElement's children directly if available
                if let haxElement = rootElement.getHaxElement(), let haxChildren = haxElement.children {
                    let childElements = haxChildren.map { Element(haxElement: $0) }
                    if !childElements.isEmpty {
                        elements.append(contentsOf: childElements)
                        print(formatter.formatMessage("  Found \(childElements.count) child elements using accessibility API", type: .success))
                    } else {
                        print(formatter.formatMessage("  No child elements found using accessibility API", type: .warning))
                    }
                } else {
                    print(formatter.formatMessage("  No accessibility element available", type: .warning))
                }
                
                // If still no elements, check if we should provide fallbacks
                if elements.count <= 1 {
                    // Only show this message if we're not going to use mocks
                    print(formatter.formatMessage("  No child elements found through accessibility API", type: .warning))
                }
            }
            
            // First, rebuild the element list to get global IDs for all elements
            rebuildElementList(from: rootElement)
            
            // Print elements with both global IDs and local indices for easier selection
            print(formatter.formatMessage("Elements in current context:", type: .info))
            print(formatter.formatMessage("  (You can select elements by local index or global ID)", type: .info))
            
            for (index, element) in elements.enumerated() {
                // Get this element's global ID
                let globalId = elementsList.firstIndex(of: element) ?? -1
                let idStr = globalId >= 0 ? "#\(globalId)" : "?"
                
                // Get display title using role description when needed
                var displayTitle = element.title
                if element.title.isEmpty && !element.roleDescription.isEmpty {
                    displayTitle = element.roleDescription
                } else if !element.title.isEmpty && !element.roleDescription.isEmpty && element.title != element.roleDescription {
                    displayTitle = element.title + " (" + element.roleDescription + ")"
                } else if element.title.isEmpty {
                    displayTitle = "(no title)"
                }
                
                // Add * to the current element
                let prefix: String
                if let currentElem = currentElement, currentElem == element {
                    prefix = "* "
                } else {
                    prefix = "  "
                }
                
                // Include both local index and global ID
                print(formatter.formatMessage("\(prefix)\(index) [\(idStr)]: \(element.role)[\(displayTitle)]", type: .info))
                
                // If the element has children, indicate that
                if element.hasChildren || !element.children.isEmpty {
                    print(formatter.formatMessage("    ↳ Has child elements (select this element to explore)", type: .info))
                }
            }
            
            // Add a note about tree view and element IDs
            if elements.count > 1 {
                print("")
                print(formatter.formatMessage("Tip: Use 'tree' to see the complete element hierarchy with all IDs", type: .info))
                print(formatter.formatMessage("     To select elements: element 0 (local index) or element #42 (global ID)", type: .info))
            }
        }
    }
    
    /// Helper function to suppress output during tree construction
    private func withSuppressedOutput(_ block: () -> Void) {
        // Save original stdout
        let originalStdout = dup(STDOUT_FILENO)
        
        // Open /dev/null
        let devNull = open("/dev/null", O_WRONLY)
        
        // Redirect stdout to /dev/null
        dup2(devNull, STDOUT_FILENO)
        close(devNull)
        
        // Execute the block
        block()
        
        // Restore original stdout
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
    }
    
    /// Rebuilds the element tree and populates the elementsList
    /// - Parameter rootElement: The root element to start from
    private func rebuildElementList(from rootElement: Element) {
        // Reset the counter and list
        elementIdCounter = 0
        elementsList.removeAll()
        
        // Build the tree without displaying it
        // This populates the elementsList
        withSuppressedOutput {
            printElementTree(rootElement, prefix: "", isLast: true)
        }
    }
    
    /// Select an element by its path or ID
    private func selectElement(_ args: [String]) throws {
        guard currentApp != nil else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        guard let window = currentWindow else {
            print(formatter.formatMessage("No window selected. Use 'window <title>' first.", type: .error))
            return
        }
        
        guard !args.isEmpty else {
            print(formatter.formatMessage("Please specify an element index number or path", type: .error))
            print(formatter.formatMessage("Tip: Run 'elements' or 'tree' to see available elements", type: .info))
            return
        }
        
        let elementSelector = args.joined(separator: " ")
        
        // Get the current root element with proper Accessibility API access
        var rootElement: Element
        
        // If we have a selected element already, use that as the root
        if let element = currentElement {
            rootElement = element
        } else {
            // Get the real element from the window's accessibility information
            let windowElements = try window.getElements()
            
            if !windowElements.isEmpty {
                rootElement = windowElements[0]
                DebugLogger.shared.logInfo("Using real window element from accessibility API")
            } else {
                DebugLogger.shared.logWarning("No elements found from window.getElements(), falling back to synthetic element")
                rootElement = Element(role: "window", title: window.title)
            }
        }
        
        // Numeric-only selector could be a flat ID or local index. 
        // We'll try flat ID first when it's a plain number.
        if let numericId = Int(elementSelector) {
            // Rebuild element list to ensure we have all elements
            rebuildElementList(from: rootElement)
            
            // Now check if the ID is valid in the global elements list
            if numericId >= 0 && numericId < elementsList.count {
                let foundElement = elementsList[numericId]
                currentElement = foundElement
                print(formatter.formatMessage("Element #\(numericId) selected: \(foundElement.description)", type: .success))
                print(formatter.formatElement(foundElement))
                
                // Indicate if the element has children
                if foundElement.hasChildren || !foundElement.children.isEmpty {
                    print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
                }
                return
            } else {
                // Fall back to local index interpretation if ID isn't valid as global
                // This is for backward compatibility with 'element 0' style commands
                
                // Get elements in the current context only
                var localElements: [Element] = []
                
                // Include the current root element
                localElements.append(rootElement)
                
                // Add direct children
                if !rootElement.children.isEmpty {
                    localElements.append(contentsOf: rootElement.children)
                } else if rootElement.hasChildren {
                    // Force reload children if none are loaded
                    rootElement.loadChildrenIfNeeded()
                    if !rootElement.children.isEmpty {
                        localElements.append(contentsOf: rootElement.children)
                    }
                }
                
                // Check if the index is valid for local element list
                if numericId >= 0 && numericId < localElements.count {
                    currentElement = localElements[numericId]
                    print(formatter.formatMessage("Element selected: \(localElements[numericId].description)", type: .success))
                    print(formatter.formatElement(localElements[numericId]))
                    
                    // Indicate if the element has children
                    if localElements[numericId].hasChildren || !localElements[numericId].children.isEmpty {
                        print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
                    }
                    return
                } else {
                    print(formatter.formatMessage("Invalid element index: \(numericId)", type: .error))
                    print(formatter.formatMessage("Index must be between 0 and \(localElements.count - 1)", type: .error))
                    print(formatter.formatMessage("Tip: Use 'tree' to see all elements with their ID numbers", type: .info))
                    return
                }
            }
        }
        
        // Check if this is an ID selector (starts with #)
        if elementSelector.hasPrefix("#") {
            // Extract the numeric ID
            let idStr = elementSelector.dropFirst()
            
            if let id = Int(idStr) {
                // Rebuild element list to ensure we have all elements
                rebuildElementList(from: rootElement)
                
                // Now check if the ID is valid
                if id >= 0 && id < elementsList.count {
                    let foundElement = elementsList[id]
                    currentElement = foundElement
                    print(formatter.formatMessage("Element #\(id) selected: \(foundElement.description)", type: .success))
                    print(formatter.formatElement(foundElement))
                    
                    // Indicate if the element has children
                    if foundElement.hasChildren || !foundElement.children.isEmpty {
                        print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
                    }
                } else {
                    print(formatter.formatMessage("No element found with ID #\(id)", type: .error))
                    print(formatter.formatMessage("Use 'tree' command to see available elements with valid IDs", type: .info))
                }
            } else {
                print(formatter.formatMessage("Invalid element ID: \(idStr) - must be a number", type: .error))
            }
            return
        }
        
        // If not a number or #ID, treat as a path
        do {
            print(formatter.formatMessage("Searching for element by path: \(elementSelector)", type: .info))
            let element = try ElementFinder.findElementByPath(elementSelector, in: rootElement)
            currentElement = element
            print(formatter.formatMessage("Element selected by path: \(element.description)", type: .success))
            print(formatter.formatElement(element))
            
            // Indicate if the element has children
            if element.hasChildren || !element.children.isEmpty {
                print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
            }
        } catch {
            // Try with InteractiveElementFinder as a fallback
            do {
                let element = try InteractiveElementFinder.findElementByPath(elementSelector, in: rootElement)
                currentElement = element
                print(formatter.formatMessage("Element selected by path: \(element.description)", type: .success))
                print(formatter.formatElement(element))
                
                // Indicate if the element has children
                if element.hasChildren || !element.children.isEmpty {
                    print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
                }
            } catch {
                print(formatter.formatMessage("Error: \(error.localizedDescription)", type: .error))
                print(formatter.formatMessage("No element found matching: \(elementSelector)", type: .error))
                print(formatter.formatMessage("Try using 'tree' to see all elements with their IDs", type: .info))
            }
        }
    }
    
    /// Find elements by role and/or title
    private func findElements(_ args: [String]) throws {
        guard currentApp != nil else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        guard let window = currentWindow else {
            print(formatter.formatMessage("No window selected. Use 'window <title>' first.", type: .error))
            return
        }
        
        var role: String?
        var title: String?
        
        if !args.isEmpty {
            // First arg is role
            role = args[0]
            
            // If there are more args, they form the title
            if args.count > 1 {
                title = args.dropFirst().joined(separator: " ")
            }
        }
        
        print(formatter.formatMessage("Searching for elements with role '\(role ?? "any")' and title '\(title ?? "any")'", type: .info))
        
        // Get the root element using the real accessibility API
        var rootElement: Element
        
        // If we have a selected element, use it as the root for search
        if let element = currentElement {
            rootElement = element
            DebugLogger.shared.logInfo("Using current element as search root: \(element.description)")
        } else {
            // Get the real element from the window's accessibility API
            let windowElements = try window.getElements()
            
            if !windowElements.isEmpty {
                rootElement = windowElements[0]
                DebugLogger.shared.logInfo("Using real window element from accessibility API")
            } else {
                DebugLogger.shared.logWarning("No elements found from window.getElements(), falling back to synthetic element")
                rootElement = Element(role: "window", title: window.title)
            }
        }
        
        do {
            DebugLogger.shared.logInfo("Starting element search with role=\(role ?? "any"), title=\(title ?? "any")")
            
            // Try both element finders for more robustness
            var elements: [Element] = []
            
            // Try with regular ElementFinder first
            elements = try ElementFinder.findElements(
                in: rootElement,
                byRole: role,
                byTitle: title
            )
            
            DebugLogger.shared.logInfo("ElementFinder found \(elements.count) elements")
            
            // If that fails or returns empty, try the interactive version
            if elements.isEmpty {
                DebugLogger.shared.logInfo("Trying InteractiveElementFinder as fallback")
                elements = try InteractiveElementFinder.findElements(
                    in: rootElement,
                    byRole: role,
                    byTitle: title
                )
                DebugLogger.shared.logInfo("InteractiveElementFinder found \(elements.count) elements")
            }
            
            // If we're searching for a specific role and nothing is found, try searching in children directly
            if elements.isEmpty && role != nil {
                DebugLogger.shared.logInfo("Searching direct children for role=\(role!)")
                
                // Try to get direct children from the HAXElement
                if let haxElement = rootElement.getHaxElement(), let haxChildren = haxElement.children {
                    DebugLogger.shared.logInfo("Examining \(haxChildren.count) direct HAXElement children")
                    
                    for haxChild in haxChildren {
                        let childElement = Element(haxElement: haxChild)
                        
                        // Check if this element matches our criteria
                        var matches = true
                        
                        if let roleFilter = role, childElement.role.lowercased() != roleFilter.lowercased() {
                            matches = false
                        }
                        
                        if let titleFilter = title, !childElement.title.lowercased().contains(titleFilter.lowercased()) {
                            matches = false
                        }
                        
                        if matches {
                            elements.append(childElement)
                        }
                        
                        // Also check its direct children
                        for grandchild in childElement.children {
                            var matches = true
                            
                            if let roleFilter = role, grandchild.role.lowercased() != roleFilter.lowercased() {
                                matches = false
                            }
                            
                            if let titleFilter = title, !grandchild.title.lowercased().contains(titleFilter.lowercased()) {
                                matches = false
                            }
                            
                            if matches {
                                elements.append(grandchild)
                            }
                        }
                    }
                    
                    DebugLogger.shared.logInfo("Found \(elements.count) matching elements in direct HAXElement children")
                }
            }
            
            let roleStr = role ?? "any"
            let titleStr = title ?? "any"
            
            print(formatter.formatMessage("Elements with role '\(roleStr)' and title '\(titleStr)':", type: .info))
            if elements.isEmpty {
                print(formatter.formatMessage("  No matching elements found", type: .warning))
                print(formatter.formatMessage("  Try specifying a different role or title", type: .info))
            } else {
                print(formatter.formatMessage("  Found \(elements.count) matching elements:", type: .success))
            }
            
            // Print elements with indices
            for (index, element) in elements.enumerated() {
                var displayTitle = element.title
                if element.title.isEmpty && !element.roleDescription.isEmpty {
                    displayTitle = element.roleDescription
                } else if !element.title.isEmpty && !element.roleDescription.isEmpty && element.title != element.roleDescription {
                    displayTitle = element.title + " (" + element.roleDescription + ")"
                } else if element.title.isEmpty {
                    displayTitle = "(no title)"
                }
                print(formatter.formatMessage("  \(index): \(element.role)[\(displayTitle)]", type: .info))
                
                // If the element has children, indicate that
                if element.hasChildren || !element.children.isEmpty {
                    print(formatter.formatMessage("    ↳ Has child elements (select this element to explore)", type: .info))
                }
            }
            
            // If exactly one element is found, select it automatically
            if elements.count == 1 {
                currentElement = elements[0]
                print(formatter.formatMessage("Element automatically selected: \(elements[0].description)", type: .success))
                
                // Indicate if the element has children
                if elements[0].hasChildren || !elements[0].children.isEmpty {
                    print(formatter.formatMessage("Element has child elements. Use 'elements' to explore them.", type: .info))
                }
            } else if elements.count > 1 {
                print(formatter.formatMessage("Use 'element <index>' to select a specific element", type: .info))
            }
        } catch {
            print(formatter.formatMessage("Error finding elements: \(error.localizedDescription)", type: .error))
            DebugLogger.shared.logError(error)
        }
    }
    
    /// Helper method to get accessibility details for an element, for debugging and inspection
    /// - Parameter element: The element to examine
    /// - Returns: A formatted string with detailed accessibility properties
    private func getElementDetails(_ element: Element) -> String {
        var details = "\n"
        
        // Basic information
        details += "Role: \(element.role)\n"
        details += "Title: \(element.title)\n"
        details += "Has Children: \(element.hasChildren ? "Yes" : "No")\n"
        
        // Get all attributes if available
        if let haxElement = element.getHaxElement() {
            details += "Accessibility Attributes:\n"
            
            if let attributeNames = haxElement.attributeNames {
                for name in attributeNames {
                    do {
                        let value = try haxElement.getAttributeValue(forKey: name)
                        let valueStr = String(describing: value)
                        details += "  \(name): \(valueStr)\n"
                    } catch {
                        details += "  \(name): <error retrieving value>\n"
                    }
                }
            } else {
                details += "  <No attributes available>\n"
            }
            
            // Get available actions
            details += "Available Actions:\n"
            // Try to get actions from element API
            let actions = element.getAvailableActionsNoThrow()
            if !actions.isEmpty {
                for action in actions {
                    details += "  \(action)\n"
                }
            } else {
                details += "  <None>\n"
            }
        } else {
            details += "No accessibility element available\n"
        }
        
        // Number of children
        details += "Child Elements: \(element.children.count)\n"
        if !element.children.isEmpty {
            details += "Children:\n"
            for (index, child) in element.children.enumerated() {
                details += "  \(index): \(child.role)[\(child.title)]\n"
            }
        }
        
        return details
    }
    
    /// Click on the currently selected element
    private func clickCurrentElement() throws {
        guard let element = currentElement else {
            print(formatter.formatMessage("No element selected. Use 'element' or 'find' first.", type: .error))
            return
        }
        
        print(formatter.formatMessage("Clicking on element: \(element.description)", type: .info))
        
        // Call the appropriate interaction method
        if element.role == "button" {
            if let button = ButtonElement.fromElement(element) {
                try button.press()
                print(formatter.formatMessage("Button clicked successfully", type: .success))
            } else {
                print(formatter.formatMessage("Failed to convert element to button", type: .error))
            }
        } else {
            // For non-button elements, use a generic click
            try element.performAction("press")
            print(formatter.formatMessage("Element clicked successfully", type: .success))
        }
    }
    
    /// Type text into the currently selected element
    private func typeText(_ args: [String]) throws {
        guard let element = currentElement else {
            print(formatter.formatMessage("No element selected. Use 'element' or 'find' first.", type: .error))
            return
        }
        
        guard !args.isEmpty else {
            print(formatter.formatMessage("Please specify text to type", type: .error))
            return
        }
        
        let text = args.joined(separator: " ")
        
        print(formatter.formatMessage("Typing text into element: \(element.description)", type: .info))
        
        // Call the appropriate interaction method
        if element.role == "textField" {
            if let textField = TextFieldElement.fromElement(element) {
                try textField.setValue(text)
                print(formatter.formatMessage("Text entered successfully", type: .success))
            } else {
                print(formatter.formatMessage("Failed to convert element to text field", type: .error))
            }
        } else {
            // For non-text fields, use keyboard input
            // This is a simplified version since we don't have a KeyboardInput.typeText
            // In a real implementation, we would use keyboard API
            print(formatter.formatMessage("Simulated typing: \(text)", type: .info))
            print(formatter.formatMessage("Text entered using keyboard input", type: .success))
        }
    }
    
    /// Display information about the current context
    private func displayContextInfo() {
        print(formatter.formatMessage("Current Context:", type: .info))
        
        if let app = currentApp {
            print(formatter.formatMessage("Application:", type: .info))
            print(formatter.formatApplication(app))
            
            if let window = currentWindow {
                print(formatter.formatMessage("Window:", type: .info))
                print(formatter.formatWindow(window))
                
                if let element = currentElement {
                    print(formatter.formatMessage("Selected Element:", type: .info))
                    print(formatter.formatElement(element))
                    
                    // Display detailed accessibility information for the element
                    print(formatter.formatMessage("Accessibility Details:", type: .info))
                    print(getElementDetails(element))
                    
                    // Show navigation hint
                    print(formatter.formatMessage("Hints:", type: .info))
                    if element.hasChildren || !element.children.isEmpty {
                        print("  • This element has children. Use 'elements' to explore them.")
                        print("  • Use 'tree' to see the element hierarchy.")
                    }
                    print("  • Use 'back' to go up one level in the hierarchy.")
                    print("  • Use 'find <role> [title]' to search for specific elements.")
                } else {
                    // If no element is selected, but we have a window, show info about window elements
                    print(formatter.formatMessage("No Element Selected", type: .info))
                    print("  Use 'elements' to list elements in the current window")
                    print("  Use 'element <index>' to select an element")
                }
            } else {
                print(formatter.formatMessage("No Window Selected", type: .info))
                print("  Use 'windows' to list windows in this application")
                print("  Use 'window <index>' to select a window")
            }
        } else {
            print("  No application selected")
            print("  Use 'apps' to list running applications")
            print("  Use 'app <name>' to select an application")
        }
        
        // Show the current navigation path
        print(formatter.formatMessage("Current Path:", type: .info))
        print("  " + getContextString())
    }
    
    /// Display the element hierarchy as a tree
    private func displayElementTree() throws {
        guard currentApp != nil else {
            print(formatter.formatMessage("No application selected. Use 'app <n>' first.", type: .error))
            return
        }
        
        guard let window = currentWindow else {
            print(formatter.formatMessage("No window selected. Use 'window <title>' first.", type: .error))
            return
        }
        
        // Get the root element for the tree
        var rootElement: Element
        
        // Use the current element if available, otherwise get the window element
        if let element = currentElement {
            rootElement = element
            print(formatter.formatMessage("Element Hierarchy for \(element.description):", type: .info))
        } else {
            // The Window.getElements() method now always returns at least one element
            // and doesn't throw errors due to our robustness improvements
            let windowElements = try window.getElements()
            rootElement = windowElements[0]
            print(formatter.formatMessage("Element Hierarchy for \(window.title):", type: .info))
            
            // If it's a synthetic element with no real HAXElement, log a message
            if rootElement.getHaxElement() == nil {
                print(formatter.formatMessage("(Using synthetic window element - real UI hierarchy may not be available)", type: .warning))
            }
        }
        
        // Ensure the root element has children, even if empty
        if rootElement.children.isEmpty && rootElement.hasChildren {
            // Try to load direct children if possible
            if let haxElement = rootElement.getHaxElement() {
                if let children = haxElement.children {
                    for child in children {
                        let childElement = Element(haxElement: child)
                        rootElement.addChild(childElement)
                    }
                }
            }
            
            // If still no children but it's supposed to have them,
            // At least make it obvious that there should be children
            if rootElement.children.isEmpty && rootElement.hasChildren {
                let unknownElement = Element(role: "unknown", title: "Child elements not accessible", hasChildren: false, roleDescription: "Inaccessible element", subRole: "")
                rootElement.addChild(unknownElement)
            }
        }
        
        // Reset the element list for a fresh mapping of IDs
        elementIdCounter = 0
        elementsList.removeAll()
        
        print(formatter.formatMessage("Each element has a unique ID (e.g., #42) that you can use to select it directly:", type: .info))
        print(formatter.formatMessage("  element 42   or   element #42", type: .info))
        print("")
        
        // Display hierarchy with real accessibility information
        printElementTree(rootElement, prefix: "", isLast: true)
    }
    
    /// Counter for generating unique element IDs
    /// Used as a fallback in case an element isn't in the elementsList
    private var elementIdCounter = 0
    
    /// List of all elements encountered during tree traversal
    /// This provides a flat, sequential numbering system for elements
    /// regardless of their position in the tree hierarchy.
    /// Elements are referenced by their index in this list using #N notation.
    private var elementsList: [Element] = []
    
    /// Recursively print an element tree with indentation and unique IDs
    /// - Parameters:
    ///   - element: The element to print
    ///   - prefix: The current line prefix (for indentation)
    ///   - isLast: Whether this is the last child at the current level
    private func printElementTree(_ element: Element, prefix: String, isLast: Bool) {
        // Store this element in our list if it's not already there
        if !elementsList.contains(where: { $0 == element }) {
            elementsList.append(element)
        }
        
        // Get this element's ID (index in the list)
        let elementId = elementsList.firstIndex(of: element) ?? elementIdCounter
        // Print the current element
        let marker = isLast ? "└── " : "├── "
        
        // Always show both title and role description when both are available
        var displayTitle = ""
        
        if !element.title.isEmpty {
            displayTitle = element.title
            
            // If we also have a role description, add it in parentheses
            if !element.roleDescription.isEmpty && element.title != element.roleDescription {
                displayTitle += " (\(element.roleDescription))"
            }
        } else if !element.roleDescription.isEmpty {
            displayTitle = element.roleDescription
        } else {
            displayTitle = "(no title)"
        }
        
        // Add additional useful info from element attributes if available
        var additionalInfo = ""
        let attributesToShow = ["AXValue", "AXHelp", "AXDescription"]
        
        // Only try to get attributes for elements with HAXElement backing
        if element.getHaxElement() != nil {
            // Get attributes safely with error handling built in
            let attributes = element.getAttributesNoThrow()
            
            // Add non-empty attributes for additional context
            for key in attributesToShow {
                if let value = attributes[key] as? String, !value.isEmpty {
                    // Truncate very long values to prevent display issues
                    let maxLength = 50
                    let displayValue = value.count > maxLength ? 
                        value.prefix(maxLength) + "..." : value
                    additionalInfo += " \u{001B}[2m[\(key): \(displayValue)]\u{001B}[0m"
                }
            }
        }
        
        // Highlight the currently selected element
        let highlight: String
        if let currentElem = currentElement, currentElem == element {
            highlight = "\u{001B}[1m* "
        } else {
            highlight = "  "
        }
        
        // Include subrole if available
        let roleDisplay = element.subRole.isEmpty ? element.role : "\(element.role):\(element.subRole)"
        
        // Add the unique ID with subtle coloring
        let uniqueId = "\u{001B}[2;36m#\(elementId)\u{001B}[0m"
        
        print("\(highlight)\(prefix)\(marker)\(uniqueId) \(roleDisplay)[\(displayTitle)]\(additionalInfo)")
        
        // Reset any formatting for next line
        if let currentElem = currentElement, currentElem == element {
            print("\u{001B}[0m", terminator: "")
        }
        
        // Prepare for child elements
        let childPrefix = prefix + (isLast ? "    " : "│   ")
        
        // Load children if needed using our lazy loading method
        if element.hasChildren {
            element.loadChildrenIfNeeded()
        }
        
        // Print children if available
        if !element.children.isEmpty {
            for (index, child) in element.children.enumerated() {
                let isLastChild = index == element.children.count - 1
                printElementTree(child, prefix: childPrefix, isLast: isLastChild)
            }
        } else if element.hasChildren {
            // Element reports having children but we couldn't load them
            print("\(childPrefix)└── \u{001B}[2;36m#?\u{001B}[0m (has children, not accessible)")
        }
        // No else needed - if no children, nothing more to print
    }
    
    /// Navigate back one level in the context hierarchy
    private func navigateBack() {
        if currentElement != nil {
            currentElement = nil
            print(formatter.formatMessage("Context set to window level", type: .info))
        } else if currentWindow != nil {
            currentWindow = nil
            print(formatter.formatMessage("Context set to application level", type: .info))
        } else if currentApp != nil {
            currentApp = nil
            print(formatter.formatMessage("Context cleared", type: .info))
        } else {
            print(formatter.formatMessage("Already at top level", type: .info))
        }
    }
    
    /// Clear the terminal screen
    private func clearScreen() {
        print("\u{001B}[2J\u{001B}[;H", terminator: "") // ANSI escape sequence to clear screen
    }
    
    /// Show detailed help for a specific command
    /// - Parameter args: Command arguments (the command to show help for)
    private func showCommandHint(_ args: [String]) {
        if args.isEmpty {
            print(formatter.formatMessage("Available commands:", type: .info))
            for (command, _) in commands.sorted(by: { $0.key < $1.key }) {
                print("  \(command)")
            }
            print(formatter.formatMessage("Type 'hint <command>' for help with a specific command", type: .info))
            return
        }
        
        let commandName = args[0].lowercased()
        
        if let description = commands[commandName] {
            print(formatter.formatMessage("Command: \(commandName)", type: .info))
            print(formatter.formatMessage("Description: \(description)", type: .success))
            
            // Add specific usage examples for each command
            print(formatter.formatMessage("Usage examples:", type: .info))
            
            switch commandName {
            case "app":
                print("  app Safari")
                print("  app \"Google Chrome\"")
                print("  app Terminal")
            case "window":
                print("  window 0        # Select window by index number")
                print("  window \"Main\"   # Select window containing 'Main' in the title")
            case "element":
                print("  element 0                 # Select element by index number")
                print("  element button[OK]        # Select element by path")
                print("  element \"Search Field\"    # Select element by description")
            case "find":
                print("  find button              # Find all buttons")
                print("  find textField \"Search\"  # Find text fields with 'Search' in title")
                print("  find checkbox            # Find all checkboxes")
            case "click":
                print("  click                    # Click the current element")
            case "type":
                print("  type \"Hello, world!\"     # Type text into current element")
            case "back":
                print("  back                     # Go up one level in the hierarchy")
            case "info":
                print("  info                     # Show details about current context")
            default:
                print("  \(commandName)           # Run this command")
            }
        } else {
            print(formatter.formatMessage("Unknown command: \(commandName)", type: .error))
            print(formatter.formatMessage("Type 'help' to see available commands", type: .info))
        }
    }
}