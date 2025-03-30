// ABOUTME: This file implements a curses-style UI navigator for exploring UI elements.
// ABOUTME: It provides a visual tree representation with keyboard navigation and action execution.

import Foundation
import Haxcessibility
import Darwin.C
import Dispatch // For DispatchTime

/// A curses-style UI navigator for exploring and interacting with UI elements
public class UINavigator {
    // Current application and window context
    private var currentApplication: Application?
    private var currentWindow: Window?
    
    // Current navigation state
    private var rootElement: Element?
    private var selectedElement: Element?
    private var elementPath: [Element] = []
    
    // Element collection for flat access
    private var elementsList: [Element] = []
    
    // Terminal dimensions
    private var terminalWidth: Int = 80
    private var terminalHeight: Int = 24
    
    // Display settings
    private var showDetails: Bool = true
    private var colorEnabled: Bool = true
    
    // Running state
    private var running: Bool = false
    private var lastCommand: String = ""
    
    // Formatter for output
    private var formatter: OutputFormatter
    
    /// Initialize the UI Navigator
    /// - Parameter formatter: The output formatter to use
    public init(formatter: OutputFormatter? = nil) {
        self.formatter = formatter ?? PlainTextFormatter()
        
        // Try to get terminal dimensions
        if let columns = ProcessInfo.processInfo.environment["COLUMNS"],
           let lines = ProcessInfo.processInfo.environment["LINES"],
           let columnsInt = Int(columns),
           let linesInt = Int(lines) {
            self.terminalWidth = columnsInt
            self.terminalHeight = linesInt
        }
    }
    
    /// Start the UI Navigator with a specific application
    /// - Parameter appName: The name of the application to navigate
    /// - Throws: ApplicationManagerError if the application cannot be found
    public func startWithApplication(_ appName: String) throws {
        print(formatter.formatMessage("Starting UI Navigator for \(appName)...", type: .info))
        
        // Set up the application context
        let app = try ApplicationManager.getApplicationByName(appName)
        self.currentApplication = app
        
        // Try to get the main window
        if let window = try app.getWindows().first {
            self.currentWindow = window
            print(formatter.formatMessage("Found window: \(window.title)", type: .success))
            
            // Get the window root element
            let elements = try window.getElements()
            if let rootElement = elements.first {
                self.rootElement = rootElement
                self.selectedElement = rootElement
                self.elementPath = [rootElement]
                
                // Start the UI loop in a simple interactive mode
                try simpleNavigatorLoop()
            } else {
                throw UIElementError.elementNotFound(description: "Root element for window \(window.title)")
            }
        } else {
            throw WindowError.windowNotFound(description: "Main window for application \(appName)")
        }
    }
    
    /// A more user-friendly interactive loop
    private func simpleNavigatorLoop() throws {
        print("Starting UI Navigator")
        print("\nCommands:")
        print("  - Enter element number to select it")
        print("  - 'p' to go to parent")
        print("  - 'c' to explore children")
        print("  - 'i' to show detailed info")
        print("  - 'a' to see available actions")
        print("  - 'x' followed by action number to execute an action")
        print("  - 'r' to refresh the view")
        print("  - 'q' to quit")
        print("\nExample: '5' selects element #5, 'a' shows actions, 'x 2' executes action #2")
        print("")
        
        running = true
        
        // Display the initial UI
        buildElementList()
        displayFullTree()
        
        while running {
            print("\nCommand: ", terminator: "")
            fflush(stdout)
            
            if let line = readLine()?.trimmingCharacters(in: .whitespaces), !line.isEmpty {
                // Process command
                if line == "q" {
                    // Quit
                    print("Exiting navigator...")
                    running = false
                } 
                else if line == "p" {
                    // Go to parent
                    navigateToParent()
                    buildElementList()
                    displayFullTree()
                }
                else if line == "c" {
                    // Explore children
                    if let element = selectedElement, !element.children.isEmpty {
                        print("\nChildren of \(element.role)[\(element.title.isEmpty ? "Untitled" : element.title)]:")
                        displayChildren(of: element)
                    } else {
                        print("Selected element has no children to explore")
                    }
                }
                else if line == "i" {
                    // Show detailed info
                    if selectedElement != nil {
                        showElementDetails()
                    } else {
                        print("No element selected")
                    }
                }
                else if line == "a" {
                    // Show available actions
                    if selectedElement != nil {
                        showAvailableActions()
                    } else {
                        print("No element selected")
                    }
                }
                else if line == "r" {
                    // Refresh view
                    buildElementList()
                    displayFullTree()
                }
                else if line.hasPrefix("x ") {
                    // Execute action by number
                    let parts = line.split(separator: " ")
                    if parts.count >= 2, let actionIndex = Int(parts[1]), let element = selectedElement {
                        executeAction(at: actionIndex - 1, on: element)
                    } else {
                        print("Invalid action format. Use 'x <number>', e.g., 'x 1'")
                    }
                }
                else if let elementId = Int(line) {
                    // Select element by ID
                    selectElementById(elementId)
                }
                else {
                    print("Unknown command: \(line)")
                    print("Type a number to select an element, or 'p', 'c', 'i', 'a', 'x', 'r', 'q'")
                }
            }
        }
    }
    
