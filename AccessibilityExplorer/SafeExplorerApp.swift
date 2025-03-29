// ABOUTME: Accessibility Explorer with controlled and safe access to real accessibility APIs
// ABOUTME: Implements extensive safety measures to prevent freezing and high CPU usage

import SwiftUI
import Foundation
import AppKit

@main
struct SafeExplorerApp: App {
    @StateObject private var viewModel = SafeExplorerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(viewModel)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

/// Main view model for the explorer app
class SafeExplorerViewModel: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var selectedApplication: AppInfo? = nil
    @Published var rootElement: UINode? = nil
    @Published var selectedElement: UINode? = nil
    @Published var elementProperties: [String: String] = [:]
    
    @Published var isLoading = false
    @Published var useMockData = true
    @Published var errorMessage: String? = nil
    
    private let safeAccessibility = SafeAccessibility.shared
    
    init() {
        // Default to mock data for safety
        setUseMockData(true)
        
        // Load applications
        refreshApplications()
    }
    
    /// Toggle between mock and real data
    func setUseMockData(_ useMock: Bool) {
        self.useMockData = useMock
        safeAccessibility.setUseMockData(useMock)
    }
    
    /// Refresh the list of applications
    func refreshApplications() {
        isLoading = true
        
        safeAccessibility.getApplications { [weak self] apps in
            DispatchQueue.main.async {
                self?.applications = apps
                self?.isLoading = false
                
                // Auto-select the first application if none is selected
                if self?.selectedApplication == nil, let firstApp = apps.first {
                    self?.selectApplication(firstApp)
                }
            }
        }
    }
    
    /// Select an application and load its UI elements
    func selectApplication(_ app: AppInfo) {
        self.selectedApplication = app
        self.rootElement = nil
        self.selectedElement = nil
        self.elementProperties = [:]
        
        isLoading = true
        
        safeAccessibility.getUIElementsForApp(appInfo: app) { [weak self] rootNode in
            DispatchQueue.main.async {
                self?.rootElement = rootNode
                self?.selectedElement = rootNode
                self?.isLoading = false
                
                // Load properties for the root element
                if let rootNode = rootNode {
                    self?.loadPropertiesForElement(rootNode)
                }
            }
        }
    }
    
    /// Select a UI element and load its properties
    func selectElement(_ element: UINode) {
        // Deselect previous element
        selectedElement?.isSelected = false
        
        // Select new element
        element.isSelected = true
        selectedElement = element
        
        // Load properties for this element
        loadPropertiesForElement(element)
    }
    
    /// Load the children for an element if they haven't been loaded yet
    func loadChildrenIfNeeded(for element: UINode) {
        // If children are already loaded, no need to reload
        if !element.children.isEmpty {
            return
        }
        
        element.isLoading = true
        
        if selectedApplication == nil {
            element.isLoading = false
            return
        }
        
        if useMockData {
            // For mock data, we don't need to do anything since mock children are pre-loaded
            element.isLoading = false
            return
        }
        
        // For real data, try to load children from the AXUIElement
        if let axElement = element.axElement {
            // Get children with a timeout
            let loadingQueue = DispatchQueue(label: "com.accessibility-explorer.loading", qos: .userInitiated)
            
            loadingQueue.async { [weak self, weak element] in
                guard let self = self, let element = element else { return }
                
                // Create a timer to enforce a timeout
                let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    print("Child loading timed out for \(element.name)")
                    
                    DispatchQueue.main.async {
                        element.isLoading = false
                    }
                }
                
                // Try to get children
                var childrenRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(axElement, kAXChildrenAttribute as CFString, &childrenRef)
                
                if result == .success, let childrenArray = childrenRef as? [AXUIElement] {
                    // Process only a reasonable number of children to prevent freezing
                    var newChildren: [UINode] = []
                    for childElement in childrenArray.prefix(20) {
                        if let childNode = safeAccessibility.createNodeFromElement(
                            element: childElement,
                            parent: element,
                            appInfo: element.appInfo
                        ) {
                            newChildren.append(childNode)
                        }
                    }
                    
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        element.children = newChildren
                        element.isLoading = false
                        timeoutTimer.invalidate()
                    }
                } else {
                    // Failed to get children
                    DispatchQueue.main.async {
                        element.isLoading = false
                        timeoutTimer.invalidate()
                    }
                }
            }
        } else {
            // No AXUIElement reference
            element.isLoading = false
        }
    }
    
    /// Load properties for a UI element
    private func loadPropertiesForElement(_ element: UINode) {
        isLoading = true
        
        safeAccessibility.getPropertiesForElement(element: element) { [weak self] properties in
            DispatchQueue.main.async {
                self?.elementProperties = properties
                self?.isLoading = false
            }
        }
    }
}

