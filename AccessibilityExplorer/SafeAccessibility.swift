// ABOUTME: Provides controlled, safe access to macOS Accessibility APIs
// ABOUTME: Implements safety measures to prevent freezing and high CPU usage

import SwiftUI
import Foundation
import AppKit

/// Provides controlled, safe access to macOS Accessibility APIs with strict timeout enforcement
class SafeAccessibility {
    /// Singleton instance for access
    static let shared = SafeAccessibility()
    
    // Whether to use real accessibility APIs or static mock data
    private(set) var useMockData = true
    
    // Timeouts to prevent freezing
    private let defaultTimeout: TimeInterval = 0.5
    private let appListTimeout: TimeInterval = 1.0
    
    // Status tracking for UI
    private(set) var isLoading = false
    private(set) var lastError: String? = nil
    
    // Tracks operations to limit parallel requests
    private var operationCount = 0
    private let maxConcurrentOperations = 1
    private let operationQueue = DispatchQueue(label: "com.accessibility-explorer.operations", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 1)
    
    // Safety thresholds
    private var highCPUThreshold: Double = 70.0
    private var maxOperationTime: TimeInterval = 3.0
    
    private init() {
        // Default to mock data for initial safety
        useMockData = true
        
        // Start CPU monitoring
        startCPUMonitoring()
    }
    
    /// Enables/disables real accessibility API access
    func setUseMockData(_ useMock: Bool) {
        // If disabling mock data, check permissions first
        if !useMock && !checkAccessibilityPermissions() {
            // Keep mock data enabled if permissions aren't granted
            useMockData = true
            lastError = "Accessibility permissions not granted. Using mock data."
            return
        }
        
        useMockData = useMock
        print("SafeAccessibility: Using \(useMock ? "mock" : "real") data")
    }
    
    /// Gets a list of running applications with safety limits
    func getApplications(completion: @escaping ([AppInfo]) -> Void) {
        guard canStartOperation() else {
            // Too many operations running, return mock data
            print("SafeAccessibility: Too many operations, using mock data")
            completion(MockDataProvider.getApplications())
            return
        }
        
        incrementOperationCount()
        
        if useMockData {
            // Return mock data immediately
            let mockApps = MockDataProvider.getApplications()
            decrementOperationCount()
            completion(mockApps)
            return
        }
        
        // Use real accessibility APIs with strict timeout
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Generate a timer that will force-complete this operation
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: self.appListTimeout, repeats: false) { _ in
                print("SafeAccessibility: Application list request timed out")
                self.lastError = "Application list request timed out"
                self.decrementOperationCount()
                completion(MockDataProvider.getApplications())
            }
            
