// ABOUTME: Simple accessibility explorer app with basic safety mechanisms
// ABOUTME: Designed to avoid freezing issues while providing real accessibility data

import SwiftUI
import AppKit

// AX action constants not exposed in AppKit
let kAXMinimizeAction = "AXMinimize"
let kAXCloseAction = "AXClose"

/// Simple model for an application
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

/// Model for a UI element node
class UIElement: Identifiable, ObservableObject {
    let id = UUID()
    var name: String
    let role: String
    let appInfo: AppInfo
    var description: String
    
    // Reference to the AXUIElement
    let axElement: AXUIElement?
    
    // Enhanced accessibility attributes
    var identifier: String = ""
    var value: String = ""
    var label: String = ""
    var help: String = ""
    var enabled: Bool = true
    var focused: Bool = false
    var selected: Bool = false
    var position: NSPoint?
    var size: NSSize?
    var availableActions: [String] = []
    var subrole: String = ""
    var placeholderValue: String = ""
    
    @Published var isExpanded = false
    @Published var isSelected = false
    @Published var children: [UIElement] = []
    @Published var isLoading = false
    
    weak var parent: UIElement?
    
    init(name: String, role: String, appInfo: AppInfo, description: String = "", parent: UIElement? = nil, axElement: AXUIElement? = nil) {
        self.name = name
        self.role = role
        self.appInfo = appInfo
        self.description = description
        self.parent = parent
        self.axElement = axElement
        
        // Initialize additional properties if we have an AXUIElement
        if let axElement = axElement {
            loadBasicProperties(from: axElement)
        }
    }
    
    /// Load basic properties from the accessibility element
    private func loadBasicProperties(from axElement: AXUIElement) {
        // Load identifier
        var valueRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXIdentifierAttribute as CFString, &valueRef) == .success,
           let value = valueRef as? String {
            self.identifier = value
        }
        
        // Load value
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef) == .success {
            if let stringValue = valueRef as? String {
                self.value = stringValue
            } else if let numberValue = valueRef as? NSNumber {
                self.value = numberValue.stringValue
            } else if let boolValue = valueRef as? Bool {
                self.value = boolValue ? "true" : "false"
            }
        }
        
        // Load enabled state
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXEnabledAttribute as CFString, &valueRef) == .success,
           let enabled = valueRef as? Bool {
            self.enabled = enabled
        }
        
        // Load focused state
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXFocusedAttribute as CFString, &valueRef) == .success,
           let focused = valueRef as? Bool {
            self.focused = focused
        }
        
        // Load selected state
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXSelectedAttribute as CFString, &valueRef) == .success,
           let selected = valueRef as? Bool {
            self.selected = selected
        }
        
        // Load subrole
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXSubroleAttribute as CFString, &valueRef) == .success,
           let subrole = valueRef as? String {
            self.subrole = subrole
        }
        
        // Load placeholder value
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXPlaceholderValueAttribute as CFString, &valueRef) == .success,
           let placeholder = valueRef as? String {
            self.placeholderValue = placeholder
        }
        
        // Load help text
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXHelpAttribute as CFString, &valueRef) == .success,
           let help = valueRef as? String {
            self.help = help
        }
        
        // Load position
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &valueRef) == .success,
           let positionValue = valueRef as? NSValue {
            var point = NSPoint()
            positionValue.getValue(&point)
            self.position = point
        }
        
        // Load size
        valueRef = nil
        if AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &valueRef) == .success,
           let sizeValue = valueRef as? NSValue {
            var size = NSSize()
            sizeValue.getValue(&size)
            self.size = size
        }
        
        // Load available actions
        var actionsArrayRef: CFArray?
        if AXUIElementCopyActionNames(axElement, &actionsArrayRef) == .success,
           let actionNames = actionsArrayRef as? [String] {
            self.availableActions = actionNames
        }
    }
    
    func addChild(_ child: UIElement) {
        child.parent = self
        children.append(child)
    }
    
    func getAncestors() -> [UIElement] {
        var ancestors: [UIElement] = []
        var current: UIElement? = self.parent
        
        while let parent = current {
            ancestors.insert(parent, at: 0)
            current = parent.parent
        }
        
        return ancestors
    }
}

// SafeAccessibility class is now defined in SafeAccessibility.swift