/// Main content view
struct ContentView: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    viewModel.refreshApplications()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                // Safety mode toggle
                Toggle(isOn: $viewModel.useMockData) {
                    Text("Safe Mode")
                }
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: viewModel.useMockData) { newValue in
                    viewModel.setUseMockData(newValue)
                    viewModel.refreshApplications()
                }
                
                Button(action: {
                    showSettings.toggle()
                }) {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Split view with sidebar and content
            HSplitView {
                // Applications sidebar
                ApplicationSidebar()
                    .frame(minWidth: 200, maxWidth: 300)
                
                // Element tree and details
                if viewModel.selectedApplication != nil {
                    // Split view for tree and properties
                    HSplitView {
                        // Element tree
                        ElementTreeView()
                            .frame(minWidth: 300, maxWidth: .infinity)
                        
                        // Element properties
                        ElementPropertiesView()
                            .frame(minWidth: 350, maxWidth: .infinity)
                    }
                } else {
                    // No application selected
                    EmptySelectionView()
                }
            }
            
            // Status bar
            StatusBarView()
                .frame(height: 22)
                .background(Color(.controlBackgroundColor))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

/// Sidebar showing available applications
struct ApplicationSidebar: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
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
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // List of applications
                List {
                    ForEach(viewModel.applications) { app in
                        ApplicationRow(app: app)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectApplication(app)
                            }
                            .background(viewModel.selectedApplication?.id == app.id ? Color.blue.opacity(0.1) : Color.clear)
                    }
                }
                .listStyle(SidebarListStyle())
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

/// Row in the applications list
struct ApplicationRow: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
    var body: some View {
        HStack {
            Image(systemName: iconForApp(app))
                .frame(width: 20, height: 20)
                .foregroundColor(viewModel.selectedApplication?.id == app.id ? .blue : .primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.selectedApplication?.id == app.id ? .blue : .primary)
                
                Text("PID: \(app.pid)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.selectedApplication?.id == app.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Get appropriate icon for the app
    private func iconForApp(_ app: AppInfo) -> String {
        switch app.name {
        case "Safari": return "safari"
        case "TextEdit": return "doc.text"
        case "Finder": return "folder"
        case "Mail": return "envelope"
        case "Photos": return "photo"
        case "Calendar": return "calendar"
        case "Notes": return "note.text"
        case "Maps": return "map"
        case "Messages": return "message"
        case "System Settings": return "gearshape"
        default: return "app.badge"
        }
    }
}

/// Tree view of UI elements
struct ElementTreeView: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
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
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let rootElement = viewModel.rootElement {
                ScrollView {
                    VStack(alignment: .leading) {
                        // Root element with all its children
                        ElementNodeView(node: rootElement)
                            .padding(.horizontal)
                    }
                }
            } else {
                Text("No elements to display")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.textBackgroundColor))
    }
}

/// Individual UI element node in the tree
struct ElementNodeView: View {
    @ObservedObject var node: UINode
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Element row with expansion button
            Button(action: {
                // Select the element
                viewModel.selectElement(node)
                
                // Toggle expansion
                withAnimation {
                    node.isExpanded.toggle()
                    
                    // Load children if expanding and no children yet
                    if node.isExpanded && node.children.isEmpty {
                        viewModel.loadChildrenIfNeeded(for: node)
                    }
                }
            }) {
                HStack(spacing: 8) {
                    // Expansion indicator
                    if !node.children.isEmpty {
                        Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Element icon
                    Image(systemName: iconForRole(node.role))
                        .foregroundColor(node.isSelected ? .blue : .primary)
                        .frame(width: 16, height: 16)
                    
                    // Element name and role
                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.name)
                            .font(.system(size: 14))
                            .foregroundColor(node.isSelected ? .blue : .primary)
                            .lineLimit(1)
                        
                        Text(node.role)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(node.isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(4)
            
            // Show loading indicator while loading children
            if node.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 36)
            }
            
            // Show children if expanded
            if node.isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(node.children) { child in
                        ElementNodeView(node: child)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    /// Get appropriate icon for element role
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable"
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "Menu", "MenuBar", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        case "FileItem": return "doc"
        case "FolderItem": return "folder"
        case "TabGroup", "Tab": return "rectangle.stack"
        case "SearchField": return "magnifyingglass"
        case "Heading": return "text.alignleft"
        case "Navigation": return "arrow.up.left.and.arrow.down.right"
        case "Article": return "doc.text"
        default: return "circle"
        }
    }
}

