// ABOUTME: Simple accessibility explorer app with basic safety mechanisms
// ABOUTME: Designed to avoid freezing issues while providing real accessibility data

import SwiftUI
import AppKit

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
    let name: String
    let role: String
    let appInfo: AppInfo
    let description: String
    
    // Reference to the AXUIElement
    let axElement: AXUIElement?
    
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

/// Safety-focused accessibility data provider
class SafeAccessibility {
    static let shared = SafeAccessibility()
    
    var useMockData = true {
        didSet {
            print("Changed to \(useMockData ? "mock" : "real") data mode")
        }
    }
    
    var isLoading = false
    
    private init() {}
    
    /// Check whether accessibility is authorized
    func checkAccessibilityPermissions() -> Bool {
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
    }
    
    /// Get a list of running applications
    func getApplications(completion: @escaping ([AppInfo]) -> Void) {
        if useMockData {
            completion([
                AppInfo(name: "Safari", bundleID: "com.apple.Safari", pid: 1001, icon: "safari"),
                AppInfo(name: "TextEdit", bundleID: "com.apple.TextEdit", pid: 1002, icon: "doc.text"),
                AppInfo(name: "Finder", bundleID: "com.apple.finder", pid: 1003, icon: "folder"),
                AppInfo(name: "Mail", bundleID: "com.apple.mail", pid: 1004, icon: "envelope"),
                AppInfo(name: "Photos", bundleID: "com.apple.Photos", pid: 1005, icon: "photo")
            ])
            return
        }
        
        // Use a timeout to prevent freezing
        let timeoutQueue = DispatchQueue(label: "com.timeout.queue")
        var hasCompleted = false
        
        // Set a timeout
        timeoutQueue.asyncAfter(deadline: .now() + 1.0) {
            if !hasCompleted {
                hasCompleted = true
                print("Timeout getting applications")
                // Return mock data on timeout
                completion([
                    AppInfo(name: "Safari", bundleID: "com.apple.Safari", pid: 1001, icon: "safari"),
                    AppInfo(name: "TextEdit", bundleID: "com.apple.TextEdit", pid: 1002, icon: "doc.text"),
                    AppInfo(name: "Finder", bundleID: "com.apple.finder", pid: 1003, icon: "folder")
                ])
            }
        }
        
        // Get real applications
        DispatchQueue.global(qos: .userInitiated).async {
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
            
            if !hasCompleted {
                hasCompleted = true
                completion(apps)
            }
        }
    }
    