/// Main view model for the app
class ExplorerViewModel: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var selectedApp: AppInfo? = nil
    @Published var rootElement: UIElement? = nil
    @Published var selectedElement: UIElement? = nil
    @Published var properties: [String: String] = [:]
    
    @Published var useMockData = false {
        didSet {
            if selectedApp != nil {
                refreshElementTree()
            }
        }
    }
    
    @Published var isLoading = false
    @Published var lastErrorMessage: String? = nil
    
    init() {
        useMockData = false // Always use real accessibility API
        loadApplications()
    }
    
    func loadApplications() {
        isLoading = true
        
        // Load applications using the Workspace API
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
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
            
            DispatchQueue.main.async {
                self?.applications = apps
                self?.isLoading = false
            }
        }
    }
    
    func selectApplication(_ app: AppInfo) {
        self.selectedApp = app
        self.rootElement = nil
        self.selectedElement = nil
        
        refreshElementTree()
    }
    
    func refreshElementTree() {
        guard let app = selectedApp else { return }
        
        isLoading = true
        
        // Create a new root element for the application
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Create an AXUIElement for the application
            let axApp = AXUIElementCreateApplication(app.pid)
            let rootElement = UIElement(name: app.name, role: "Application", appInfo: app, description: "Application process", axElement: axApp)
            
            // Get windows
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            
            if result == .success, let windowsArray = windowsRef as? [AXUIElement] {
                // Limit to first 3 windows
                for window in windowsArray.prefix(3) {
                    // Get window title
                    var titleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                    let title = (titleRef as? String) ?? "Window"
                    
                    // Create window element
                    let windowElement = UIElement(
                        name: title,
                        role: "Window",
                        appInfo: app,
                        description: "Application window",
                        parent: rootElement,
                        axElement: window
                    )
                    rootElement.addChild(windowElement)
                }
            }
            
            DispatchQueue.main.async {
                self?.rootElement = rootElement
                self?.selectedElement = rootElement
                self?.isLoading = false
                
                self?.loadProperties(for: rootElement)
            }
        }
    }
    
    func selectElement(_ element: UIElement) {
        // Deselect previous selection
        self.selectedElement?.isSelected = false
        
        // Select new element
        element.isSelected = true
        self.selectedElement = element
        
        // Load properties
        loadProperties(for: element)
    }
    
    func expandElement(_ element: UIElement) {
        if element.children.isEmpty && !element.isLoading {
            element.isLoading = true
            
            loadChildren(for: element) {
                DispatchQueue.main.async {
                    element.isLoading = false
                    element.isExpanded = true
                }
            }
        } else {
            element.isExpanded = true
        }
    }
    
    func collapseElement(_ element: UIElement) {
        element.isExpanded = false
    }
    
    func loadProperties(for element: UIElement) {
        // Load properties directly from the AXUIElement
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var properties: [String: String] = [
                "Name": element.name,
                "Role": element.role,
                "Description": element.description
            ]
            
            // Try to get real properties if we have a reference
            if let axElement = element.axElement {
                // Get attributes
                var namesRef: CFArray?
                if AXUIElementCopyAttributeNames(axElement, &namesRef) == .success,
                   let attributeNames = namesRef as? [String] {
                    
                    // Get a value for each attribute with a timeout safety
                    for name in attributeNames.prefix(20) { // Limit to 20 attributes
                        var valueRef: CFTypeRef?
                        if AXUIElementCopyAttributeValue(axElement, name as CFString, &valueRef) == .success {
                            // Convert different value types to strings
                            if let stringValue = valueRef as? String {
                                properties[name] = stringValue
                            } else if let numberValue = valueRef as? NSNumber {
                                properties[name] = numberValue.stringValue
                            } else if let boolValue = valueRef as? Bool {
                                properties[name] = boolValue ? "true" : "false"
                            } else if CFGetTypeID(valueRef as CFTypeRef) == AXUIElementGetTypeID() {
                                properties[name] = "Element"
                            } else if valueRef == nil {
                                properties[name] = "nil"
                            } else {
                                properties[name] = "Complex Value"
                            }
                        }
                    }
                    
                    // Get position and size specifically
                    if element.role == "Window" || element.role == "Button" {
                        var positionRef: CFTypeRef?
                        if AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &positionRef) == .success,
                           let position = positionRef as? NSValue {
                            var point = NSPoint()
                            position.getValue(&point)
                            properties["Position"] = "{x: \(Int(point.x)), y: \(Int(point.y))}"
                        }
                        
                        var sizeRef: CFTypeRef?
                        if AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &sizeRef) == .success,
                           let size = sizeRef as? NSValue {
                            var sizeValue = NSSize()
                            size.getValue(&sizeValue)
                            properties["Size"] = "{width: \(Int(sizeValue.width)), height: \(Int(sizeValue.height))}"
                        }
                    }
                }
                
                // Get available actions
                var actionsArrayRef: CFArray?
                if AXUIElementCopyActionNames(axElement, &actionsArrayRef) == .success,
                   let actionNames = actionsArrayRef as? [String] {
                    if !actionNames.isEmpty {
                        properties["Available Actions"] = actionNames.joined(separator: ", ")
                        
                        // Update the element's available actions - sometimes this might have been missed during initialization
                        if element.availableActions.isEmpty {
                            element.availableActions = actionNames
                        }
                    }
                }
            }
            
            // Get and display all supported user actions
            if let self = self {
                let supportedActions = self.actionsForElement(element).map { $0.0 }
                if !supportedActions.isEmpty {
                    properties["Supported User Actions"] = supportedActions.joined(separator: ", ")
                }
            }
            
            DispatchQueue.main.async {
                self?.properties = properties
            }
        }
    }
    
    func loadChildren(for element: UIElement, completion: @escaping () -> Void) {
        // Reset children
        element.children = []
        
        // Get element children directly from the accessibility API
        if let axElement = element.axElement {
            // Mark as loading
            element.isLoading = true
            
            // Use a timeout for safety
            let timeoutQueue = DispatchQueue(label: "com.timeout.queue")
            var hasCompleted = false
            
            // Set a timeout
            timeoutQueue.asyncAfter(deadline: .now() + 0.5) {
                if !hasCompleted {
                    hasCompleted = true
                    print("Timeout loading children")
                    DispatchQueue.main.async {
                        element.isLoading = false
                        completion()
                    }
                }
            }
            
            // Try to get children
            DispatchQueue.global(qos: .userInitiated).async {
                var childrenRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(axElement, kAXChildrenAttribute as CFString, &childrenRef)
                
                if result == .success, let childrenArray = childrenRef as? [AXUIElement] {
                    // Process children with smart hierarchy optimization
                    self.processChildren(childrenArray, parentElement: element) { processedChildren in
                        DispatchQueue.main.async {
                            element.children = processedChildren
                            element.isLoading = false
                            
                            if !hasCompleted {
                                hasCompleted = true
                                completion()
                            }
                        }
                    }
                } else {
                    if !hasCompleted {
                        hasCompleted = true
                        DispatchQueue.main.async {
                            element.isLoading = false
                            completion()
                        }
                    }
                }
            }
        } else {
            // No AX element available
            completion()
        }
    }
    
    /// Process children with smart hierarchy optimization
    private func processChildren(_ axChildren: [AXUIElement], parentElement: UIElement, completion: @escaping ([UIElement]) -> Void) {
        // Create a processing queue to handle the children
        let processingQueue = DispatchQueue(label: "com.accessibility.processQueue", qos: .userInitiated)
        
        processingQueue.async {
            var processedChildren: [UIElement] = []
            let processingGroup = DispatchGroup()
            let childrenQueue = DispatchQueue(label: "com.accessibility.childrenQueue")
            
            // Only process a reasonable number to prevent freezing
            for axChild in axChildren.prefix(30) {
                // Process each child on the queue
                processingGroup.enter()
                
                // Create child element with optimization
                if let childElement = self.createAndOptimizeElement(
                    axElement: axChild,
                    parent: parentElement
                ) {
                    // Apply optimization to handle AXGroup elements
                    if childElement.role == "AXGroup" || childElement.role == "Group" {
                        // For groups, check if they're empty or have only one child
                        self.processGroupElement(childElement) { result in
                            if let optimizedElement = result {
                                childrenQueue.async {
                                    processedChildren.append(optimizedElement)
                                    processingGroup.leave()
                                }
                            } else {
                                processingGroup.leave()
                            }
                        }
                    } else {
                        // For non-group elements, just add to the list
                        childrenQueue.async {
                            processedChildren.append(childElement)
                            processingGroup.leave()
                        }
                    }
                } else {
                    // No element created
                    processingGroup.leave()
                }
            }
            
            // After all children are processed
            processingGroup.notify(queue: processingQueue) {
                // Get remaining children without optimization to ensure we don't miss any types
                let nonGroupChildren = axChildren.prefix(30).compactMap { axChild -> UIElement? in
                    var roleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(axChild, kAXRoleAttribute as CFString, &roleRef)
                    let role = (roleRef as? String) ?? "Unknown"
                    
                    // Create elements for important roles that might have been missed in optimization
                    let importantRoles = ["Menu", "MenuItem", "MenuBar", "MenuBarItem"]
                    if importantRoles.contains(role) {
                        return self.createAndOptimizeElement(axElement: axChild, parent: parentElement)
                    }
                    return nil
                }
                
                // Add any important elements that may have been missed
                processedChildren.append(contentsOf: nonGroupChildren)
                
                // Sort by role to group similar elements together
                let sortedChildren = processedChildren.sorted { 
                    // Prioritize important UI elements
                    if $0.role == "MenuBar" && $1.role != "MenuBar" { return true }
                    if $0.role == "Menu" && $1.role != "Menu" && $1.role != "MenuBar" { return true }
                    
                    // Otherwise sort alphabetically by role
                    return $0.role < $1.role
                }
                
                completion(sortedChildren)
            }
        }
    }
    
    /// Create an element with basic attribute loading
    private func createAndOptimizeElement(axElement: AXUIElement, parent: UIElement) -> UIElement? {
        // Get role
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? "Unknown"
        
        // Only optimize AXGroup elements - leave all other elements alone
        // Note: Make sure we only elide truly empty groups with no useful information
        if (role == "AXGroup" || role == "Group") {
            // Check if the group has any children
            var hasChildren = false
            var childrenRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let childArray = childrenRef as? [AXUIElement], !childArray.isEmpty {
                hasChildren = true
            }
            
            // Check if the group has any useful attributes
            var hasUsefulAttributes = false
            
            // Check for identifier
            var identifierRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXIdentifierAttribute as CFString, &identifierRef) == .success,
               let identifier = identifierRef as? String, !identifier.isEmpty {
                hasUsefulAttributes = true
            }
            
            // Check for title/name
            var titleRef: CFTypeRef?
            if !hasUsefulAttributes && 
               AXUIElementCopyAttributeValue(axElement, kAXTitleAttribute as CFString, &titleRef) == .success,
               let title = titleRef as? String, !title.isEmpty {
                hasUsefulAttributes = true
            }
            
            // Check for description
            var descRef: CFTypeRef?
            if !hasUsefulAttributes && 
               AXUIElementCopyAttributeValue(axElement, kAXDescriptionAttribute as CFString, &descRef) == .success,
               let desc = descRef as? String, !desc.isEmpty {
                hasUsefulAttributes = true
            }
            
            // Skip only truly empty groups with no children and no useful attributes
            if !hasChildren && !hasUsefulAttributes {
                return nil
            }
        }
        
        // Get name/title
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axElement, kAXTitleAttribute as CFString, &titleRef)
        var name = (titleRef as? String) ?? ""
        
        // Try description if title is empty
        if name.isEmpty {
            var descRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axElement, kAXDescriptionAttribute as CFString, &descRef)
            if let desc = descRef as? String, !desc.isEmpty {
                name = desc
            }
        }
        
        // If still empty, try value for text elements
        if name.isEmpty {
            var valueRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef) == .success,
               let value = valueRef as? String, !value.isEmpty {
                name = value
            }
        }
        
        // If still empty, use role as fallback
        if name.isEmpty {
            name = role
        }
        
        // Create element with basic info
        let element = UIElement(
            name: name,
            role: role,
            appInfo: parent.appInfo,
            description: "\(role) element",
            parent: parent,
            axElement: axElement
        )
        
        // Load additional properties for enhanced visualization
        loadAdditionalProperties(for: element)
        
        return element
    }
    
    /// Load additional properties for an element
    private func loadAdditionalProperties(for element: UIElement) {
        guard let axElement = element.axElement else { return }
        
        // Load value for form elements
        if element.role == "TextField" || element.role == "TextArea" || element.role == "StaticText" ||
           element.role == "CheckBox" || element.role == "RadioButton" {
            var valueRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef) == .success {
                if let stringValue = valueRef as? String {
                    element.value = stringValue
                } else if let boolValue = valueRef as? Bool {
                    element.value = boolValue ? "checked" : "unchecked"
                } else if let numberValue = valueRef as? NSNumber {
                    element.value = numberValue.stringValue
                }
            }
        }
        
        // Load help text
        var helpRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXHelpAttribute as CFString, &helpRef) == .success,
           let helpText = helpRef as? String {
            element.help = helpText
        }
        
        // Load placeholder value
        var placeholderRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXPlaceholderValueAttribute as CFString, &placeholderRef) == .success,
           let placeholder = placeholderRef as? String {
            element.placeholderValue = placeholder
        }
        
        // Load enabled state
        var enabledRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXEnabledAttribute as CFString, &enabledRef) == .success,
           let enabled = enabledRef as? Bool {
            element.enabled = enabled
        }
        
        // Load other states
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXFocusedAttribute as CFString, &focusedRef) == .success,
           let focused = focusedRef as? Bool {
            element.focused = focused
        }
        
        var selectedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXSelectedAttribute as CFString, &selectedRef) == .success,
           let selected = selectedRef as? Bool {
            element.selected = selected
        }
    }
    
    /// Process an AXGroup element with hierarchy optimization
    private func processGroupElement(_ groupElement: UIElement, completion: @escaping (UIElement?) -> Void) {
        guard let axElement = groupElement.axElement else {
            completion(groupElement)
            return
        }
        
        // Check if the group has children
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axElement, kAXChildrenAttribute as CFString, &childrenRef)
        
        if result == .success, let childrenArray = childrenRef as? [AXUIElement] {
            if childrenArray.isEmpty {
                // Empty group with no children - skip only if truly useless
                if groupElement.identifier.isEmpty && groupElement.name.isEmpty && groupElement.help.isEmpty {
                    completion(nil)
                } else {
                    completion(groupElement)
                }
            } else if childrenArray.count == 1 {
                // Group with single child - optimize by lifting the child
                let singleAXChild = childrenArray[0]
                
                // Get role of child to make sure we don't flatten important containers
                var childRoleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(singleAXChild, kAXRoleAttribute as CFString, &childRoleRef)
                let childRole = (childRoleRef as? String) ?? "Unknown"
                
                // Don't optimize if the child is an important UI element that should stay nested
                // This prevents flattening key menu structures and other important hierarchies
                let importantRoles = ["MenuBar", "Menu", "MenuItem", "TabGroup", "Table", "List", "Outline"]
                if importantRoles.contains(childRole) {
                    // Load children the regular way for important elements
                    loadRegularChildren(for: groupElement, from: childrenArray) { success in
                        completion(groupElement)
                    }
                    return
                }
                
                // Create the child element
                if let childElement = createAndOptimizeElement(
                    axElement: singleAXChild,
                    parent: groupElement.parent ?? groupElement) {
                    
                    // Preserve group's attributes on the child if they're not already set
                    if !groupElement.identifier.isEmpty && childElement.identifier.isEmpty {
                        childElement.identifier = groupElement.identifier
                    }
                    
                    if !groupElement.name.isEmpty && childElement.name.isEmpty {
                        childElement.name = groupElement.name
                    }
                    
                    if !groupElement.help.isEmpty && childElement.help.isEmpty {
                        childElement.help = groupElement.help
                    }
                    
                    // Set the proper parent
                    childElement.parent = groupElement.parent
                    
                    // Return the optimized child instead of the group
                    completion(childElement)
                } else {
                    // If child creation failed, use the original group
                    completion(groupElement)
                }
            } else {
                // Group with multiple children - keep as is
                // Load the children for this group
                loadRegularChildren(for: groupElement, from: childrenArray) { success in
                    completion(groupElement)
                }
            }
        } else {
            // Couldn't get children - keep as is
            completion(groupElement)
        }
    }
    
    /// Load children without hierarchy optimization
    private func loadRegularChildren(for element: UIElement, from axChildren: [AXUIElement], completion: @escaping (Bool) -> Void) {
        // Process a reasonable number of children
        let childrenToProcess = axChildren.prefix(20)
        var newChildren: [UIElement] = []
        
        for axChild in childrenToProcess {
            if let childElement = createAndOptimizeElement(
                axElement: axChild,
                parent: element
            ) {
                element.addChild(childElement)
                newChildren.append(childElement)
            }
        }
        
        completion(!newChildren.isEmpty)
    }
    
    func checkAccess() -> Bool {
        // Check if accessibility is authorized
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
    }
    
    /// Get a list of supported actions for the given element
    func getSupportedActions(for element: UIElement) -> [String] {
        guard let axElement = element.axElement else {
            return []
        }
        
        var actionsArrayRef: CFArray?
        let result = AXUIElementCopyActionNames(axElement, &actionsArrayRef)
        
        if result == .success, let actionNames = actionsArrayRef as? [String] {
            return actionNames
        }
        
        return []
    }
}