/// View showing properties of the selected element
struct ElementPropertiesView: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Element header
            if let element = viewModel.selectedElement {
                ElementHeader(element: element)
            }
            
            // Tab selection
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        Text(tabTitle(for: index))
                            .font(.system(size: 13))
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(4)
                }
                Spacer()
            }
            .padding(.horizontal)
            .background(Color(.separatorColor).opacity(0.3))
            
            // Tab content
            if viewModel.isLoading && viewModel.elementProperties.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading properties...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let element = viewModel.selectedElement {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case 0: // Properties
                            BasicPropertiesView(properties: viewModel.elementProperties)
                        case 1: // Attributes
                            AttributesView(properties: viewModel.elementProperties)
                        case 2: // Actions
                            ActionsView(element: element)
                        default:
                            EmptyView()
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Information panel
                        InfoPanel()
                    }
                    .padding(.top)
                }
            } else {
                Text("No element selected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Properties"
        case 1: return "Attributes"
        case 2: return "Actions"
        default: return ""
        }
    }
}

/// Header for the selected element
struct ElementHeader: View {
    let element: UINode
    
    var body: some View {
        HStack {
            // Role icon
            Image(systemName: iconForRole(element.role))
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                // Title
                Text(element.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Role description
                Text("\(element.role)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Path
                Text(generatePath(for: element))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.5))
    }
    
    /// Generate a path string representation for the element
    private func generatePath(for element: UINode) -> String {
        let ancestors = element.getAncestors()
        let fullPath = ancestors + [element]
        return fullPath.map { $0.name }.joined(separator: " → ")
    }
    
    /// Get appropriate icon for element role
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable"
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "Menu", "MenuBar", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        case "FileItem": return "doc"
        case "FolderItem": return "folder"
        case "TabGroup", "Tab": return "rectangle.stack"
        default: return "circle"
        }
    }
}

/// Basic properties tab content
struct BasicPropertiesView: View {
    let properties: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("Basic Properties").font(.headline)) {
                PropertyList(items: basicProperties)
            }
            
            GroupBox(label: Text("Details").font(.headline)) {
                PropertyList(items: detailProperties)
            }
        }
        .padding(.horizontal)
    }
    
    private var basicProperties: [(name: String, value: String)] {
        [
            ("Name", properties["Name"] ?? "Unknown"),
            ("Role", properties["Role"] ?? "Unknown"),
            ("Description", properties["Description"] ?? "-")
        ]
    }
    
    private var detailProperties: [(name: String, value: String)] {
        var props: [(String, String)] = []
        
        for (key, value) in properties {
            if !["Name", "Role", "Description"].contains(key) {
                props.append((key, value))
            }
        }
        
        return props.sorted { $0.0 < $1.0 }
    }
}

/// Attributes tab content
struct AttributesView: View {
    let properties: [String: String]
    
    var body: some View {
        GroupBox(label: Text("All Attributes").font(.headline)) {
            PropertyList(items: attributeList)
        }
        .padding(.horizontal)
    }
    