    /// Get UI elements for an application
    func getUIElements(for app: AppInfo, completion: @escaping (UIElement?) -> Void) {
        if useMockData {
            let rootElement = UIElement(name: app.name, role: "Application", appInfo: app, description: "Application process")
            
            // Add main window
            let mainWindow = UIElement(name: "Main Window", role: "Window", appInfo: app, description: "Main application window", parent: rootElement)
            rootElement.addChild(mainWindow)
            
            // Add menu bar
            let menuBar = UIElement(name: "Menu Bar", role: "MenuBar", appInfo: app, description: "Application menu bar", parent: rootElement)
            rootElement.addChild(menuBar)
            
            // Add window elements
            let toolbar = UIElement(name: "Toolbar", role: "Toolbar", appInfo: app, description: "Window toolbar", parent: mainWindow)
            mainWindow.addChild(toolbar)
            
            let content = UIElement(name: "Content", role: "Group", appInfo: app, description: "Content area", parent: mainWindow)
            mainWindow.addChild(content)
            
            // Add some buttons to toolbar
            toolbar.addChild(UIElement(name: "Back", role: "Button", appInfo: app, description: "Go back", parent: toolbar))
            toolbar.addChild(UIElement(name: "Forward", role: "Button", appInfo: app, description: "Go forward", parent: toolbar))
            toolbar.addChild(UIElement(name: "Reload", role: "Button", appInfo: app, description: "Reload page", parent: toolbar))
            
            completion(rootElement)
            return
        }
        
        // Use a timeout for real access
        let timeoutQueue = DispatchQueue(label: "com.timeout.queue")
        var hasCompleted = false
        
        // Set a timeout for safety
        timeoutQueue.asyncAfter(deadline: .now() + 1.0) {
            if !hasCompleted {
                hasCompleted = true
                print("Timeout getting UI elements")
                // Return mock data on timeout
                let rootElement = UIElement(name: app.name, role: "Application", appInfo: app, description: "Application process")
                completion(rootElement)
            }
        }
        
        // Try to get real elements
        DispatchQueue.global(qos: .userInitiated).async {
            // Create an application accessibility element
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
                    
                    // Get window children (limited to direct children)
                    var childrenRef: CFTypeRef?
                    let childrenResult = AXUIElementCopyAttributeValue(window, kAXChildrenAttribute as CFString, &childrenRef)
                    
                    if childrenResult == .success, let childrenArray = childrenRef as? [AXUIElement] {
                        for child in childrenArray.prefix(10) {
                            var roleRef: CFTypeRef?
                            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef)
                            let role = (roleRef as? String) ?? "Unknown"
                            
                            var childTitleRef: CFTypeRef?
                            AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &childTitleRef)
                            let childTitle = (childTitleRef as? String) ?? role
                            
                            let childElement = UIElement(
                                name: childTitle,
                                role: role,
                                appInfo: app,
                                description: "\(role) element",
                                parent: windowElement,
                                axElement: child
                            )
                            windowElement.addChild(childElement)
                        }
                    }
                }
            }
            
            if !hasCompleted {
                hasCompleted = true
                completion(rootElement)
            }
        }
    }
    
    /// Get properties for an element
    func getProperties(for element: UIElement) -> [String: String] {
        var properties: [String: String] = [
            "Name": element.name,
            "Role": element.role,
            "Description": element.description
        ]
        
        if useMockData {
            // Add more mock properties based on role
            switch element.role {
            case "Application":
                properties["Process ID"] = "\(element.appInfo.pid)"
                properties["Bundle ID"] = element.appInfo.bundleID
                properties["Frontmost"] = "true"
            case "Window":
                properties["Position"] = "{x: 0, y: 0}"
                properties["Size"] = "{width: 800, height: 600}"
                properties["Main"] = "true"
                properties["Minimized"] = "false"
            case "Button":
                properties["Enabled"] = "true"
                properties["Position"] = "{x: 20, y: 20}"
                properties["Size"] = "{width: 80, height: 25}"
            default:
                properties["Type"] = element.role
            }
            
            return properties
        }
        
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
        }
        
        return properties
    }
    
    /// Load children for an element on demand
    func loadChildren(for element: UIElement, completion: @escaping () -> Void) {
        if useMockData || element.children.count > 0 {
            // Children already loaded or using mock data
            completion()
            return
        }
        
        guard let axElement = element.axElement else {
            completion()
            return
        }
        
        // Use a timeout for safety
        let timeoutQueue = DispatchQueue(label: "com.timeout.queue")
        var hasCompleted = false
        
        // Set a timeout
        timeoutQueue.asyncAfter(deadline: .now() + 0.5) {
            if !hasCompleted {
                hasCompleted = true
                print("Timeout loading children")
                completion()
            }
        }
        
        // Try to get children
        DispatchQueue.global(qos: .userInitiated).async {
            var childrenRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(axElement, kAXChildrenAttribute as CFString, &childrenRef)
            
            if result == .success, let childrenArray = childrenRef as? [AXUIElement] {
                var newChildren: [UIElement] = []
                
                // Only get a reasonable number to prevent freezing
                for child in childrenArray.prefix(20) {
                    var roleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef)
                    let role = (roleRef as? String) ?? "Unknown"
                    
                    var titleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleRef)
                    var name = (titleRef as? String) ?? role
                    
                    // Try description if title is empty
                    if name.isEmpty || name == role {
                        var descRef: CFTypeRef?
                        AXUIElementCopyAttributeValue(child, kAXDescriptionAttribute as CFString, &descRef)
                        if let desc = descRef as? String, !desc.isEmpty {
                            name = desc
                        }
                    }
                    
                    // Create child element
                    let childElement = UIElement(
                        name: name,
                        role: role,
                        appInfo: element.appInfo,
                        description: "\(role) element",
                        parent: element,
                        axElement: child
                    )
                    
                    // Check if it has children (for future use)
                    var subChildrenRef: CFTypeRef?
                    _ = AXUIElementCopyAttributeValue(child, kAXChildrenAttribute as CFString, &subChildrenRef)
                    
                    // Add to new children list
                    newChildren.append(childElement)
                }
                
                // Update element on main thread
                DispatchQueue.main.async {
                    element.children = newChildren
                    
                    if !hasCompleted {
                        hasCompleted = true
                        completion()
                    }
                }
            } else {
                if !hasCompleted {
                    hasCompleted = true
                    completion()
                }
            }
        }
    }
}