            // Try to get real running applications
            do {
                var apps: [AppInfo] = []
                let workspace = NSWorkspace.shared
                let runningApps = workspace.runningApplications
                
                // Filter to only apps with UI (limited to max 10)
                let uiApps = runningApps.filter { $0.activationPolicy == .regular }.prefix(10)
                
                for app in uiApps {
                    if let bundleID = app.bundleIdentifier {
                        apps.append(AppInfo(
                            name: app.localizedName ?? "Unknown",
                            bundleID: bundleID,
                            pid: app.processIdentifier,
                            icon: "app"
                        ))
                    }
                }
                
                // Cancel the timeout timer since we succeeded
                timeoutTimer.invalidate()
                self.decrementOperationCount()
                completion(apps)
            } catch {
                // Something went wrong, use mock data as fallback
                print("SafeAccessibility: Error getting applications: \(error)")
                self.lastError = "Error: \(error.localizedDescription)"
                
                // Cancel the timeout timer
                timeoutTimer.invalidate()
                self.decrementOperationCount()
                completion(MockDataProvider.getApplications())
            }
        }
    }
    
    /// Gets UI elements for an application with safety limits
    func getUIElementsForApp(appInfo: AppInfo, completion: @escaping (UINode?) -> Void) {
        guard canStartOperation() else {
            // Too many operations running, return mock data
            print("SafeAccessibility: Too many operations, using mock data")
            completion(MockDataProvider.getUIElementsForApp(appInfo: appInfo))
            return
        }
        
        incrementOperationCount()
        
        if useMockData {
            // Return mock data immediately with a small delay to simulate real API calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.decrementOperationCount()
                completion(MockDataProvider.getUIElementsForApp(appInfo: appInfo))
            }
            return
        }
        
        // Use real accessibility APIs with strict timeout
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Generate a timer that will force-complete this operation
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: self.defaultTimeout, repeats: false) { _ in
                print("SafeAccessibility: UI element request timed out")
                self.lastError = "UI element request timed out"
                self.decrementOperationCount()
                completion(MockDataProvider.getUIElementsForApp(appInfo: appInfo))
            }
            
            // Try to get real UI elements using AXUIElement
            do {
                // Create an AXUIElement reference for the application
                let axApp = AXUIElementCreateApplication(appInfo.pid)
                
                // Create the root node for this application
                let rootNode = UINode(name: appInfo.name, role: "Application", appInfo: appInfo, description: "Application process")
                
                // Get application windows
                var windowsRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
                
                if result == .success, let windowsArray = windowsRef as? [AXUIElement] {
                    // Process each window
                    for window in windowsArray.prefix(3) { // Limit to 3 windows to prevent freezing
                        if let windowNode = self.createNodeFromElement(element: window, role: "Window", parent: rootNode, appInfo: appInfo) {
                            rootNode.addChild(windowNode)
                            
                            // Get limited children for this window (first level only to prevent deep recursion)
                            self.getChildrenForElement(element: window, parent: windowNode, appInfo: appInfo, maxDepth: 1)
                        }
                    }
                }
                
                // Get application menu bar (without recursing into all menu items to prevent freezing)
                var menuBarRef: CFTypeRef?
                let menuResult = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarRef)
                
                if menuResult == .success, let menuBar = menuBarRef as? AXUIElement {
                    if let menuBarNode = self.createNodeFromElement(element: menuBar, role: "MenuBar", parent: rootNode, appInfo: appInfo) {
                        rootNode.addChild(menuBarNode)
                        
                        // Get only top-level menu items without recursing into all submenus
                        self.getChildrenForElement(element: menuBar, parent: menuBarNode, appInfo: appInfo, maxDepth: 1)
                    }
                }
                
                // Cancel the timeout timer since we succeeded
                timeoutTimer.invalidate()
                self.decrementOperationCount()
                completion(rootNode)
            } catch {
                // Something went wrong, use mock data as fallback
                print("SafeAccessibility: Error getting UI elements: \(error)")
                self.lastError = "Error: \(error.localizedDescription)"
                
                // Cancel the timeout timer
                timeoutTimer.invalidate()
                self.decrementOperationCount()
                completion(MockDataProvider.getUIElementsForApp(appInfo: appInfo))
            }
        }
    }
    
    /// Gets the specific properties for a UI element with safety limits
    func getPropertiesForElement(element: UINode, completion: @escaping ([String: String]) -> Void) {
        guard canStartOperation() else {
            // Too many operations running, return mock data
            print("SafeAccessibility: Too many operations, using mock data")
            completion(MockDataProvider.getPropertiesForElement(element: element))
            return
        }
        
        incrementOperationCount()
        
        if useMockData {
            // Return mock data immediately
            let properties = MockDataProvider.getPropertiesForElement(element: element)
            decrementOperationCount()
            completion(properties)
            return
        }
        
        // Use real accessibility APIs with strict timeout
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Generate a timer that will force-complete this operation
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: self.defaultTimeout, repeats: false) { _ in
                print("SafeAccessibility: Properties request timed out")
                self.lastError = "Properties request timed out"
                self.decrementOperationCount()
                completion(MockDataProvider.getPropertiesForElement(element: element))
            }
            
            // Try to get real properties from the AXUIElement
            do {
                // Check if we have an AXUIElement stored in our element
                if let axElement = element.axElement {
                    // Get all properties from the AXUIElement
                    var properties = [String: String]()
                    
                    // Get basic properties first
                    properties["Name"] = element.name
                    properties["Role"] = element.role
                    properties["Description"] = element.description
                    
                    // Get standard attributes if available
                    let attributes = self.getAttributeNames(for: axElement)
                    
                    for attribute in attributes {
                        if let value = self.getAttributeValue(for: axElement, attribute: attribute) {
                            properties[attribute] = value
                        }
                    }
                    
                    // Get additional properties based on role
                    switch element.role {
                    case "Application":
                        properties["Process ID"] = "\(element.appInfo.pid)"
                        properties["Bundle ID"] = element.appInfo.bundleID
                    case "Window":
                        if let frontmost = getBooleanAttributeValue(for: axElement, attribute: kAXFrontmostAttribute as String) {
                            properties["Frontmost"] = frontmost ? "true" : "false"
                        }
                        if let minimized = getBooleanAttributeValue(for: axElement, attribute: kAXMinimizedAttribute as String) {
                            properties["Minimized"] = minimized ? "true" : "false"
                        }
                    default:
                        break
                    }
                    
                    // Get position and size
                    if let position = getPositionValue(for: axElement) {
                        properties["Position"] = position
                    }
                    if let size = getSizeValue(for: axElement) {
                        properties["Size"] = size
                    }
                    
                    // Cancel the timeout timer since we succeeded
                    timeoutTimer.invalidate()
                    self.decrementOperationCount()
                    completion(properties)
                } else {
                    // No AXUIElement reference available, use mock data
                    let mockProperties = MockDataProvider.getPropertiesForElement(element: element)
                    
                    // Cancel the timeout timer
                    timeoutTimer.invalidate()
                    self.decrementOperationCount()
                    completion(mockProperties)
                }
            } catch {
                // Something went wrong, use mock data as fallback
                print("SafeAccessibility: Error getting properties: \(error)")
                self.lastError = "Error: \(error.localizedDescription)"
                
                // Cancel the timeout timer
                timeoutTimer.invalidate()
                self.decrementOperationCount()
                completion(MockDataProvider.getPropertiesForElement(element: element))
            }
        }
    }
    
    /// Check if accessibility APIs are permitted and can be used
    private func checkAccessibilityPermissions() -> Bool {
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
    }
    
    /// Check if a new operation can be started
    private func canStartOperation() -> Bool {
        semaphore.wait()
        defer { semaphore.signal() }
        
        // Check if too many operations are already running
        if operationCount >= maxConcurrentOperations {
            return false
        }
        
        // Check if CPU usage is too high
        if isUsingTooMuchCPU() {
            print("SafeAccessibility: CPU usage too high, using mock data")
            lastError = "CPU usage too high, using mock data"
            return false
        }
        
        return true
    }
    
    /// Increment the operation counter
    private func incrementOperationCount() {
        semaphore.wait()
        operationCount += 1
        isLoading = operationCount > 0
        semaphore.signal()
    }
    
    /// Decrement the operation counter
    private func decrementOperationCount() {
        semaphore.wait()
        operationCount -= 1
        isLoading = operationCount > 0
        semaphore.signal()
    }
    
    /// Check if CPU usage is too high
    private func isUsingTooMuchCPU() -> Bool {
        // Get CPU usage for this process
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
                let usage = Double(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                return usage > highCPUThreshold
            }
        } catch {
            print("Error getting CPU usage: \(error)")
        }
        
        // Default to false if we couldn't check
        return false
    }
    
    /// Start periodic CPU monitoring
    private func startCPUMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if let self = self, self.isUsingTooMuchCPU() {
                print("SafeAccessibility: High CPU usage detected, forcing mock data")
                self.useMockData = true
            }
        }
    }
    
    // MARK: - AXUIElement Helper Methods
    
    /// Create a UINode from an AXUIElement - Public API for other classes
    func createNodeFromElement(element: AXUIElement, role: String? = nil, parent: UINode? = nil, appInfo: AppInfo) -> UINode? {
        // Get the role if not provided
        let roleValue = role ?? getRole(for: element) ?? "Unknown"
        
        // Get the name and description
        let name = getName(for: element) ?? roleValue
        let description = getDescription(for: element) ?? ""
        
        // Create node with reference to the AXUIElement
        let node = UINode(
            name: name,
            role: roleValue,
            appInfo: appInfo,
            description: description,
            parent: parent,
            axElement: element
        )
        
        return node
    }
    
    /// Get children for an AXUIElement and add them to the parent node
    private func getChildrenForElement(element: AXUIElement, parent: UINode, appInfo: AppInfo, maxDepth: Int = 1, currentDepth: Int = 0) {
        // Don't recurse too deep to prevent freezing
        guard currentDepth < maxDepth else { return }
        
        // Get children
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        
        if result == .success, let childrenArray = childrenRef as? [AXUIElement] {
            // Limit to a reasonable number of children to prevent freezing
            let maxChildren = 20
            for childElement in childrenArray.prefix(maxChildren) {
                if let childNode = createNodeFromElement(element: childElement, parent: parent, appInfo: appInfo) {
                    parent.addChild(childNode)
                    
                    // Recurse to next level if not at max depth yet
                    if currentDepth + 1 < maxDepth {
                        getChildrenForElement(
                            element: childElement,
                            parent: childNode,
                            appInfo: appInfo,
                            maxDepth: maxDepth,
                            currentDepth: currentDepth + 1
                        )
                    }
                }
            }
        }
    }
    
    /// Get the role of an AXUIElement
    private func getRole(for element: AXUIElement) -> String? {
        var roleRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        
        if result == .success, let role = roleRef as? String {
            return role
        }
        return nil
    }
    
    /// Get the name of an AXUIElement
    private func getName(for element: AXUIElement) -> String? {
        var nameRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &nameRef)
        
        if result == .success, let name = nameRef as? String {
            return name
        }
        
        // Try description if title is not available
        var descRef: CFTypeRef?
        let descResult = AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        
        if descResult == .success, let desc = descRef as? String, !desc.isEmpty {
            return desc
        }
        
        // Try value as a last resort
        var valueRef: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
        
        if valueResult == .success, let value = valueRef as? String, !value.isEmpty {
            return value
        }
        
        return nil
    }
    
    /// Get the description of an AXUIElement
    private func getDescription(for element: AXUIElement) -> String? {
        var descRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        
        if result == .success, let desc = descRef as? String {
            return desc
        }
        
        // Try help text as a fallback
        var helpRef: CFTypeRef?
        let helpResult = AXUIElementCopyAttributeValue(element, kAXHelpAttribute as CFString, &helpRef)
        
        if helpResult == .success, let help = helpRef as? String {
            return help
        }
        
        return nil
    }
    
    /// Get all available attribute names for an AXUIElement
    private func getAttributeNames(for element: AXUIElement) -> [String] {
        var namesRef: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &namesRef)
        
        if result == .success, let names = namesRef as? [String] {
            return names
        }
        
        return []
    }
    
    /// Get the value of an attribute as a string
    private func getAttributeValue(for element: AXUIElement, attribute: String) -> String? {
        var valueRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef)
        
        if result == .success {
            // Handle different value types
            if let stringValue = valueRef as? String {
                return stringValue
            } else if let numberValue = valueRef as? NSNumber {
                return numberValue.stringValue
            } else if let boolValue = valueRef as? Bool {
                return boolValue ? "true" : "false"
            } else if CFGetTypeID(valueRef as CFTypeRef) == AXUIElementGetTypeID() {
                // This is another AXUIElement - just return its role
                if let childElement = valueRef as? AXUIElement {
                    return getRole(for: childElement) ?? "Element"
                }
                return "Element"
            } else if valueRef == nil {
                return "nil"
            } else {
                // Special handling for arrays and other complex types
                if CFGetTypeID(valueRef as CFTypeRef) == CFArrayGetTypeID() {
                    return "(Array with \((valueRef as? NSArray)?.count ?? 0) items)"
                }
                return "(Complex Value)"
            }
        }
        
        return nil
    }
    
    /// Get a boolean attribute value
    private func getBooleanAttributeValue(for element: AXUIElement, attribute: String) -> Bool? {
        var valueRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef)
        
        if result == .success, let value = valueRef as? Bool {
            return value
        }
        
        return nil
    }
    
    /// Get position value as a formatted string
    private func getPositionValue(for element: AXUIElement) -> String? {
        var positionRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        
        if result == .success, let position = positionRef as? NSValue {
            var point = NSPoint()
            position.getValue(&point)
            return "{x: \(Int(point.x)), y: \(Int(point.y))}"
        }
        
        return nil
    }
    
    /// Get size value as a formatted string
    private func getSizeValue(for element: AXUIElement) -> String? {
        var sizeRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
        
        if result == .success, let size = sizeRef as? NSValue {
            var sizeValue = NSSize()
            size.getValue(&sizeValue)
            return "{width: \(Int(sizeValue.width)), height: \(Int(sizeValue.height))}"
        }
        
        return nil
    }
}