    /// Build a complete list of relevant elements for navigation
    private func buildElementList() {
        guard let rootNode = rootElement else {
            return
        }
        
        // Clear the list
        elementsList.removeAll()
        
        // Always include the root element first
        elementsList.append(rootNode)
        
        // If we have a selected element, make sure to include it and its siblings
        if let selected = selectedElement, let parent = selected.parent {
            // Add the parent's children (siblings of the selected element)
            for child in parent.children {
                if !elementsList.contains(where: { $0 == child }) {
                    elementsList.append(child)
                }
            }
            
            // Add the selected element's children
            for child in selected.children {
                if !elementsList.contains(where: { $0 == child }) {
                    elementsList.append(child)
                }
            }
        } else {
            // Just add the root element's children
            for child in rootNode.children {
                if !elementsList.contains(where: { $0 == child }) {
                    elementsList.append(child)
                }
            }
        }
    }
    
    /// Display a complete tree view that resembles the application structure
    private func displayFullTree() {
        guard let rootNode = rootElement else {
            print("No elements to display")
            return
        }
        
        print("\n=== UI STRUCTURE OF \(currentApplication?.name ?? "Unknown") ===")
        print("Window: \(currentWindow?.title ?? "Unknown")")
        
        // Print the current path
        print("Path: \(formatPath())")
        print("Current Selection: \(selectedElement?.description ?? "None")")
        print("-----------------------------------------------------------")
        
        // Display the UI structure
        print("\nUI Elements (enter number to select):")
        printElementTree(rootNode, prefix: "", isLast: true, maxDepth: 5)
        
        // Display useful info about selected element
        if let selected = selectedElement {
            print("\nSelected Element (#\(elementsList.firstIndex(of: selected) ?? -1)):")
            print("  Type: \(selected.role)" + (selected.subRole.isEmpty ? "" : ":\(selected.subRole)"))
            print("  Title: \(selected.title.isEmpty ? "(none)" : selected.title)")
            print("  Description: \(selected.roleDescription.isEmpty ? "(none)" : selected.roleDescription)")
            print("  Children: \(selected.children.count)" + (selected.hasChildren && selected.children.isEmpty ? " (not loaded)" : ""))
            
            // Show a few key attributes if available
            let attributes = selected.getAttributesNoThrow()
            let importantAttributes = ["AXValue", "AXHelp", "AXDescription"]
            
            var hasAttributes = false
            for attr in importantAttributes {
                if let value = attributes[attr] {
                    if !hasAttributes {
                        print("  Attributes:")
                        hasAttributes = true
                    }
                    print("    \(attr): \(value)")
                }
            }
            
            // Show available actions summary
            let actions = selected.getAvailableActionsNoThrow()
            if !actions.isEmpty {
                print("  Actions: \(actions.joined(separator: ", "))")
                print("  Use 'a' to see all actions, 'x <number>' to execute an action")
            }
        }
    }
    