/// Main view model for the app
class ExplorerViewModel: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var selectedApp: AppInfo? = nil
    @Published var rootElement: UIElement? = nil
    @Published var selectedElement: UIElement? = nil
    @Published var properties: [String: String] = [:]
    
    @Published var useMockData = true {
        didSet {
            SafeAccessibility.shared.useMockData = useMockData
            if selectedApp != nil {
                refreshElementTree()
            }
        }
    }
    
    @Published var isLoading = false
    
    private let safeAccessibility = SafeAccessibility.shared
    
    init() {
        useMockData = true
        loadApplications()
    }
    
    func loadApplications() {
        isLoading = true
        
        safeAccessibility.getApplications { [weak self] apps in
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
        
        safeAccessibility.getUIElements(for: app) { [weak self] rootElement in
            DispatchQueue.main.async {
                self?.rootElement = rootElement
                self?.selectedElement = rootElement
                self?.isLoading = false
                
                if let rootElement = rootElement {
                    self?.loadProperties(for: rootElement)
                }
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
            
            safeAccessibility.loadChildren(for: element) {
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
        self.properties = safeAccessibility.getProperties(for: element)
    }
    
    func checkAccess() -> Bool {
        return safeAccessibility.checkAccessibilityPermissions()
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
                
                Toggle(isOn: $viewModel.useMockData) {
                    Text("Safe Mode")
                }
                .toggleStyle(SwitchToggleStyle())
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
                    Image(systemName: viewModel.useMockData ? "shield.fill" : "network")
                        .foregroundColor(viewModel.useMockData ? .orange : .green)
                    
                    Text(viewModel.useMockData ? "Safe Mode" : "Accessibility API Mode")
                        .font(.caption)
                        .foregroundColor(viewModel.useMockData ? .orange : .green)
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
            // Button icon
            Image(systemName: "button.programmable")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Compact button rendering
            RoundedRectangle(cornerRadius: 4)
                .fill(element.isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                .overlay(
                    Text(element.name)
                        .font(.system(size: 12))
                        .fontWeight(element.isSelected ? .semibold : .regular)
                        .foregroundColor(element.isSelected ? .blue : .primary)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                )
                .frame(height: 20)
                .frame(minWidth: 60, maxWidth: 120)
            
            // Role caption
            Text("Button")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Text field visualization
    private var textFieldVisualization: some View {
        HStack {
            // Text field icon
            Image(systemName: "text.cursor")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Text field mock
            RoundedRectangle(cornerRadius: 4)
                .stroke(element.isSelected ? Color.blue : Color.gray, lineWidth: 1)
                .background(Color.white.opacity(0.5))
                .frame(height: 20)
                .frame(minWidth: 80, maxWidth: 150)
                .overlay(
                    HStack {
                        Text(element.name)
                            .font(.system(size: 11))
                            .foregroundColor(element.isSelected ? .blue : .gray)
                            .padding(.leading, 4)
                            .lineLimit(1)
                        Spacer()
                    }
                )
            
            // Role caption
            Text(element.role)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Checkbox visualization
    private var checkboxVisualization: some View {
        HStack {
            // Checkbox icon
            Image(systemName: "checkmark.square")
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Checkbox label
            Text(element.name)
                .font(.system(size: 12))
                .fontWeight(element.isSelected ? .semibold : .regular)
                .foregroundColor(element.isSelected ? .blue : .primary)
                .lineLimit(1)
            
            // Role caption
            Text("Checkbox")
                .font(.caption)
                .foregroundColor(.secondary)
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
            // Element icon
            Image(systemName: iconForRole(element.role))
                .foregroundColor(element.isSelected ? .blue : .primary)
                .frame(width: 16, height: 16)
            
            // Element name and role
            VStack(alignment: .leading, spacing: 2) {
                Text(element.name)
                    .font(.system(size: 12))
                    .fontWeight(element.isSelected ? .bold : .regular)
                    .foregroundColor(element.isSelected ? .blue : .primary)
                
                Text(element.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Actions")
                .font(.headline)
            
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
                        
                        Button("Perform") {
                            // In this version, we won't actually perform actions
                            print("Would perform \(action.0) on \(element.name)")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                }
            } else {
                Text("No element selected")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Note: Actions in this demo have no effect on the actual UI elements.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func actionsForElement(_ element: UIElement) -> [(String, String)] {
        switch element.role {
        case "Button":
            return [
                ("Press", "Simulate pressing this button"),
                ("Focus", "Set keyboard focus to this button")
            ]
        case "TextField", "TextArea":
            return [
                ("Focus", "Set focus to this field"),
                ("Enter Text", "Insert text into this field")
            ]
        case "Window":
            return [
                ("Minimize", "Minimize this window"),
                ("Close", "Close this window")
            ]
        default:
            return [("Inspect", "View detailed information about this element")]
        }
    }
    
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "Press": return "hand.tap"
        case "Focus": return "scope"
        case "Enter Text": return "text.cursor"
        case "Minimize": return "arrow.down.right.square"
        case "Close": return "xmark.square"
        case "Inspect": return "magnifyingglass"
        default: return "arrow.right"
        }
    }
}