@main
struct BasicExplorerApp: App {
    @StateObject private var viewModel = ExplorerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 1000, minHeight: 700)
        }
    }
}

/// Main content view
struct ContentView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    viewModel.loadApplications()
                }) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                // Safe Mode toggle removed - now always using real API with interaction
                Text("Interactive Mode")
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.1))
                    )
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Main content
            HSplitView {
                // Apps sidebar
                ApplicationsSidebar()
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                
                // Element tree and details 
                if viewModel.selectedApp != nil {
                    HSplitView {
                        // Element tree
                        ElementTreeView()
                            .frame(minWidth: 300)
                        
                        // Element details
                        ElementDetailsView()
                            .frame(minWidth: 350)
                    }
                } else {
                    // No app selected
                    VStack {
                        Spacer()
                        Text("Select an application")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // Status bar
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .padding(.trailing, 4)
                    Text("Loading...")
                        .font(.caption)
                } else {
                    Image(systemName: "hand.tap")
                        .foregroundColor(.green)
                    
                    Text("Accessibility Explorer (With Interaction)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if let app = viewModel.selectedApp {
                    Text("\(app.name) (PID: \(app.pid))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .frame(height: 24)
            .background(Color(.controlBackgroundColor))
        }
    }
}

/// Sidebar showing applications
struct ApplicationsSidebar: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Applications")
                .font(.headline)
                .padding()
            
            if viewModel.isLoading && viewModel.applications.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading applications...")
                        .font(.caption)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.applications) { app in
                        ApplicationRow(app: app)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectApplication(app)
                            }
                            .background(viewModel.selectedApp?.id == app.id ? Color.blue.opacity(0.1) : Color.clear)
                    }
                }
                .listStyle(SidebarListStyle())
            }
        }
    }
}

/// Application row in sidebar
struct ApplicationRow: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        HStack {
            Image(systemName: iconForApp(app))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading) {
                Text(app.name)
                    .fontWeight(viewModel.selectedApp?.id == app.id ? .bold : .regular)
                
                Text("PID: \(app.pid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.selectedApp?.id == app.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForApp(_ app: AppInfo) -> String {
        switch app.name {
        case "Safari": return "safari"
        case "TextEdit": return "doc.text"
        case "Finder": return "folder"
        case "Mail": return "envelope"
        case "Photos": return "photo"
        case "Calendar": return "calendar"
        default: return "app.badge"
        }
    }
}