    /// Print element tree with proper indentation and display options
    /// - Parameters:
    ///   - element: The element to print
    ///   - prefix: Indentation prefix
    ///   - isLast: Whether this is the last child in its group
    ///   - maxDepth: Maximum depth to display
    ///   - currentDepth: Current depth in the tree
    private func printElementTree(_ element: Element, prefix: String, isLast: Bool, maxDepth: Int, currentDepth: Int = 0) {
        // Check if we've reached the max depth
        if currentDepth > maxDepth {
            return
        }
        
        // Get the element's index in our list
        let elementId = elementsList.firstIndex(of: element) ?? -1
        
        // Create the branch line
        let branch = isLast ? "└── " : "├── "
        
        // Create the display name with element type and title
        var displayName = "\(element.role)"
        if !element.title.isEmpty {
            displayName += "[\(element.title)]"
        } else if !element.roleDescription.isEmpty {
            displayName += "[\(element.roleDescription)]"
        }
        
        // Highlight the selected element
        let isSelected = element == selectedElement
        let displayId = "[\(elementId)]"
        
        if isSelected {
            print("\(prefix)\(branch)\u{001B}[1;32m\(displayId) \(displayName)\u{001B}[0m")
        } else {
            print("\(prefix)\(branch)\(displayId) \(displayName)")
        }
        
        // Set up the prefix for children
        let childPrefix = prefix + (isLast ? "    " : "│   ")
        
        // Ensure children are loaded
        if element.hasChildren && element.children.isEmpty {
            element.loadChildrenIfNeeded()
        }
        
        // Print children
        let children = element.children
        for (index, child) in children.enumerated() {
            let isLastChild = index == children.count - 1
            printElementTree(child, prefix: childPrefix, isLast: isLastChild, maxDepth: maxDepth, currentDepth: currentDepth + 1)
        }
    }
    
    /// Display children of a specific element with their IDs
    /// - Parameter element: The parent element
    private func displayChildren(of element: Element) {
        // Show the children of the element
        let children = element.children
        if children.isEmpty {
            if element.hasChildren {
                print("Element reports having children but they couldn't be loaded")
            } else {
                print("Element has no children")
            }
            return
        }
        
        // Display children with their IDs
        for child in children {
            let elementId = elementsList.firstIndex(of: child) ?? -1
            if elementId >= 0 {
                print("  [\(elementId)] \(child.role)[\(child.title.isEmpty ? "Untitled" : child.title)]")
            } else {
                // If this child isn't in our list yet, add it
                elementsList.append(child)
                let newId = elementsList.count - 1
                print("  [\(newId)] \(child.role)[\(child.title.isEmpty ? "Untitled" : child.title)]")
            }
        }
    }
    
    /// Format the current path as a string
    private func formatPath() -> String {
        return elementPath.map { 
            $0.title.isEmpty ? $0.role : "\($0.role)[\($0.title)]" 
        }.joined(separator: " > ")
    }
    
    /// Show detailed information about the selected element
    private func showElementDetails() {
        guard let element = selectedElement else {
            print("No element selected")
            return
        }
        
        print("\n=== ELEMENT DETAILS ===")
        print("Role: \(element.role)")
        if !element.subRole.isEmpty {
            print("SubRole: \(element.subRole)")
        }
        print("Title: \(element.title)")
        print("Role Description: \(element.roleDescription)")
        print("Has Children: \(element.hasChildren ? "Yes (\(element.children.count) loaded)" : "No")")
        
        // Show attributes
        let attributes = element.getAttributesNoThrow()
        if !attributes.isEmpty {
            print("\nAttributes:")
            for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
                print("  \(key): \(String(describing: value))")
            }
        } else {
            print("\nNo attributes available")
        }
        