    private var attributeList: [(name: String, value: String)] {
        return properties.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}

/// Actions tab content
struct ActionsView: View {
    let element: UINode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Actions")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(availableActions(for: element), id: \.name) { action in
                Button(action: {
                    print("Action: \(action.name) would be performed on \(element.role) \(element.name)")
                }) {
                    HStack {
                        Image(systemName: iconForAction(action.name))
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading) {
                            Text(action.name)
                                .font(.headline)
                            
                            Text(action.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Explanation text
            Text("Note: Actions are simulated and may not affect real UI elements in safe mode.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    /// Generate available actions based on element role
    private func availableActions(for element: UINode) -> [(name: String, description: String)] {
        switch element.role {
        case "Button":
            return [
                ("Press", "Simulate a click/press on this button"),
                ("Focus", "Set input focus to this button")
            ]
            
        case "TextField", "TextArea":
            return [
                ("Focus", "Set input focus to this text field"),
                ("Select All", "Select all text in this field"),
                ("Insert Text", "Insert text at current cursor position"),
                ("Clear", "Clear all text from this field")
            ]
            
        case "Window":
            return [
                ("Bring to Front", "Make this window frontmost"),
                ("Minimize", "Minimize this window to the Dock"),
                ("Close", "Close this window"),
                ("Resize", "Change the size of this window")
            ]
            
        case "Application":
            return [
                ("Activate", "Bring this application to the foreground"),
                ("Hide", "Hide this application"),
                ("Quit", "Terminate this application"),
                ("Show Info", "Show information about this application")
            ]
            
        case "Menu", "MenuItem":
            return [
                ("Open", "Open this menu"),
                ("Select", "Select this menu item"),
                ("Highlight", "Highlight but don't select this item")
            ]
            
        case "List", "Table":
            return [
                ("Select Item", "Select an item in this container"),
                ("Scroll", "Scroll through the content"),
                ("Focus", "Set input focus to this container")
            ]
            
        default:
            if !element.children.isEmpty {
                return [
                    ("Expand", "Expand to show children"),
                    ("Collapse", "Collapse to hide children"),
                    ("Focus", "Set input focus to this element")
                ]
            } else {
                return [
                    ("Focus", "Set input focus to this element"),
                    ("Inspect", "Show detailed information")
                ]
            }
        }
    }
    
    /// Get icon for action
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "Press": return "hand.tap"
        case "Focus": return "scope"
        case "Select All": return "selection.pin.in.out"
        case "Insert Text": return "text.cursor"
        case "Clear": return "xmark.circle"
        case "Bring to Front": return "square.stack.3d.up"
        case "Minimize": return "arrow.down.right.square"
        case "Close": return "xmark.square"
        case "Resize": return "arrow.up.left.and.arrow.down.right"
        case "Activate": return "app.badge"
        case "Hide": return "eye.slash"
        case "Quit": return "power"
        case "Show Info": return "info.circle"
        case "Open": return "folder"
        case "Select": return "checkmark.circle"
        case "Highlight": return "sparkles"
        case "Select Item": return "hand.point.up.left"
        case "Scroll": return "scroll"
        case "Expand": return "chevron.down.square"
        case "Collapse": return "chevron.up.square"
        case "Inspect": return "magnifyingglass"
        default: return "arrow.right.circle"
        }
    }
}

/// Helper for displaying a list of properties
struct PropertyList: View {
    let items: [(name: String, value: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items, id: \.name) { item in
                HStack(alignment: .top) {
                    Text(item.name)
                        .font(.system(size: 12))
                        .frame(width: 100, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    Text(item.value)
                        .font(.system(size: 12))
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Divider()
            }
        }
        .padding()
    }
}

/// Information panel at the bottom of property views
struct InfoPanel: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.bottom, 4)
            
            HStack(alignment: .center) {
                Image(systemName: viewModel.useMockData ? "exclamationmark.shield.fill" : "info.circle.fill")
                    .foregroundColor(viewModel.useMockData ? .orange : .blue)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.useMockData ? "Safe Mode Active" : "Live Accessibility Data")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.useMockData ? .orange : .blue)
                    
                    Text(viewModel.useMockData ?
                        "Using simulated data to prevent system freezes." :
                        "Accessing real accessibility APIs with safety limits.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(viewModel.useMockData ? Color.orange.opacity(0.05) : Color.blue.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

/// Status bar at the bottom of the window
struct StatusBarView: View {
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    
    var body: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .padding(.trailing, 4)
                
                Text("Loading...")
                    .font(.system(size: 11))
            } else if let errorMessage = viewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: viewModel.useMockData ? "shield.fill" : "network")
                    .foregroundColor(viewModel.useMockData ? .orange : .green)
                    .font(.system(size: 11))
                
                Text(viewModel.useMockData ? "Safe Mode" : "Connected")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.useMockData ? .orange : .green)
            }
            
            Spacer()
            
            if let app = viewModel.selectedApplication {
                Text("\(app.name) (PID: \(app.pid))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

/// Empty view shown when no application is selected
struct EmptySelectionView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.left")
                .font(.system(size: 50))
                .padding()
            
            Text("Select an application from the sidebar")
                .font(.title2)
            
            Text("Choose an application to view its accessibility hierarchy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }
}

/// Settings view
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: SafeExplorerViewModel
    @State private var tempUseMockData: Bool
    
    init() {
        // Initialize state with the current value from the view model
        _tempUseMockData = State(initialValue: SafeAccessibility.shared.useMockData)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            // Safe mode settings
            GroupBox(label: Text("Safety Settings").font(.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Use Safe Mode", isOn: $tempUseMockData)
                        .padding(.vertical, 8)
                    
                    Text("""
                    Safe Mode uses simulated data instead of real accessibility APIs to prevent system freezes and high CPU usage.
                    
                    Turn off Safe Mode to access real accessibility data (requires permissions).
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Button("Apply Changes") {
                        viewModel.setUseMockData(tempUseMockData)
                        viewModel.refreshApplications()
                    }
                    .disabled(tempUseMockData == viewModel.useMockData)
                }
                .padding()
            }
            .padding()
            
            // Permissions info
            GroupBox(label: Text("Accessibility Permissions").font(.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This app requires accessibility permissions to access UI elements from other applications.")
                        .font(.body)
                    
                    Button("Open Accessibility Settings") {
                        // Open System Preferences at Accessibility pane
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                }
                .padding()
            }
            .padding()
            
            Spacer()
            
            // Version info
            Text("Accessibility Explorer v1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .frame(width: 500, height: 400)
    }
}