/// Tree view of UI elements
struct ElementTreeView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Element Tree")
                .font(.headline)
                .padding()
            
            if viewModel.isLoading && viewModel.rootElement == nil {
                VStack {
                    ProgressView()
                    Text("Loading elements...")
                        .font(.caption)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let rootElement = viewModel.rootElement {
                ScrollView {
                    VStack(alignment: .leading) {
                        ElementNodeView(element: rootElement)
                            .padding(.horizontal)
                    }
                }
            } else {
                Text("No elements to display")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// A node in the element tree
struct ElementNodeView: View {
    @ObservedObject var element: UIElement
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                // Select this element
                viewModel.selectElement(element)
                
                // Toggle expanded state
                if element.isExpanded {
                    viewModel.collapseElement(element)
                } else {
                    viewModel.expandElement(element)
                }
            }) {
                HStack {
                    // Expand/collapse indicator
                    if !element.children.isEmpty || element.isLoading {
                        Image(systemName: element.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Visualized element representation
                    elementVisualization
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 2)
            
            // Loading indicator
            if element.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Loading...")
                        .font(.caption)
                }
                .padding(.leading, 20)
            }
            
            // Children
            if element.isExpanded {
                ForEach(element.children) { child in
                    ElementNodeView(element: child)
                        .padding(.leading, 20)
                }
            }
        }
    }
    
    /// Element visualization based on its role
    @ViewBuilder
    private var elementVisualization: some View {
        switch element.role {
        case "Button":
            buttonVisualization
        case "TextField", "SearchField":
            textFieldVisualization
        case "CheckBox", "CheckBoxButton":
            checkboxVisualization
        case "RadioButton":
            radioButtonVisualization
        case "Menu", "MenuItem", "MenuBar":
            menuVisualization
        case "TabGroup":
            tabGroupVisualization
        case "ScrollArea":
            scrollAreaVisualization
        case "Slider", "ValueIndicator":
            sliderVisualization
        case "StaticText", "Text":
            textVisualization
        case "Image":
            imageVisualization
        case "Window":
            windowVisualization
        case "Table":
            tableVisualization
        default:
            defaultVisualization
        }
    }
    
    /// Button visualization
    private var buttonVisualization: some View {
        HStack {
            // Button icon with state indicators
            ZStack {
                Image(systemName: "button.programmable")
                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                    .frame(width: 16, height: 16)
                
                // Show focused indicator
                if element.focused {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            // Compact button rendering
            RoundedRectangle(cornerRadius: 4)
                .fill(element.isSelected ? Color.blue.opacity(0.3) : 
                     (element.enabled ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05)))
                .overlay(
                    VStack(alignment: .leading, spacing: 1) {
                        // Primary information: Name first, then ID if available
                        VStack(alignment: .leading, spacing: 1) {
                            if !element.name.isEmpty {
                                Text(element.name)
                                    .font(.system(size: 12))
                                    .fontWeight(element.isSelected ? .semibold : .medium)
                                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                
                                // Show ID as secondary if different from name
                                if !element.identifier.isEmpty && element.identifier != element.name {
                                    Text("id: \(element.identifier)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .padding(.horizontal, 4)
                                }
                            } else if !element.identifier.isEmpty {
                                // Use ID if no name
                                Text("id: \(element.identifier)")
                                    .font(.system(size: 12))
                                    .fontWeight(element.isSelected ? .semibold : .medium)
                                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                            } else {
                                // Fall back to generic label
                                Text("(Unnamed Button)")
                                    .font(.system(size: 12))
                                    .fontWeight(element.isSelected ? .semibold : .regular)
                                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                    .italic()
                            }
                        }
                    }
                )
                .frame(height: element.identifier.isEmpty ? 20 : 30)
                .frame(minWidth: 60, maxWidth: 150)
            
            // Status indicators and info
            VStack(alignment: .leading, spacing: 2) {
                // Role with subrole if available
                Text(element.subrole.isEmpty ? "Button" : "Button (\(element.subrole))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // State indicators
                HStack(spacing: 4) {
                    if !element.enabled {
                        Text("Disabled")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.focused {
                        Text("Focused")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if !element.availableActions.isEmpty {
                        Text("\(element.availableActions.count) actions")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
            }
        }
    }
    
    /// Text field visualization
    private var textFieldVisualization: some View {
        HStack {
            // Text field icon with state indicators
            ZStack {
                Image(systemName: "text.cursor")
                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                    .frame(width: 16, height: 16)
                
                // Show focused indicator
                if element.focused {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            // Text field mock
            VStack(alignment: .leading, spacing: 1) {
                // Primary information: name/title first, then ID
                if !element.name.isEmpty {
                    // Show name/title as primary information
                    Text(element.name)
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .medium)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                    
                    // Show ID as secondary if different from name
                    if !element.identifier.isEmpty && element.identifier != element.name {
                        Text("id: \(element.identifier)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else if !element.identifier.isEmpty {
                    // Show ID if no name is available
                    Text("id: \(element.identifier)")
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .medium)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                }
                
                // Display field content or placeholder
                RoundedRectangle(cornerRadius: 4)
                    .stroke(element.isSelected ? Color.blue : element.enabled ? Color.gray : Color.gray.opacity(0.5), lineWidth: 1)
                    .background(element.enabled ? Color.white.opacity(0.5) : Color.gray.opacity(0.1))
                    .frame(height: 22)
                    .frame(minWidth: 80, maxWidth: 180)
                    .overlay(
                        HStack {
                            if !element.value.isEmpty {
                                // Show actual value
                                Text(element.value)
                                    .font(.system(size: 11))
                                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .black : .gray)
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                            } else if !element.placeholderValue.isEmpty {
                                // Show placeholder text
                                Text(element.placeholderValue)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                                    .italic()
                            } else if element.identifier.isEmpty {
                                // Only show name here if no ID was shown above
                                Text(element.name.isEmpty ? "(Unnamed Field)" : element.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(element.isSelected ? .blue : .gray)
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                            } else if !element.name.isEmpty && element.name != element.identifier {
                                // Show name as secondary info if different from ID
                                Text(element.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                            } else {
                                // Show a placeholder
                                Text("(Empty)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                                    .italic()
                            }
                            Spacer()
                        }
                    )
            }
            
            // Role and state info
            VStack(alignment: .leading, spacing: 2) {
                // Show role with more specific info
                Text(element.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // State indicators
                HStack(spacing: 4) {
                    if !element.enabled {
                        Text("Disabled")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.focused {
                        Text("Focused")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.value.count > 0 {
                        Text("Has Text")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
            }
        }
    }
    
    /// Checkbox visualization
    private var checkboxVisualization: some View {
        HStack {
            // Checkbox icon with state information
            ZStack {
                // Show actual checkbox state (checked/unchecked)
                Image(systemName: element.value.contains("checked") || element.value == "1" || element.value == "true" ? 
                      "checkmark.square.fill" : "square")
                    .foregroundColor(element.isSelected ? .blue : 
                                     element.enabled ? (element.value.contains("checked") || element.value == "1" || element.value == "true" ? .blue : .primary) : .gray)
                    .frame(width: 16, height: 16)
                
                // Show focused indicator
                if element.focused {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                // Primary information: Name first, then ID
                if !element.name.isEmpty {
                    Text(element.name)
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .medium)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                    
                    // Show ID as secondary if different from name
                    if !element.identifier.isEmpty && element.identifier != element.name {
                        Text("id: \(element.identifier)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else if !element.identifier.isEmpty {
                    // Use ID if no name
                    Text("id: \(element.identifier)")
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .medium)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                } else {
                    // Fall back to generic label
                    Text("(Unnamed Checkbox)")
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .regular)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                        .italic()
                }
            }
            
            // State information
            VStack(alignment: .leading, spacing: 2) {
                // Role with state
                HStack {
                    Text("Checkbox")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if element.value.contains("checked") || element.value == "1" || element.value == "true" {
                        Text("✓")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
                
                // State indicators
                HStack(spacing: 4) {
                    if !element.enabled {
                        Text("Disabled")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.focused {
                        Text("Focused")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.value.contains("checked") || element.value == "1" || element.value == "true" {
                        Text("Checked")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
            }
        }
    }
    
    /// Radio button visualization
    private var radioButtonVisualization: some View {
        HStack {
            // Radio button icon
            Image(systemName: "circle")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Radio button label
            Text(element.name)
                .font(.system(size: 12))
                .fontWeight(element.isSelected ? .semibold : .regular)
                .foregroundColor(element.isSelected ? .blue : .primary)
                .lineLimit(1)
            
            // Role caption
            Text("Radio")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Menu visualization
    private var menuVisualization: some View {
        HStack {
            // Menu icon
            Image(systemName: "menubar.arrow.down")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Menu rendering
            Text(element.name)
                .font(.system(size: 12, weight: .medium))
                .fontWeight(element.isSelected ? .semibold : .regular)
                .foregroundColor(element.isSelected ? .blue : .primary)
                .lineLimit(1)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(element.isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(3)
            
            // Role caption
            Text(element.role)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Tab group visualization
    private var tabGroupVisualization: some View {
        HStack {
            // Tab icon
            Image(systemName: "rectangle.stack")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Tab visualization
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 1) {
                    Text(element.name)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(element.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(3)
                    
                    if element.children.count > 1 {
                        Text("+\(element.children.count - 1)")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .foregroundColor(.secondary)
                    }
                }
                Rectangle()
                    .fill(element.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(height: 4)
                    .cornerRadius(1)
            }
            
            // Role caption
            Text("Tabs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Scroll area visualization
    private var scrollAreaVisualization: some View {
        HStack {
            // Scroll icon
            Image(systemName: "scroll")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Scroll area visualization 
            VStack(alignment: .leading, spacing: 0) {
                Text(element.name)
                    .font(.system(size: 12))
                    .fontWeight(element.isSelected ? .semibold : .regular)
                    .foregroundColor(element.isSelected ? .blue : .primary)
                    .lineLimit(1)
                
                Rectangle()
                    .fill(element.isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 20)
                    .overlay(
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 4, height: 16)
                                .cornerRadius(2)
                                .padding(.trailing, 2)
                        }
                    )
                    .cornerRadius(3)
            }
            
            // Role caption
            Text("ScrollArea")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Slider visualization
    private var sliderVisualization: some View {
        HStack {
            // Slider icon
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Slider visualization
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 4)
                .overlay(
                    Circle()
                        .fill(element.isSelected ? Color.blue : Color.gray)
                        .frame(width: 10, height: 10)
                        .offset(x: 20, y: 0)
                )
                .cornerRadius(2)
            
            // Name and role
            VStack(alignment: .leading, spacing: 0) {
                Text(element.name)
                    .font(.system(size: 12))
                    .fontWeight(element.isSelected ? .semibold : .regular)
                    .foregroundColor(element.isSelected ? .blue : .primary)
                
                Text("Slider")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Text visualization
    private var textVisualization: some View {
        HStack {
            // Text icon
            Image(systemName: "text.quote")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Text visualization
            Text(element.name.isEmpty ? "Text" : element.name)
                .font(.system(size: 12))
                .fontWeight(element.isSelected ? .semibold : .regular)
                .foregroundColor(element.isSelected ? .blue : .primary)
                .lineLimit(1)
            
            // Role caption
            Text("Text")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Image visualization
    private var imageVisualization: some View {
        HStack {
            // Image icon
            Image(systemName: "photo")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Image placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(element.isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundColor(element.isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.5))
                )
            
            // Name and role
            VStack(alignment: .leading, spacing: 0) {
                Text(element.name)
                    .font(.system(size: 12))
                    .fontWeight(element.isSelected ? .semibold : .regular)
                    .foregroundColor(element.isSelected ? .blue : .primary)
                
                Text("Image")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Window visualization
    private var windowVisualization: some View {
        HStack {
            // Window icon
            Image(systemName: "macwindow")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Window visualization
            VStack(alignment: .leading, spacing: 2) {
                // Window header
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(Color.yellow.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 6, height: 6)
                    
                    Text(element.name)
                        .font(.system(size: 10))
                        .fontWeight(element.isSelected ? .semibold : .regular)
                        .foregroundColor(element.isSelected ? .blue : .primary)
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                }
                
                // Window content
                Rectangle()
                    .fill(element.isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .frame(width: 100, height: 16)
                    .cornerRadius(2)
            }
            .padding(2)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            
            // Role caption
            Text("Window")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Table visualization
    private var tableVisualization: some View {
        HStack {
            // Table icon
            Image(systemName: "tablecells")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Table visualization
            VStack(spacing: 1) {
                // Header row
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(element.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 30, height: 8)
                    Rectangle()
                        .fill(element.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 30, height: 8)
                }
                
                // Data rows
                ForEach(0..<2) { _ in
                    HStack(spacing: 1) {
                        Rectangle()
                            .fill(element.isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .frame(width: 30, height: 5)
                        Rectangle()
                            .fill(element.isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .frame(width: 30, height: 5)
                    }
                }
            }
            .cornerRadius(2)
            
            // Name and role
            VStack(alignment: .leading, spacing: 0) {
                Text(element.name)
                    .font(.system(size: 12))
                    .fontWeight(element.isSelected ? .semibold : .regular)
                    .foregroundColor(element.isSelected ? .blue : .primary)
                
                Text("Table")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Default visualization for other element types
    private var defaultVisualization: some View {
        HStack {
            // Element icon with state indicators
            ZStack {
                Image(systemName: iconForRole(element.role))
                    .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                    .frame(width: 16, height: 16)
                
                // Show focused indicator
                if element.focused {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            // Element details
            VStack(alignment: .leading, spacing: 1) {
                // Primary information: Name first, then identifier
                if !element.name.isEmpty {
                    Text(element.name)
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .bold : .medium)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                    
                    // Show id as secondary if it exists and is different from name
                    if !element.identifier.isEmpty && element.identifier != element.name {
                        Text("id: \(element.identifier)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else if !element.identifier.isEmpty {
                    // Use identifier if no name
                    Text("id: \(element.identifier)")
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .bold : .regular)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                } else {
                    // Fall back to role if no name or id
                    Text("(\(element.role))")
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .bold : .regular)
                        .foregroundColor(element.isSelected ? .blue : element.enabled ? .primary : .gray)
                        .lineLimit(1)
                }
                
                // Show value if available
                if !element.value.isEmpty && element.value != "false" && element.value != "true" {
                    Text("Value: \(element.value)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Show help text if available
                if !element.help.isEmpty {
                    Text(element.help)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .italic()
                }
            }
            
            // State and role information
            VStack(alignment: .leading, spacing: 2) {
                // Role with subrole if available
                Text(element.subrole.isEmpty ? element.role : "\(element.role) (\(element.subrole))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // State indicators and available actions
                HStack(spacing: 4) {
                    if !element.enabled {
                        Text("Disabled")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.focused {
                        Text("Focused")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if element.selected {
                        Text("Selected")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if !element.availableActions.isEmpty {
                        Text("\(element.availableActions.count) actions")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
                
                // Position indicator if available
                if let position = element.position {
                    Text("[\(Int(position.x)),\(Int(position.y))]")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable"
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "MenuBar", "Menu", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        case "Slider": return "slider.horizontal.3"
        case "CheckBox": return "checkmark.square"
        case "RadioButton": return "circle"
        case "Image": return "photo"
        case "TabGroup": return "rectangle.stack"
        default: return "circle"
        }
    }
}

/// Properties display view
struct ElementDetailsView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Element header
            if let element = viewModel.selectedElement {
                ElementHeader(element: element)
            }
            
            // Tab selection
            HStack {
                ForEach(0..<3) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        Text(tabTitle(for: index))
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Properties content
            if viewModel.properties.isEmpty {
                Text("No properties available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        switch selectedTab {
                        case 0: // Basic properties
                            PropertiesView(properties: basicProperties())
                        case 1: // All properties
                            PropertiesView(properties: allProperties())
                        case 2: // Actions
                            ActionsView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            
            // Safe mode indicator
            HStack {
                Image(systemName: viewModel.useMockData ? "exclamationmark.shield" : "info.circle")
                    .foregroundColor(viewModel.useMockData ? .orange : .blue)
                
                if viewModel.useMockData {
                    Text("Safe Mode - Using simulated data only.")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Using real accessibility API data with safety limits.")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(8)
            .background(viewModel.useMockData ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Basic"
        case 1: return "All Properties"
        case 2: return "Actions"
        default: return ""
        }
    }
    
    private func basicProperties() -> [(key: String, value: String)] {
        let basicKeys = ["Name", "Role", "Description", "Position", "Size", "Enabled"]
        return viewModel.properties.filter { basicKeys.contains($0.key) }
                                   .sorted { $0.key < $1.key }
                                   .map { ($0.key, $0.value) }
    }
    
    private func allProperties() -> [(key: String, value: String)] {
        return viewModel.properties.sorted { $0.key < $1.key }
                                   .map { ($0.key, $0.value) }
    }
}

/// Element header
struct ElementHeader: View {
    let element: UIElement
    
    var body: some View {
        HStack(spacing: 16) {
            // Element icon
            Image(systemName: iconForRole(element.role))
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Element info
            VStack(alignment: .leading, spacing: 4) {
                Text(element.name)
                    .font(.headline)
                
                Text(element.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Show path (breadcrumbs)
                if element.parent != nil {
                    Text("\(breadcrumbPath(for: element))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
    
    private func breadcrumbPath(for element: UIElement) -> String {
        var path = ""
        
        var current: UIElement? = element
        while let c = current {
            path = c.name + (path.isEmpty ? "" : " → " + path)
            current = c.parent
        }
        
        return path
    }
    
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable"
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "MenuBar", "Menu", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        default: return "circle"
        }
    }
}

/// Properties view
struct PropertiesView: View {
    let properties: [(key: String, value: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(properties, id: \.key) { property in
                HStack(alignment: .top) {
                    Text(property.key)
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    Text(property.value)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                
                Divider()
            }
        }
    }
}

/// Actions view
struct ActionsView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    @State private var isPerformingAction = false
    @State private var actionResult: (success: Bool, message: String?) = (false, nil)
    @State private var showingActionResult = false
    @State private var showingTextInput = false
    @State private var textInputValue = ""
    @State private var showingValueEditor = false
    @State private var valueEditorValue = ""
    @State private var showingPositionEditor = false
    @State private var positionX: String = "0"
    @State private var positionY: String = "0"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Actions")
                .font(.headline)
            
            if showingActionResult {
                actionResultView
            }
            
            if let element = viewModel.selectedElement {
                ForEach(actionsForElement(element), id: \.0) { action in
                    HStack {
                        Image(systemName: iconForAction(action.0))
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading) {
                            Text(action.0)
                                .font(.body)
                            
                            Text(action.1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isPerformingAction {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button("Perform") {
                                performAction(action.0, on: element)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                }
                
                Text("Note: Actions will affect the actual application UI.")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top)
            } else {
                Text("No element selected")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingTextInput) {
            textInputSheet
        }
        .sheet(isPresented: $showingValueEditor) {
            valueEditorSheet
        }
        .sheet(isPresented: $showingPositionEditor) {
            positionEditorSheet
        }
    }
    
    // Action result status view
    private var actionResultView: some View {
        HStack {
            Image(systemName: actionResult.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(actionResult.success ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(actionResult.success ? "Action Successful" : "Action Failed")
                    .fontWeight(.semibold)
                
                if let message = actionResult.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                showingActionResult = false
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(actionResult.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    // Text input sheet for enter text action
    private var textInputSheet: some View {
        VStack(spacing: 20) {
            Text("Enter Text")
                .font(.headline)
            
            TextField("Text to insert", text: $textInputValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    showingTextInput = false
                    textInputValue = ""
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Insert") {
                    guard let element = viewModel.selectedElement else { return }
                    
                    showingTextInput = false
                    isPerformingAction = true
                    
                    performTextEntryAction(on: element, text: textInputValue) { success, message in
                        DispatchQueue.main.async {
                            isPerformingAction = false
                            actionResult = (success, message ?? "Text entered successfully")
                            showingActionResult = true
                            
                            // Refresh properties after action
                            if success {
                                viewModel.loadProperties(for: element)
                            }
                        }
                    }
                    
                    textInputValue = ""
                }
                .keyboardShortcut(.return)
                .disabled(textInputValue.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 200)
        .padding()
    }
    
    // Value editor sheet for sliders, steppers, etc.
    private var valueEditorSheet: some View {
        VStack(spacing: 20) {
            Text("Set Value")
                .font(.headline)
            
            TextField("Value", text: $valueEditorValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    showingValueEditor = false
                    valueEditorValue = ""
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Set") {
                    guard let element = viewModel.selectedElement else { return }
                    
                    showingValueEditor = false
                    isPerformingAction = true
                    
                    performSetValueAction(on: element, value: valueEditorValue) { success, message in
                        DispatchQueue.main.async {
                            isPerformingAction = false
                            actionResult = (success, message ?? "Value set successfully")
                            showingActionResult = true
                            
                            // Refresh properties after action
                            if success {
                                viewModel.loadProperties(for: element)
                            }
                        }
                    }
                    
                    valueEditorValue = ""
                }
                .keyboardShortcut(.return)
                .disabled(valueEditorValue.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 200)
        .padding()
    }
    
    // Position editor sheet for moving/positioning elements
    private var positionEditorSheet: some View {
        VStack(spacing: 20) {
            Text("Set Position")
                .font(.headline)
            
            HStack {
                Text("X:")
                    .frame(width: 20)
                TextField("X Position", text: $positionX)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            HStack {
                Text("Y:")
                    .frame(width: 20)
                TextField("Y Position", text: $positionY)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    showingPositionEditor = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Set Position") {
                    guard let element = viewModel.selectedElement,
                          let x = Int(positionX),
                          let y = Int(positionY) else { return }
                    
                    showingPositionEditor = false
                    isPerformingAction = true
                    
                    performSetPositionAction(on: element, x: x, y: y) { success, message in
                        DispatchQueue.main.async {
                            isPerformingAction = false
                            actionResult = (success, message ?? "Position set successfully")
                            showingActionResult = true
                            
                            // Refresh properties after action
                            if success {
                                viewModel.loadProperties(for: element)
                            }
                        }
                    }
                }
                .keyboardShortcut(.return)
                .disabled(positionX.isEmpty || positionY.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 250)
        .padding()
    }
    
    // Perform the selected action
    private func performAction(_ action: String, on element: UIElement) {
        isPerformingAction = true
        
        // Handle special cases that require custom UI or special handling
        switch action {
        case "Enter Text":
            isPerformingAction = false
            showingTextInput = true
            return
            
        case "Set Value":
            isPerformingAction = false
            
            // Initialize the value editor with the current value if available
            if let axElement = element.axElement {
                var valueRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef) == .success {
                    if let stringValue = valueRef as? String {
                        valueEditorValue = stringValue
                    } else if let numberValue = valueRef as? NSNumber {
                        valueEditorValue = numberValue.stringValue
                    }
                }
            }
            
            showingValueEditor = true
            return
            
        case "Set Position":
            isPerformingAction = false
            
            // Initialize with current position if available
            if let axElement = element.axElement {
                var positionRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &positionRef) == .success,
                   let position = positionRef as? NSValue {
                    var point = NSPoint()
                    position.getValue(&point)
                    positionX = String(Int(point.x))
                    positionY = String(Int(point.y))
                }
            }
            
            showingPositionEditor = true
            return
            
        case "Inspect":
            isPerformingAction = false
            actionResult = (true, "Element properties displayed")
            showingActionResult = true
            return
            
        case "Focus":
            performFocusAction(on: element) { success, message in
                DispatchQueue.main.async {
                    isPerformingAction = false
                    actionResult = (success, message ?? "Element focused successfully")
                    showingActionResult = true
                    
                    // Refresh properties after action
                    if success {
                        viewModel.loadProperties(for: element)
                    }
                }
            }
            return
            
        case "Toggle":
            performToggleAction(on: element) { success, message in
                DispatchQueue.main.async {
                    isPerformingAction = false
                    actionResult = (success, message ?? "Checkbox toggled successfully")
                    showingActionResult = true
                    
                    // Refresh properties after action
                    if success {
                        viewModel.loadProperties(for: element)
                    }
                }
            }
            return
        
        case "Press":
            performPressAction(on: element) { success, message in
                DispatchQueue.main.async {
                    isPerformingAction = false
                    actionResult = (success, message ?? "Button pressed successfully")
                    showingActionResult = true
                    
                    // Refresh properties after action
                    if success {
                        viewModel.loadProperties(for: element)
                    }
                }
            }
            return
        }
        
        // For all other actions, determine the AX action name and use the generic handler
        var axActionName = ""
        
        // Map user-friendly action names to their AX equivalents
        switch action {
        case "Increment": axActionName = "AXIncrement"
        case "Decrement": axActionName = "AXDecrement"
        case "Minimize": axActionName = "AXMinimize"
        case "Close": axActionName = "AXClose"
        case "Raise": axActionName = "AXRaise"
        case "Show Menu": axActionName = "AXShowMenu"
        case "Pick": axActionName = "AXPick"
        case "Cancel": axActionName = "AXCancel"
        case "Confirm": axActionName = "AXConfirm"
        case "Show Alternate UI": axActionName = "AXShowAlternateUI"
        case "Show Default UI": axActionName = "AXShowDefaultUI"
        case "Zoom": axActionName = "AXZoomWindow"
        case "Scroll To Visible": axActionName = "AXScrollToVisible"
        case "Check": axActionName = "AXPress" // For checkboxes
        case "Uncheck": axActionName = "AXPress" // For checkboxes
        default:
            // For any other action, try to convert it to AX format if needed
            if !action.hasPrefix("AX") {
                // Remove spaces and make first letter uppercase for remaining chars
                let components = action.components(separatedBy: " ")
                if components.count > 1 {
                    // Convert "Show Menu" to "ShowMenu"
                    var formattedAction = components[0].lowercased()
                    for i in 1..<components.count {
                        formattedAction += components[i].prefix(1).uppercased() + components[i].dropFirst().lowercased()
                    }
                    axActionName = "AX" + formattedAction.prefix(1).uppercased() + formattedAction.dropFirst()
                } else {
                    // Just prefix with AX
                    axActionName = "AX" + action.prefix(1).uppercased() + action.dropFirst()
                }
            } else {
                // Already in AX format
                axActionName = action
            }
        }
        
        // Get a user-friendly success message
        let successMessage = "Action '\(action)' performed successfully"
        
        // Perform the action generically
        performGenericAction(on: element, action: axActionName) { success, message in
            DispatchQueue.main.async {
                isPerformingAction = false
                actionResult = (success, message ?? successMessage)
                showingActionResult = true
                
                // Refresh properties after action
                if success {
                    viewModel.loadProperties(for: element)
                }
            }
        }
    }
    
    private func actionsForElement(_ element: UIElement) -> [(String, String)] {
        var actions: [(String, String)] = []
        
        // First, get a list of all actions supported by the element
        // This ensures we don't miss any actions provided by the accessibility API
        if let axElement = element.axElement, !element.availableActions.isEmpty {
            // Add all available actions from the element
            for actionName in element.availableActions {
                // Map AX action names to user-friendly names and descriptions
                switch actionName {
                case "AXPress":
                    actions.append(("Press", "Activate this element"))
                case "AXShowMenu":
                    actions.append(("Show Menu", "Display context menu for this element"))
                case "AXPick":
                    actions.append(("Pick", "Select this item"))
                case "AXCancel":
                    actions.append(("Cancel", "Cancel current operation or dialog"))
                case "AXConfirm":
                    actions.append(("Confirm", "Confirm current operation or dialog"))
                case "AXDecrement":
                    actions.append(("Decrement", "Decrease value"))
                case "AXIncrement":
                    actions.append(("Increment", "Increase value"))
                case "AXRaise":
                    actions.append(("Raise", "Bring window to front"))
                case "AXShowAlternateUI":
                    actions.append(("Show Alternate UI", "Display alternate user interface"))
                case "AXShowDefaultUI":
                    actions.append(("Show Default UI", "Display default user interface"))
                case "AXMinimize":
                    actions.append(("Minimize", "Minimize this window"))
                case "AXZoomWindow":
                    actions.append(("Zoom", "Zoom this window"))
                case "AXClose":
                    actions.append(("Close", "Close this window or item"))
                default:
                    // For any other action not explicitly mapped, create a generic action name
                    let actionDisplayName = actionName.replacingOccurrences(of: "AX", with: "")
                    actions.append((actionDisplayName, "Perform \(actionDisplayName) action"))
                }
            }
        }
        
        // Next, add actions based on settable attributes
        if isAttributeSettable(kAXFocusedAttribute as String, on: element) {
            // Only add if not already added
            if !actions.contains(where: { $0.0 == "Focus" }) {
                actions.append(("Focus", "Set focus to this element"))
            }
        }
        
        if isAttributeSettable(kAXValueAttribute as String, on: element) {
            if !actions.contains(where: { $0.0 == "Set Value" }) {
                actions.append(("Set Value", "Change the value of this element"))
            }
            
            // For text fields, add text entry action
            if ["TextField", "SearchField", "TextArea"].contains(element.role) {
                if !actions.contains(where: { $0.0 == "Enter Text" }) {
                    actions.append(("Enter Text", "Insert text into this field"))
                }
            }
        }
        
        if isAttributeSettable(kAXPositionAttribute as String, on: element) {
            if !actions.contains(where: { $0.0 == "Set Position" }) {
                actions.append(("Set Position", "Move this element"))
            }
        }
        
        // Special actions for specific roles, if not already added through available actions
        switch element.role {
        case "CheckBox", "CheckBoxButton":
            if !actions.contains(where: { $0.0 == "Toggle" }) {
                actions.append(("Toggle", "Toggle checkbox state"))
            }
            
        case "TabGroup", "TabList", "Toolbar", "ScrollArea":
            // These are already handled by attributes or available actions
            break
            
        case "Application":
            // Applications get the inspect action if nothing else is available
            if actions.isEmpty {
                actions.append(("Inspect", "View detailed information about this application"))
            }
        default:
            break
        }
        
        // If we still have no actions, add a generic inspect action
        if actions.isEmpty {
            actions = [("Inspect", "View detailed information about this element")]
        }
        
        return actions
    }
    
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "Press": return "hand.tap"
        case "Focus": return "scope"
        case "Enter Text": return "text.cursor"
        case "Toggle": return "checkmark.square"
        case "Increment": return "plus.circle"
        case "Decrement": return "minus.circle"
        case "Set Value": return "slider.horizontal.3"
        case "Set Position": return "arrow.up.left.and.arrow.down.right"
        case "Minimize": return "arrow.down.right.square"
        case "Close": return "xmark.square"
        case "Raise": return "square.stack.3d.up"
        case "Show Menu": return "list.bullet"
        case "Inspect": return "magnifyingglass"
        case "Pick": return "hand.point.up.left"
        case "Cancel": return "xmark.circle"
        case "Confirm": return "checkmark.circle"
        case "Show Alternate UI": return "rectangle.3.offgrid"
        case "Show Default UI": return "rectangle.grid.1x2"
        case "Zoom": return "arrow.up.left.and.arrow.down.right.square"
        // Additional standard actions
        case "Scroll To Visible": return "arrow.up.and.down.and.arrow.left.and.right"
        case "Scroll To", "ScrollTo": return "arrow.up.and.down"
        case "Show Hover UI", "ShowHoverUI": return "rectangle.on.rectangle"
        case "Replace": return "arrow.2.squarepath"
        case "Check", "Uncheck": return "checkmark.square"
        case "PageLeft", "PageUp", "PageDown", "PageRight": return "arrow.left.and.right"
        // Generic fallbacks for other action types
        default:
            if action.contains("Page") {
                return "doc.text"
            } else if action.contains("Scroll") {
                return "arrow.up.and.down"
            } else if action.contains("Show") {
                return "eye"
            } else if action.contains("Select") {
                return "checkmark.circle"
            } else {
                return "arrow.right"
            }
        }
    }
    
    // MARK: - Accessibility Action Methods
    
    /// Safely check if an element supports a specific action
    private func isActionSupported(_ action: String, on element: UIElement) -> Bool {
        guard let axElement = element.axElement else {
            return false
        }
        
        var actionsArrayRef: CFArray?
        let result = AXUIElementCopyActionNames(axElement, &actionsArrayRef)
        
        if result == .success, let actionNames = actionsArrayRef as? [String] {
            return actionNames.contains(action)
        }
        
        return false
    }
    
    /// Check if an attribute is settable
    private func isAttributeSettable(_ attribute: String, on element: UIElement) -> Bool {
        guard let axElement = element.axElement else {
            return false
        }
        
        var isSettable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(axElement, attribute as CFString, &isSettable)
        
        return result == .success && isSettable.boolValue
    }
    
    /// Perform press action (clicking a button)
    private func performPressAction(on element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        let actionName = "AXPress"
        
        // For real buttons, check if press is supported
        let isSupported = isActionSupported(actionName, on: element)
        
        if isSupported {
            // Perform the action
            let result = AXUIElementPerformAction(axElement, actionName as CFString)
            completion(result == .success, result != .success ? "Failed to press element" : nil)
        } else {
            // Try default action as fallback
            if isActionSupported("AXPick", on: element) {
                let result = AXUIElementPerformAction(axElement, "AXPick" as CFString)
                completion(result == .success, result != .success ? "Failed to select element" : nil)
            } else {
                completion(false, "Element does not support press action")
            }
        }
    }
    
    /// Perform focus action (focusing an element)
    private func performFocusAction(on element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // First check if focused attribute is settable
        var isSettable: DarwinBoolean = false
        let focusAttr = kAXFocusedAttribute as CFString
        let result = AXUIElementIsAttributeSettable(axElement, focusAttr, &isSettable)
        
        if result == .success && isSettable.boolValue {
            // Set focus by setting the focused attribute to true
            let result = AXUIElementSetAttributeValue(axElement, focusAttr, true as CFTypeRef)
            completion(result == .success, result != .success ? "Failed to focus element" : nil)
        } else {
            // Try to perform the focus action if available
            if isActionSupported("AXFocus", on: element) {
                let actionResult = AXUIElementPerformAction(axElement, "AXFocus" as CFString)
                completion(actionResult == .success, actionResult != .success ? "Failed to focus element" : nil)
            } else {
                completion(false, "Element does not support focus")
            }
        }
    }
    
    /// Enter text into a text field
    private func performTextEntryAction(on element: UIElement, text: String, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if value attribute is settable
        var isSettable: DarwinBoolean = false
        let valueAttr = kAXValueAttribute as CFString
        let result = AXUIElementIsAttributeSettable(axElement, valueAttr, &isSettable)
        
        if result == .success && isSettable.boolValue {
            // Focus the element first to ensure it's ready to receive input
            performFocusAction(on: element) { success, error in
                if success {
                    // Set the value attribute to the new text
                    let valueResult = AXUIElementSetAttributeValue(axElement, valueAttr, text as CFTypeRef)
                    completion(valueResult == .success, valueResult != .success ? "Failed to set text value" : nil)
                } else {
                    // If we couldn't focus, we probably can't set text either
                    completion(false, "Failed to focus element before setting text: \(error ?? "Unknown error")")
                }
            }
        } else {
            completion(false, "Element does not support text input")
        }
    }
    
    /// Toggle a checkbox or checkbox-like element
    private func performToggleAction(on element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        // For checkboxes, we just press them which toggles the state
        performPressAction(on: element, completion: completion)
    }
    
    /// Set a numerical or string value for sliders, steppers, etc.
    private func performSetValueAction(on element: UIElement, value: String, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if value attribute is settable
        var isSettable: DarwinBoolean = false
        let valueAttr = kAXValueAttribute as CFString
        let result = AXUIElementIsAttributeSettable(axElement, valueAttr, &isSettable)
        
        if result == .success && isSettable.boolValue {
            // Try to set value as a number if possible
            if let doubleValue = Double(value) {
                let valueResult = AXUIElementSetAttributeValue(axElement, valueAttr, NSNumber(value: doubleValue) as CFTypeRef)
                completion(valueResult == .success, valueResult != .success ? "Failed to set numerical value" : nil)
            } else {
                // Otherwise set as string
                let valueResult = AXUIElementSetAttributeValue(axElement, valueAttr, value as CFTypeRef)
                completion(valueResult == .success, valueResult != .success ? "Failed to set value" : nil)
            }
        } else {
            completion(false, "Element does not support value setting")
        }
    }
    
    /// Set position for an element
    private func performSetPositionAction(on element: UIElement, x: Int, y: Int, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if position attribute is settable
        var isSettable: DarwinBoolean = false
        let positionAttr = kAXPositionAttribute as CFString
        let result = AXUIElementIsAttributeSettable(axElement, positionAttr, &isSettable)
        
        if result == .success && isSettable.boolValue {
            // Create a CGPoint value
            var point = CGPoint(x: CGFloat(x), y: CGFloat(y))
            
            // Convert to AXValue
            var axValue: AXValue?
            axValue = AXValueCreate(.cgPoint, &point)
            
            if let positionValue = axValue {
                // Set the position
                let setResult = AXUIElementSetAttributeValue(axElement, positionAttr, positionValue)
                completion(setResult == .success, setResult != .success ? "Failed to set position" : nil)
            } else {
                completion(false, "Failed to create position value")
            }
        } else {
            completion(false, "Element does not support position setting")
        }
    }
    
    /// Perform increment action for steppers, sliders, etc
    private func performIncrementAction(on element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        if isActionSupported("AXIncrement", on: element) {
            let result = AXUIElementPerformAction(axElement, "AXIncrement" as CFString)
            completion(result == .success, result != .success ? "Failed to increment value" : nil)
        } else {
            // Try to increment value manually if possible
            incrementValueManually(element: element, completion: completion)
        }
    }
    
    /// Perform decrement action for steppers, sliders, etc
    private func performDecrementAction(on element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        if isActionSupported("AXDecrement", on: element) {
            let result = AXUIElementPerformAction(axElement, "AXDecrement" as CFString)
            completion(result == .success, result != .success ? "Failed to decrement value" : nil)
        } else {
            // Try to decrement value manually if possible
            decrementValueManually(element: element, completion: completion)
        }
    }
    
    /// Attempt to increment a value manually by reading and updating the value attribute
    private func incrementValueManually(element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if the element has a value attribute
        var valueRef: CFTypeRef?
        let getResult = AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef)
        
        if getResult == .success, let currentValue = valueRef {
            // Determine how to increment based on value type
            if let numberValue = currentValue as? NSNumber {
                // For numbers, increment by 1 or 0.1 depending on type
                let newValue: NSNumber
                if numberValue.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    // Integer value
                    newValue = NSNumber(value: numberValue.intValue + 1)
                } else {
                    // Float/double value
                    newValue = NSNumber(value: numberValue.doubleValue + 0.1)
                }
                
                // Set the new value
                let setResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute as CFString, newValue as CFTypeRef)
                completion(setResult == .success, setResult != .success ? "Failed to increment value" : nil)
            } else {
                completion(false, "Cannot increment non-numeric value")
            }
        } else {
            completion(false, "Element does not have a value attribute")
        }
    }
    
    /// Attempt to decrement a value manually by reading and updating the value attribute
    private func decrementValueManually(element: UIElement, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if the element has a value attribute
        var valueRef: CFTypeRef?
        let getResult = AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &valueRef)
        
        if getResult == .success, let currentValue = valueRef {
            // Determine how to decrement based on value type
            if let numberValue = currentValue as? NSNumber {
                // For numbers, decrement by 1 or 0.1 depending on type
                let newValue: NSNumber
                if numberValue.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    // Integer value
                    newValue = NSNumber(value: numberValue.intValue - 1)
                } else {
                    // Float/double value
                    newValue = NSNumber(value: numberValue.doubleValue - 0.1)
                }
                
                // Set the new value
                let setResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute as CFString, newValue as CFTypeRef)
                completion(setResult == .success, setResult != .success ? "Failed to decrement value" : nil)
            } else {
                completion(false, "Cannot decrement non-numeric value")
            }
        } else {
            completion(false, "Element does not have a value attribute")
        }
    }
    
    /// Perform a generic action on an element
    private func performGenericAction(on element: UIElement, action: String, completion: @escaping (Bool, String?) -> Void) {
        guard let axElement = element.axElement else {
            completion(false, "No accessibility element reference available")
            return
        }
        
        // Check if the element supports this action
        if isActionSupported(action, on: element) {
            // Perform the action
            let result = AXUIElementPerformAction(axElement, action as CFString)
            completion(result == .success, result != .success ? "Failed to perform \(action)" : nil)
        } else {
            // Action not supported
            completion(false, "Element does not support the \(action) action")
        }
    }
}