/// Data structure for application information
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleID: String
    let pid: Int32
    let icon: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a node in the UI hierarchy
class UINode: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let role: String
    let appInfo: AppInfo
    let description: String
    
    // Optional reference to the actual accessibility element
    var axElement: AXUIElement?
    
    @Published var isExpanded = false
    @Published var isSelected = false
    @Published var children: [UINode] = []
    @Published var isLoading = false
    
    weak var parent: UINode?
    
    init(name: String, role: String, appInfo: AppInfo, description: String = "", parent: UINode? = nil, axElement: AXUIElement? = nil) {
        self.name = name
        self.role = role
        self.appInfo = appInfo
        self.description = description
        self.parent = parent
        self.axElement = axElement
    }
    
    func addChild(_ child: UINode) {
        child.parent = self
        children.append(child)
    }
    
    func getAncestors() -> [UINode] {
        var ancestors: [UINode] = []
        var current: UINode? = self.parent
        
        while let parent = current {
            ancestors.insert(parent, at: 0)
            current = parent.parent
        }
        
        return ancestors
    }
}

/// Provides mock accessibility data for testing and when real APIs are unavailable
class MockDataProvider {
    /// Get a list of mock applications
    static func getApplications() -> [AppInfo] {
        return [
            AppInfo(name: "Safari", bundleID: "com.apple.Safari", pid: 1001, icon: "safari"),
            AppInfo(name: "TextEdit", bundleID: "com.apple.TextEdit", pid: 1002, icon: "doc.text"),
            AppInfo(name: "Finder", bundleID: "com.apple.finder", pid: 1003, icon: "folder"),
            AppInfo(name: "Mail", bundleID: "com.apple.mail", pid: 1004, icon: "envelope"),
            AppInfo(name: "Photos", bundleID: "com.apple.Photos", pid: 1005, icon: "photo"),
            AppInfo(name: "Calendar", bundleID: "com.apple.iCal", pid: 1006, icon: "calendar"),
            AppInfo(name: "Notes", bundleID: "com.apple.Notes", pid: 1007, icon: "note.text"),
            AppInfo(name: "Maps", bundleID: "com.apple.Maps", pid: 1008, icon: "map"),
            AppInfo(name: "Messages", bundleID: "com.apple.MobileSMS", pid: 1009, icon: "message"),
            AppInfo(name: "System Settings", bundleID: "com.apple.systempreferences", pid: 1010, icon: "gearshape")
        ]
    }
    