        // Show actions
        let actions = element.getAvailableActionsNoThrow()
        if !actions.isEmpty {
            print("\nAvailable Actions:")
            for action in actions {
                print("  • \(action)")
            }
        } else {
            print("\nNo actions available")
        }
    }
    
    /// Select an element by its ID in the elements list
    private func selectElementById(_ id: Int) {
        // Check if the ID is valid
        if id >= 0 && id < elementsList.count {
            let element = elementsList[id]
            selectedElement = element
            
            // Update element path
            // Build the new path from root to the element
            var newPath = [rootElement!]
            var current: Element? = element
            
            // Work backwards from element to root
            while current != nil && current != rootElement {
                if let p = current?.parent {
                    newPath.insert(current!, at: 1)
                    current = p
                } else {
                    break
                }
            }
            
            elementPath = newPath
            
            if element == rootElement {
                // If selecting the root, just set the path to it
                elementPath = [element]
            }
            
            print("Selected element #\(id): \(element.role)[\(element.title.isEmpty ? "Untitled" : element.title)]")
            
            // If the element has children, suggest exploring them
            if element.hasChildren {
                if element.children.isEmpty {
                    element.loadChildrenIfNeeded()
                }
                
                if !element.children.isEmpty {
                    print("This element has \(element.children.count) children. Use 'c' to explore them.")
                }
            }
        } else {
            print("Invalid element ID: \(id). Valid IDs range from 0 to \(elementsList.count - 1).")
        }
    }
    
    /// Navigate to the parent of the currently selected element
    private func navigateToParent() {
        guard let currentElement = selectedElement, currentElement != rootElement else {
            print("Already at the root element, no parent available.")
            return
        }
        
        if let parent = currentElement.parent {
            // Set the parent as the selected element
            selectedElement = parent
            
            // Update the path
            if elementPath.count > 1 {
                elementPath.removeLast()
            }
            
            print("Navigated to parent: \(parent.role)[\(parent.title.isEmpty ? "Untitled" : parent.title)]")
        } else {
            print("No parent found for the current element.")
        }
    }
    
    /// Show available actions for the selected element
    private func showAvailableActions() {
        guard let element = selectedElement else {
            print("No element selected")
            return
        }
        
        let actions = element.getAvailableActionsNoThrow()
        
        print("\nAvailable Actions for: \(element.role)[\(element.title.isEmpty ? "Untitled" : element.title)]")
        
        if actions.isEmpty {
            print("No actions available for this element")
        } else {
            for (index, action) in actions.enumerated() {
                print("  \(index + 1). \(action)")
            }
            print("\nTo execute an action, type 'x' followed by the action number (e.g., 'x 1')")
        }
    }
    
    /// Execute an action on the specified element
    /// - Parameters:
    ///   - index: Index of the action in the element's actions list
    ///   - element: The element to perform the action on
    private func executeAction(at index: Int, on element: Element) {
        let actions = element.getAvailableActionsNoThrow()
        
        if index >= 0 && index < actions.count {
            let action = actions[index]
            
            print("Executing '\(action)' on \(element.role)[\(element.title.isEmpty ? "Untitled" : element.title)]...")
            
            do {
                try element.performAction(action)
                print("Action '\(action)' executed successfully.")
            } catch {
                print("Failed to execute action: \(error.localizedDescription)")
            }
        } else {
            print("Invalid action index. Valid indexes are 1 to \(actions.count).")
        }
    }
    
    /// Navigate back up the hierarchy (implementation for the simple text UI)
    private func navigateBack() {
        if elementPath.count > 1 {
            // Remove current element from path
            elementPath.removeLast()
            
            // Set selected element to the last in path
            selectedElement = elementPath.last
        }
    }
    
    /// Toggle the details panel (used in the advanced UI)
    private func togglePanel() {
        showDetails = !showDetails
    }
    
    // The following methods are placeholders for the advanced curses-style UI
    // They're not used in the simpler text-based interface
    
    /// Navigate up to the previous sibling (not used in simple UI)
    private func navigateUp() {
        // Not implemented in simple UI - using numerical selection instead
    }
    
    /// Navigate down to the next sibling (not used in simple UI)
    private func navigateDown() {
        // Not implemented in simple UI - using numerical selection instead
    }
    
    /// Navigate left to the parent element (not used in simple UI)
    private func navigateLeft() {
        // Not implemented in simple UI - using 'p' command instead
    }
    
    /// Navigate right to the first child (not used in simple UI)
    private func navigateRight() {
        // Not implemented in simple UI - using numerical selection instead
    }
    
    /// Start the navigation event loop
    private func startNavigatorLoop() throws {
        print("Initializing navigator... Press q to exit at any time")
        
        // Set up terminal for raw mode
        setupTerminal()
        
        running = true
        
        // Initial render
        print("Rendering UI...")
        render()
        print("UI rendered. Waiting for keyboard input...")
        
        var loopCount = 0
        while running && loopCount < 1000 { // Safety limit to prevent infinite loops
            loopCount += 1
            
            // Get input with timeout
            let startTime = DispatchTime.now()
            let keyPressed = readKeyWithTimeout(timeoutSeconds: 0.5)
            let endTime = DispatchTime.now()
            let elapsed = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            
            if let key = keyPressed {
                DebugLogger.shared.logInfo("Key pressed: \(key) (took \(elapsed) seconds)")
                processKey(key)
                render()
            } else if loopCount % 10 == 0 {
                // Every 10 loops with no input, show a heartbeat message
                DebugLogger.shared.logInfo("Navigator heartbeat - loop \(loopCount), no input for \(elapsed) seconds")
                showTemporaryMessage("Navigator active - press q to exit", type: .info)
            }
            
            // Small sleep to prevent CPU hogging
            usleep(10000) // 10ms
        }
        
        // Reset terminal
        resetTerminal()
        
        if loopCount >= 1000 {
            print("Navigator exited due to safety limit. This is likely a bug.")
        } else {
            print("Navigator exited normally.")
        }
    }
    
    /// Read a key with timeout
    /// - Parameter timeoutSeconds: Maximum time to wait for input
    /// - Returns: Key pressed or nil if timeout
    private func readKeyWithTimeout(timeoutSeconds: Double) -> String? {
        // Set up non-blocking read
        var oldSettings: termios = termios()
        var newSettings: termios = termios()
        
        // Get current terminal settings
        tcgetattr(FileHandle.standardInput.fileDescriptor, &oldSettings)
        
        // Copy settings and modify for non-blocking read
        newSettings = oldSettings
        newSettings.c_lflag &= ~UInt(ICANON | ECHO)
        newSettings.c_cc.12 = 0 // VTIME = 0 (no timeout)
        newSettings.c_cc.13 = 0 // VMIN = 0 (return immediately with what's available)
        
        // Apply new settings
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &newSettings)
        
        // Set up for polling
        var fds = pollfd()
        fds.fd = FileHandle.standardInput.fileDescriptor
        fds.events = Int16(POLLIN)
        fds.revents = 0
        
        // Poll with timeout
        let timeoutMs = Int32(timeoutSeconds * 1000)
        let result = poll(&fds, 1, timeoutMs)
        
        // Check result
        var key: String? = nil
        if result > 0 && (fds.revents & Int16(POLLIN)) != 0 {
            // Data available to read
            key = readKey()
        }
        
        // Restore original terminal settings
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &oldSettings)
        
        return key
    }
    
    /// Set up the terminal for raw input mode
    private func setupTerminal() {
        // Using ANSI escape sequences instead of system calls
        
        // Save terminal state (using ANSI)
        print("\u{001B}7", terminator: "")
        
        // Set terminal to alternate screen buffer
        print("\u{001B}[?1049h", terminator: "")
        
        // Clear screen
        print("\u{001B}[2J\u{001B}[;H", terminator: "")
        fflush(stdout)
        
        // Hide cursor
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)
    }
    
    /// Reset the terminal to its original state
    private func resetTerminal() {
        // Show cursor
        print("\u{001B}[?25h", terminator: "")
        
        // Return to main screen buffer
        print("\u{001B}[?1049l", terminator: "")
        
        // Restore terminal state (using ANSI)
        print("\u{001B}8", terminator: "")
        
        fflush(stdout)
    }
    
    /// Read a key from the terminal
    /// - Returns: The key pressed as a string
    private func readKey() -> String? {
        var buffer = [UInt8](repeating: 0, count: 10) // Larger buffer to handle various sequences
        let count = read(FileHandle.standardInput.fileDescriptor, &buffer, 10)
        
        if count > 0 {
            // Log key codes for debugging
            var keyCodeString = "KeyCodes: "
            for i in 0..<min(count, 10) {
                keyCodeString += "\(buffer[i]) "
            }
            DebugLogger.shared.logInfo(keyCodeString)
            
            // Handle different escape sequences for arrow keys
            if buffer[0] == 27 { // ESC character
                if count >= 3 {
                    if buffer[1] == 91 { // '['
                        // Standard xterm/vt100 escape sequences
                        switch buffer[2] {
                        case 65: return "UP"     // ESC [ A
                        case 66: return "DOWN"   // ESC [ B
                        case 67: return "RIGHT"  // ESC [ C
                        case 68: return "LEFT"   // ESC [ D
                        case 72: return "HOME"   // ESC [ H
                        case 70: return "END"    // ESC [ F
                        default: break
                        }
                        
                        // Handle multi-byte escape sequences
                        if count >= 4 && buffer[2] == 51 && buffer[3] == 126 {
                            return "DELETE" // ESC [ 3 ~
                        }
                        if count >= 4 && buffer[2] == 53 && buffer[3] == 126 {
                            return "PAGE_UP" // ESC [ 5 ~
                        }
                        if count >= 4 && buffer[2] == 54 && buffer[3] == 126 {
                            return "PAGE_DOWN" // ESC [ 6 ~
                        }
                    }
                    
                    // Handle alternative arrow key sequences
                    if buffer[1] == 79 { // 'O'
                        switch buffer[2] {
                        case 65: return "UP"    // ESC O A
                        case 66: return "DOWN"  // ESC O B
                        case 67: return "RIGHT" // ESC O C
                        case 68: return "LEFT"  // ESC O D
                        default: break
                        }
                    }
                }
                
                // If no known escape sequence matched but ESC was pressed
                return "ESC"
            }
            
            // Handle common control keys
            switch buffer[0] {
            case 13:        return "ENTER"
            case 8, 127:    return "BACKSPACE" // Backspace or Delete
            case 9:         return "TAB"
            case 32:        return "SPACE"
            case 113:       return "q" // 'q' - quit
            case 104:       return "h" // 'h' - help
            case 97:        return "a" // 'a' - actions
            case 105:       return "i" // 'i' - info
            case 115:       return "s" // 's' - select/press
            case 100:       return "d" // 'd' - details
            case 99:        return "c" // 'c' - color toggle
            default:
                if let char = String(bytes: [buffer[0]], encoding: .utf8) {
                    return char
                }
            }
        }
        
        return nil
    }
    
    /// Process a key press
    /// - Parameter key: The key pressed
    private func processKey(_ key: String) {
        switch key {
        case "q", "ESC":
            running = false
            
        // Note: These navigation methods are implemented in the simpler text UI
        // instead of the original curses-style UI
        default:
            // Just quit for now - the simpleNavigatorLoop() is our primary interface
            running = false
            break
        }
    }
    
    /// Render the UI
    private func render() {
        // Clear the screen
        print("\u{001B}[2J\u{001B}[;H", terminator: "")
        
        // Get current node and tree
        guard let rootNode = rootElement else {
            print(formatter.formatMessage("No elements to display", type: .error))
            return
        }
        
        // Print header
        let appName = currentApplication?.name ?? "Unknown"
        let windowTitle = currentWindow?.title ?? "Unknown"
        let headerText = " UI Navigator: \(appName) - \(windowTitle) "
        let padding = String(repeating: "─", count: (terminalWidth - headerText.count) / 2)
        print("\u{001B}[1m\(padding)\(headerText)\(padding)\u{001B}[0m")
        
        // Print breadcrumb
        var breadcrumb = "Location: "
        for (index, element) in elementPath.enumerated() {
            let name = element.title.isEmpty ? element.role : element.title
            if index > 0 {
                breadcrumb += " > "
            }
            breadcrumb += name
        }
        print(breadcrumb)
        print(String(repeating: "─", count: terminalWidth))
        
        // Calculate main window height
        let mainHeight = showDetails ? terminalHeight - 12 : terminalHeight - 6
        
        // Render the element tree (with main node highlighted)
        renderElementTree(rootNode, maxHeight: mainHeight)
        
        // Print the divider
        print(String(repeating: "─", count: terminalWidth))
        
        // Show element details panel if enabled
        if showDetails && selectedElement != nil {
            renderElementDetails(selectedElement!)
        }
        
        // Print footer with commands
        let footer = " [q]uit | [h]elp | [a]ctions | [tab] toggle details | arrows to navigate "
        print(String(repeating: "─", count: terminalWidth))
        print("\u{001B}[1m\(footer)\u{001B}[0m")
        
        // Flush output
        fflush(stdout)
    }
    
    /// Render the element tree
    /// - Parameters:
    ///   - element: The root element to render
    ///   - prefix: The prefix for the current line
    ///   - isLast: Whether this is the last child in its parent
    ///   - maxHeight: Maximum height to render
    ///   - currentHeight: Current rendering height
    /// - Returns: The new current height
    @discardableResult
    private func renderElementTree(_ element: Element, prefix: String = "", isLast: Bool = true,
                                  maxHeight: Int = 20, currentHeight: Int = 0) -> Int {
        // Check if we've exceeded the maximum height
        if currentHeight >= maxHeight {
            print("\(prefix)└── ... (more elements)")
            return currentHeight + 1
        }
        
        // Determine the marker and next prefix
        let marker = isLast ? "└── " : "├── "
        let nextPrefix = prefix + (isLast ? "    " : "│   ")
        
        // Check if this is the selected element
        let isSelected = selectedElement == element
        
        // Format element name
        var displayTitle = element.title
        if displayTitle.isEmpty && !element.roleDescription.isEmpty {
            displayTitle = element.roleDescription
        } else if displayTitle.isEmpty {
            displayTitle = "(no title)"
        }
        
        // Build the display line
        let role = element.role
        let displayText = "\(role)[\(displayTitle)]"
        
        // Apply highlighting for selected element
        if isSelected {
            print("\(prefix)\(marker)\u{001B}[1;32m→ \(displayText)\u{001B}[0m")
        } else {
            print("\(prefix)\(marker)\(displayText)")
        }
        
        var newHeight = currentHeight + 1
        
        // Process children if this element has them and if we haven't reached max height
        if !element.children.isEmpty && newHeight < maxHeight {
            for (index, child) in element.children.enumerated() {
                let isLastChild = index == element.children.count - 1
                newHeight = renderElementTree(child, prefix: nextPrefix, isLast: isLastChild,
                                             maxHeight: maxHeight, currentHeight: newHeight)
                
                // Stop if we've hit the max height
                if newHeight >= maxHeight {
                    break
                }
            }
        } else if element.hasChildren && element.children.isEmpty {
            // Element has children but they're not loaded
            print("\(nextPrefix)└── (has children, not loaded)")
            newHeight += 1
        }
        
        return newHeight
    }
    
    /// Render details for the selected element
    /// - Parameter element: The element to show details for
    private func renderElementDetails(_ element: Element) {
        print(" Element Details:")
        print(" ---------------")
        print(" Role: \(element.role)")
        if !element.subRole.isEmpty {
            print(" SubRole: \(element.subRole)")
        }
        print(" Title: \(element.title)")
        print(" Has Children: \(element.hasChildren ? "Yes" : "No")")
        
        // Show attributes
        print(" Attributes:")
        let attributes = element.getAttributesNoThrow()
        if attributes.isEmpty {
            print("   (None available)")
        } else {
            // Show the first few attributes
            var count = 0
            for (key, value) in attributes {
                if count >= 3 {
                    print("   (... and \(attributes.count - 3) more)")
                    break
                }
                print("   \(key): \(value)")
                count += 1
            }
        }
        
        // Show available actions
        print(" Available Actions:")
        let actions = element.getAvailableActionsNoThrow()
        if actions.isEmpty {
            print("   (None available)")
        } else {
            for action in actions {
                print("   • \(action)")
            }
        }
    }
    
    /// Show help information
    private func showHelp() {
        // Clear screen
        print("\u{001B}[2J\u{001B}[;H", terminator: "")
        
        print("UI Navigator Help")
        print("================")
        print("")
        print("Navigation:")
        print("  Arrow UP/DOWN    - Navigate between siblings")
        print("  Arrow LEFT       - Navigate to parent")
        print("  Arrow RIGHT      - Navigate to first child")
        print("  ENTER            - Same as RIGHT (navigate into)")
        print("  BACKSPACE        - Go back up the hierarchy")
        print("")
        print("Actions:")
        print("  'a'              - Show available actions for selected element")
        print("  's'              - Execute default action (usually 'press') on selected element")
        print("  'i'              - Inspect element (show all properties and values)")
        print("  'd'              - Jump to deeper element directly")
        print("")
        print("Display:")
        print("  TAB              - Toggle details panel")
        print("  'c'              - Toggle color mode")
        print("")
        print("General:")
        print("  'q' or ESC       - Quit navigator")
        print("  'h'              - Show this help")
        print("")
        print("Press any key to continue...")
        
        // Wait for key press
        _ = readKey()
    }
    
    /// Show actions for the selected element
    private func showActions() {
        guard let element = selectedElement else {
            return
        }
        
        // Clear screen
        print("\u{001B}[2J\u{001B}[;H", terminator: "")
        
        print("Available Actions for \(element.role)[\(element.title)]")
        print("=================================================")
        print("")
        
        let actions = element.getAvailableActionsNoThrow()
        if actions.isEmpty {
            print("No actions available for this element")
        } else {
            for (index, action) in actions.enumerated() {
                print("  \(index + 1). \(action)")
            }
            
            print("")
            print("Enter action number to execute, or any other key to cancel:")
        }
        
        // Get action selection
        if let key = readKey(), let actionIndex = Int(key), actionIndex > 0 && actionIndex <= actions.count {
            let action = actions[actionIndex - 1]
            performAction(action)
        }
    }
    
    /// Perform the default action on the selected element
    /// - Parameter action: Optional specific action to perform (uses default if nil)
    private func performAction(_ action: String? = nil) {
        guard let element = selectedElement else {
            return
        }
        
        let actionToPerform = action ?? "press"
        
        do {
            try element.performAction(actionToPerform)
            
            // Show confirmation
            let msg = "Performed '\(actionToPerform)' on \(element.role)[\(element.title)]"
            showTemporaryMessage(msg, type: .success)
        } catch {
            showTemporaryMessage("Error: \(error.localizedDescription)", type: .error)
        }
    }
    
    /// Show a temporary message
    /// - Parameters:
    ///   - message: The message to show
    ///   - type: The message type
    private func showTemporaryMessage(_ message: String, type: MessageType) {
        // Print message with appropriate color
        switch type {
        case .success:
            print("\u{001B}[1;32m\(message)\u{001B}[0m")
        case .error:
            print("\u{001B}[1;31m\(message)\u{001B}[0m")
        case .warning:
            print("\u{001B}[1;33m\(message)\u{001B}[0m")
        case .info:
            print("\u{001B}[1;34m\(message)\u{001B}[0m")
        }
        
        // Flush output
        fflush(stdout)
    }
}

extension OutputFormatter {
    /// Format a UI element for display in the navigator
    /// - Parameter element: The element to format
    /// - Returns: Formatted string representation
    func formatUIElement(_ element: Element) -> String {
        let role = element.role
        var displayTitle = element.title
        
        if displayTitle.isEmpty && !element.roleDescription.isEmpty {
            displayTitle = element.roleDescription
        } else if displayTitle.isEmpty {
            displayTitle = "(no title)"
        }
        
        return "\(role)[\(displayTitle)]"
    }
}