    /// Get mock UI elements for a specific application
    static func getUIElementsForApp(appInfo: AppInfo) -> UINode {
        // Create root application node
        let rootNode = UINode(name: appInfo.name, role: "Application", appInfo: appInfo, description: "Application process")
        
        // Add main window
        let mainWindow = UINode(name: "Main Window", role: "Window", appInfo: appInfo, description: "Main application window", parent: rootNode)
        rootNode.addChild(mainWindow)
        
        // Add menu bar
        let menuBar = UINode(name: "Menu Bar", role: "MenuBar", appInfo: appInfo, description: "Application menu bar", parent: rootNode)
        rootNode.addChild(menuBar)
        
        // Add common window elements
        let toolbar = UINode(name: "Toolbar", role: "Toolbar", appInfo: appInfo, description: "Window toolbar", parent: mainWindow)
        mainWindow.addChild(toolbar)
        
        let contentArea = UINode(name: "Content Area", role: "Group", appInfo: appInfo, description: "Main content area", parent: mainWindow)
        mainWindow.addChild(contentArea)
        
        let statusBar = UINode(name: "Status Bar", role: "Group", appInfo: appInfo, description: "Status information", parent: mainWindow)
        mainWindow.addChild(statusBar)
        
        // Add toolbar elements
        toolbar.addChild(UINode(name: "New", role: "Button", appInfo: appInfo, description: "Create new document", parent: toolbar))
        toolbar.addChild(UINode(name: "Open", role: "Button", appInfo: appInfo, description: "Open document", parent: toolbar))
        toolbar.addChild(UINode(name: "Save", role: "Button", appInfo: appInfo, description: "Save document", parent: toolbar))
        toolbar.addChild(UINode(name: "Search", role: "SearchField", appInfo: appInfo, description: "Search in document", parent: toolbar))
        
        // Add content specific to app type
        switch appInfo.name {
        case "Safari":
            // Safari-specific UI elements
            let addressBar = UINode(name: "Address Bar", role: "TextField", appInfo: appInfo, description: "URL field", parent: contentArea)
            contentArea.addChild(addressBar)
            
            let webContent = UINode(name: "Web Content", role: "WebArea", appInfo: appInfo, description: "Web page content", parent: contentArea)
            contentArea.addChild(webContent)
            
            let tabGroup = UINode(name: "Tabs", role: "TabGroup", appInfo: appInfo, description: "Browser tabs", parent: contentArea)
            contentArea.addChild(tabGroup)
            
            // Add web content elements
            webContent.addChild(UINode(name: "Heading", role: "Heading", appInfo: appInfo, description: "Page heading", parent: webContent))
            webContent.addChild(UINode(name: "Navigation", role: "Navigation", appInfo: appInfo, description: "Site navigation", parent: webContent))
            webContent.addChild(UINode(name: "Main Content", role: "Article", appInfo: appInfo, description: "Page content", parent: webContent))
            
            // Add tab elements
            tabGroup.addChild(UINode(name: "Tab 1", role: "Tab", appInfo: appInfo, description: "First tab", parent: tabGroup))
            tabGroup.addChild(UINode(name: "Tab 2", role: "Tab", appInfo: appInfo, description: "Second tab", parent: tabGroup))
            
        case "TextEdit":
            // TextEdit-specific UI elements
            let textArea = UINode(name: "Text Area", role: "TextArea", appInfo: appInfo, description: "Document text", parent: contentArea)
            contentArea.addChild(textArea)
            
            let formatBar = UINode(name: "Format Bar", role: "Group", appInfo: appInfo, description: "Formatting controls", parent: contentArea)
            contentArea.addChild(formatBar)
            
            // Add format bar elements
            formatBar.addChild(UINode(name: "Bold", role: "Button", appInfo: appInfo, description: "Bold text", parent: formatBar))
            formatBar.addChild(UINode(name: "Italic", role: "Button", appInfo: appInfo, description: "Italic text", parent: formatBar))
            formatBar.addChild(UINode(name: "Underline", role: "Button", appInfo: appInfo, description: "Underline text", parent: formatBar))
            
        case "Finder":
            // Finder-specific UI elements
            let sidebar = UINode(name: "Sidebar", role: "List", appInfo: appInfo, description: "Favorites and locations", parent: contentArea)
            contentArea.addChild(sidebar)
            
            let fileList = UINode(name: "File List", role: "Table", appInfo: appInfo, description: "Files and folders", parent: contentArea)
            contentArea.addChild(fileList)
            
            // Add sidebar elements
            let favorites = UINode(name: "Favorites", role: "Group", appInfo: appInfo, description: "Favorite locations", parent: sidebar)
            sidebar.addChild(favorites)
            
            let locations = UINode(name: "Locations", role: "Group", appInfo: appInfo, description: "Storage locations", parent: sidebar)
            sidebar.addChild(locations)
            
            // Add file list elements
            fileList.addChild(UINode(name: "Document.pdf", role: "FileItem", appInfo: appInfo, description: "PDF document", parent: fileList))
            fileList.addChild(UINode(name: "Image.jpg", role: "FileItem", appInfo: appInfo, description: "JPEG image", parent: fileList))
            fileList.addChild(UINode(name: "Folder", role: "FolderItem", appInfo: appInfo, description: "Folder", parent: fileList))
            
        default:
            // Generic UI elements for other apps
            contentArea.addChild(UINode(name: "Generic Content", role: "Group", appInfo: appInfo, description: "Application content", parent: contentArea))
            statusBar.addChild(UINode(name: "Status Text", role: "StaticText", appInfo: appInfo, description: "Status information", parent: statusBar))
        }
        
        // Add menu elements
        let fileMenu = UINode(name: "File", role: "Menu", appInfo: appInfo, description: "File menu", parent: menuBar)
        menuBar.addChild(fileMenu)
        
        let editMenu = UINode(name: "Edit", role: "Menu", appInfo: appInfo, description: "Edit menu", parent: menuBar)
        menuBar.addChild(editMenu)
        
        let viewMenu = UINode(name: "View", role: "Menu", appInfo: appInfo, description: "View menu", parent: menuBar)
        menuBar.addChild(viewMenu)
        
        let helpMenu = UINode(name: "Help", role: "Menu", appInfo: appInfo, description: "Help menu", parent: menuBar)
        menuBar.addChild(helpMenu)
        
        // Add file menu items
        fileMenu.addChild(UINode(name: "New", role: "MenuItem", appInfo: appInfo, description: "Create new document", parent: fileMenu))
        fileMenu.addChild(UINode(name: "Open...", role: "MenuItem", appInfo: appInfo, description: "Open document", parent: fileMenu))
        fileMenu.addChild(UINode(name: "Save", role: "MenuItem", appInfo: appInfo, description: "Save document", parent: fileMenu))
        fileMenu.addChild(UINode(name: "Close", role: "MenuItem", appInfo: appInfo, description: "Close document", parent: fileMenu))
        
        return rootNode
    }
    
    /// Get mock properties for a UI element
    static func getPropertiesForElement(element: UINode) -> [String: String] {
        var properties: [String: String] = [
            "Name": element.name,
            "Role": element.role,
            "Description": element.description,
            "Enabled": "true",
            "Focused": "false"
        ]
        
        // Add role-specific properties
        switch element.role {
        case "Button":
            properties["Button Type"] = "Push Button"
            properties["Enabled"] = "true"
            properties["Position"] = "{x: 100, y: 50}"
            properties["Size"] = "{width: 80, height: 24}"
            
        case "TextField", "TextArea":
            properties["Value"] = "Sample text"
            properties["Editable"] = "true"
            properties["Position"] = "{x: 120, y: 80}"
            properties["Size"] = "{width: 200, height: 20}"
            properties["Placeholder"] = "Enter text here"
            
        case "Window":
            properties["Focused"] = "true"
            properties["Main"] = "true"
            properties["Minimized"] = "false"
            properties["Position"] = "{x: 0, y: 0}"
            properties["Size"] = "{width: 800, height: 600}"
            properties["Close Button"] = "Available"
            
        case "Application":
            properties["Frontmost"] = "true"
            properties["Hidden"] = "false"
            properties["Path"] = "/Applications/\(element.name).app"
            properties["Process ID"] = "\(element.appInfo.pid)"
            properties["Bundle ID"] = element.appInfo.bundleID
            
        case "Menu", "MenuItem":
            properties["Enabled"] = "true"
            properties["Title"] = element.name
            properties["Selected"] = "false"
            
        case "WebArea":
            properties["URL"] = "https://example.com"
            properties["Loading"] = "false"
            
        default:
            properties["Position"] = "{x: 50, y: 50}"
            properties["Size"] = "{width: 100, height: 30}"
        }
        
        // Add accessibility properties
        properties["Help Text"] = "This is a \(element.role.lowercased())"
        properties["Identifier"] = "com.example.\(element.role.lowercased()).\(element.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        
        return properties
    }
}