// ABOUTME: Minimal Accessibility Explorer app that avoids any accessibility API calls
// ABOUTME: Provides a static UI that simulates accessibility exploration

import SwiftUI

// MARK: - Models

// Represents a property of an accessibility element
struct ElementProperty: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let category: PropertyCategory
    
    init(name: String, value: String, category: PropertyCategory = .general) {
        self.name = name
        self.value = value
        self.category = category
    }
    
    enum PropertyCategory: String, CaseIterable {
        case general = "General"
        case attributes = "Attributes"
        case actions = "Actions"
        case position = "Position & Size"
    }
}

// Simple model for mock applications
struct MockApplication: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var icon: String // SF Symbol name
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MockApplication, rhs: MockApplication) -> Bool {
        lhs.id == rhs.id
    }
}

// Model for UI Elements with hierarchical structure
class UIElement: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let description: String
    let hasChildren: Bool
    
    @Published var isExpanded: Bool = false
    @Published var children: [UIElement] = []
    @Published var isSelected: Bool = false
    
    weak var parent: UIElement?
    private var childrenGenerated = false
    
    init(name: String, role: String, description: String = "", hasChildren: Bool = false) {
        self.name = name
        self.role = role
        self.description = description
        self.hasChildren = hasChildren
    }
    
    // Generate mock children elements if they haven't been generated yet
    func loadChildren() {
        guard hasChildren && !childrenGenerated else { return }
        
        // Only generate children once
        childrenGenerated = true
        
        // Create appropriate children based on role
        switch role {
        case "Application":
            children = [
                UIElement(name: "Main Window", role: "Window", description: "Main application window", hasChildren: true),
                UIElement(name: "Menu Bar", role: "Menu", description: "Application menu", hasChildren: true)
            ]
            
        case "Window":
            children = [
                UIElement(name: "Toolbar", role: "Toolbar", description: "Window toolbar", hasChildren: true),
                UIElement(name: "Content Area", role: "Group", description: "Main content", hasChildren: true),
                UIElement(name: "Status Bar", role: "Group", description: "Status information", hasChildren: true)
            ]
            
        case "Toolbar":
            children = [
                UIElement(name: "New", role: "Button", description: "Create new document", hasChildren: false),
                UIElement(name: "Open", role: "Button", description: "Open document", hasChildren: false),
                UIElement(name: "Save", role: "Button", description: "Save document", hasChildren: false),
                UIElement(name: "Search Field", role: "SearchField", description: "Search in document", hasChildren: false)
            ]
            
        case "Group":
            if name == "Content Area" {
                children = [
                    UIElement(name: "Document Area", role: "ScrollArea", description: "Document content", hasChildren: true),
                    UIElement(name: "Sidebar", role: "List", description: "Navigation sidebar", hasChildren: false)
                ]
            } else if name == "Status Bar" {
                children = [
                    UIElement(name: "Status Text", role: "StaticText", description: "Status information", hasChildren: false),
                    UIElement(name: "Progress Indicator", role: "ProgressIndicator", description: "Operation progress", hasChildren: false)
                ]
            }
            
        case "Menu":
            children = [
                UIElement(name: "File", role: "MenuItem", description: "File menu", hasChildren: true),
                UIElement(name: "Edit", role: "MenuItem", description: "Edit menu", hasChildren: true),
                UIElement(name: "View", role: "MenuItem", description: "View menu", hasChildren: true),
                UIElement(name: "Help", role: "MenuItem", description: "Help menu", hasChildren: true)
            ]
            
        case "MenuItem":
            if !name.isEmpty {
                let itemCount = Int.random(in: 3...6)
                var menuItems: [UIElement] = []
                
                for i in 1...itemCount {
                    menuItems.append(UIElement(name: "\(name) Item \(i)", role: "MenuItem", hasChildren: false))
                }
                
                children = menuItems
            }
            
        case "ScrollArea":
            children = [
                UIElement(name: "Text Content", role: "Text", description: "Document text", hasChildren: false),
                UIElement(name: "Scrollbar", role: "Scrollbar", description: "Vertical scrollbar", hasChildren: false)
            ]
            
        default:
            // Generic children for other element types
            if hasChildren {
                let childCount = Int.random(in: 2...5)
                children = (1...childCount).map { i in
                    UIElement(name: "Child \(i)", role: "Generic", description: "Child element", hasChildren: false)
                }
            }
        }
        
        // Set parent reference for each child
        for child in children {
            child.parent = self
        }
    }
    
    // Function to get all ancestors up to the root
    func getAncestors() -> [UIElement] {
        var ancestors: [UIElement] = []
        var current: UIElement? = self.parent
        
        while let parent = current {
            ancestors.insert(parent, at: 0)
            current = parent.parent
        }
        
        return ancestors
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UIElement, rhs: UIElement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Models

// Create mock UI elements specific to each application
func createMockUITreeFor(app: MockApplication) -> UIElement {
    let rootElement = UIElement(name: app.name, role: "Application", description: "Application process", hasChildren: true)
    
    // Pre-expand the root element
    rootElement.isExpanded = true
    rootElement.loadChildren()
    
    // For specific applications, customize the tree
    if app.name == "Safari" {
        if let window = rootElement.children.first(where: { $0.role == "Window" }) {
            window.isExpanded = true
            window.loadChildren()
            
            if let contentArea = window.children.first(where: { $0.name == "Content Area" }) {
                contentArea.children = [
                    UIElement(name: "Address Bar", role: "TextField", description: "URL field", hasChildren: false),
                    UIElement(name: "Web Content", role: "WebArea", description: "Web page content", hasChildren: true),
                    UIElement(name: "Tabs", role: "TabGroup", description: "Browser tabs", hasChildren: true)
                ]
                
                if let webContent = contentArea.children.first(where: { $0.name == "Web Content" }) {
                    webContent.children = [
                        UIElement(name: "Heading", role: "Heading", description: "Page heading", hasChildren: false),
                        UIElement(name: "Navigation", role: "Navigation", description: "Site navigation", hasChildren: true),
                        UIElement(name: "Main Content", role: "Article", description: "Page content", hasChildren: true)
                    ]
                }
            }
        }
    } else if app.name == "TextEdit" {
        if let window = rootElement.children.first(where: { $0.role == "Window" }) {
            window.isExpanded = true
            window.loadChildren()
            
            if let contentArea = window.children.first(where: { $0.name == "Content Area" }) {
                contentArea.children = [
                    UIElement(name: "Text Area", role: "TextArea", description: "Document text", hasChildren: false),
                    UIElement(name: "Format Bar", role: "Group", description: "Formatting controls", hasChildren: true)
                ]
                
                if let formatBar = contentArea.children.first(where: { $0.name == "Format Bar" }) {
                    formatBar.children = [
                        UIElement(name: "Bold", role: "Button", description: "Bold text", hasChildren: false),
                        UIElement(name: "Italic", role: "Button", description: "Italic text", hasChildren: false),
                        UIElement(name: "Underline", role: "Button", description: "Underline text", hasChildren: false)
                    ]
                }
            }
        }
    } else if app.name == "Finder" {
        if let window = rootElement.children.first(where: { $0.role == "Window" }) {
            window.isExpanded = true
            window.loadChildren()
            
            if let contentArea = window.children.first(where: { $0.name == "Content Area" }) {
                contentArea.children = [
                    UIElement(name: "Sidebar", role: "List", description: "Favorites and locations", hasChildren: true),
                    UIElement(name: "File List", role: "Table", description: "Files and folders", hasChildren: true)
                ]
                
                if let sidebar = contentArea.children.first(where: { $0.name == "Sidebar" }) {
                    sidebar.children = [
                        UIElement(name: "Favorites", role: "Group", description: "Favorite locations", hasChildren: true),
                        UIElement(name: "Locations", role: "Group", description: "Storage locations", hasChildren: true)
                    ]
                }
                
                if let fileList = contentArea.children.first(where: { $0.name == "File List" }) {
                    fileList.children = [
                        UIElement(name: "Document.pdf", role: "FileItem", description: "PDF document", hasChildren: false),
                        UIElement(name: "Image.jpg", role: "FileItem", description: "JPEG image", hasChildren: false),
                        UIElement(name: "Folder", role: "FolderItem", description: "Folder", hasChildren: true)
                    ]
                }
            }
        }
    }
    
    return rootElement
}

// View model for our app
class ExplorerViewModel: ObservableObject {
    @Published var applications: [MockApplication] = []
    @Published var selectedApplication: MockApplication? = nil
    @Published var rootElement: UIElement? = nil
    @Published var selectedElement: UIElement? = nil
    
    init() {
        // Create static mock applications
        self.applications = [
            MockApplication(name: "Safari", icon: "safari"),
            MockApplication(name: "TextEdit", icon: "doc.text"),
            MockApplication(name: "Finder", icon: "folder"),
            MockApplication(name: "Mail", icon: "envelope"),
            MockApplication(name: "Calendar", icon: "calendar"),
            MockApplication(name: "Notes", icon: "note.text")
        ]
    }
    
    func selectApplication(_ app: MockApplication) {
        self.selectedApplication = app
        
        // Generate mock UI tree for this application
        self.rootElement = createMockUITreeFor(app: app)
        
        // Auto-select the application element
        self.selectedElement = rootElement
    }
    
    func selectElement(_ element: UIElement) {
        // Deselect previously selected element
        selectedElement?.isSelected = false
        
        // Select new element
        element.isSelected = true
        selectedElement = element
        
        // Debug logging
        print("Element selected: \(element.name) (role: \(element.role))")
    }
}

// MARK: - App Structure

@main
struct AccessibilityExplorerApp: App {
    @StateObject private var viewModel = ExplorerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(viewModel)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    @State private var showDebug = false
    
    var body: some View {
        VStack {
            // Main application content
            HSplitView {
                // Sidebar with applications
                ApplicationSidebar()
                    .frame(minWidth: 200, maxWidth: 300)
                
                // Main content
                if viewModel.selectedApplication != nil {
                    ExplorerContent()
                } else {
                    // No application selected
                    EmptySelectionView()
                }
            }
            
            // Debug bar
            if showDebug {
                DebugInfoBar()
            }
            
            // Debug toggle
            HStack {
                Spacer()
                Button("Toggle Debug") {
                    showDebug.toggle()
                }
                .buttonStyle(PlainButtonStyle())
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                .padding(4)
            }
        }
    }
}

// Separate view for the main content once an app is selected
struct ExplorerContent: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        HSplitView {
            // UI Element tree
            ElementTreeView()
                .frame(minWidth: 300, maxWidth: .infinity)
            
            // Element details
            ElementDetailsView()
                .frame(minWidth: 300, maxWidth: .infinity)
        }
    }
}

// Debug information bar
struct DebugInfoBar: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                DebugBlock(title: "Selected App", value: viewModel.selectedApplication?.name ?? "None")
                
                DebugBlock(title: "Root Element", value: viewModel.rootElement?.name ?? "None")
                
                DebugBlock(title: "Selected Element", value: viewModel.selectedElement?.name ?? "None")
                
                if let root = viewModel.rootElement {
                    DebugBlock(title: "Root Children", value: "\(root.children.count)")
                    
                    if root.isExpanded {
                        DebugBlock(title: "Root Expanded", value: "Yes")
                    } else {
                        DebugBlock(title: "Root Expanded", value: "No")
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color.black.opacity(0.05))
    }
}

struct DebugBlock: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12))
                .bold()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.5))
        .cornerRadius(4)
    }
}

// MARK: - View Components

struct ApplicationSidebar: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications")
                .font(.headline)
                .padding()
            
            // Simple list with explicit selection handling
            List {
                ForEach(viewModel.applications) { app in
                    ApplicationRow(
                        app: app,
                        isSelected: viewModel.selectedApplication?.id == app.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Application clicked: \(app.name)")
                        viewModel.selectApplication(app)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            // Debug info
            if let selectedApp = viewModel.selectedApplication {
                VStack(alignment: .leading) {
                    Text("Selected: \(selectedApp.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

struct ApplicationRow: View {
    var app: MockApplication
    var isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: app.icon)
                .frame(width:.none, height: 20)
                .foregroundColor(isSelected ? .blue : .primary)
            
            Text(app.name)
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .primary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

struct ElementTreeView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Element Tree")
                .font(.headline)
                .padding()
            
            if let rootElement = viewModel.rootElement {
                // Debug text to verify the root element exists
                Text("Found root element: \(rootElement.name)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
                
                // Display the tree with a simplified list approach
                ScrollView {
                    VStack(alignment: .leading) {
                        ElementTreeNodeView(element: rootElement)
                            .padding(.horizontal)
                    }
                }
                .background(Color(.textBackgroundColor))
            } else {
                Text("No elements to display")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ElementTreeNodeView: View {
    @ObservedObject var element: UIElement
    @EnvironmentObject private var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main element row
            Button(action: {
                // Select this element
                viewModel.selectElement(element)
                
                // If it has children, expand it
                if element.hasChildren {
                    withAnimation {
                        element.isExpanded.toggle()
                        
                        // Load children when expanding
                        if element.isExpanded {
                            element.loadChildren()
                        }
                    }
                }
                
                print("Clicked element: \(element.name)")
            }) {
                HStack(spacing: 8) {
                    // Expansion indicator
                    if element.hasChildren {
                        Image(systemName: element.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Element icon based on role
                    Image(systemName: iconForRole(element.role))
                        .foregroundColor(element.isSelected ? .blue : .primary)
                        .frame(width: 20, height: 20)
                    
                    // Element name and role
                    VStack(alignment: .leading, spacing: 2) {
                        Text(element.name)
                            .font(.system(size: 14))
                            .foregroundColor(element.isSelected ? .blue : .primary)
                        
                        Text(element.role)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(element.isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(4)
            
            // Children (if expanded)
            if element.isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(element.children) { child in
                        ElementTreeNodeView(element: child)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    // Get appropriate icon for element role
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable" 
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "Menu", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        case "FileItem": return "doc"
        case "FolderItem": return "folder"
        case "TabGroup": return "rectangle.stack"
        default: return "circle"
        }
    }
}

struct ElementDetailsView: View {
    @EnvironmentObject private var viewModel: ExplorerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Element header with icon and title
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let element = viewModel.selectedElement {
                        switch selectedTab {
                        case 0: // Properties
                            ElementPropertiesTab(element: element)
                        case 1: // Attributes
                            ElementAttributesTab(element: element)
                        case 2: // Actions
                            ElementActionsTab(element: element)
                        default:
                            EmptyView()
                        }
                    } else {
                        Text("No element selected")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Static information about the demo
                    BottomInfoPanel()
                }
                .padding(.top)
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

struct ElementHeader: View {
    let element: UIElement
    
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
    
    // Generate a path string representation for the element
    private func generatePath(for element: UIElement) -> String {
        let ancestors = element.getAncestors()
        let fullPath = ancestors + [element]
        return fullPath.map { $0.name }.joined(separator: " → ")
    }
    
    // Get appropriate icon for element role
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Application": return "app.badge"
        case "Window": return "macwindow"
        case "Button": return "button.programmable"
        case "TextField", "TextArea": return "text.cursor"
        case "StaticText": return "text.quote"
        case "Toolbar": return "menubar"
        case "Menu", "MenuItem": return "menubar.arrow.down"
        case "Group": return "square.stack"
        case "List": return "list.bullet"
        case "Table": return "tablecells"
        case "WebArea": return "globe"
        case "ScrollArea": return "scroll"
        case "FileItem": return "doc"
        case "FolderItem": return "folder"
        case "TabGroup": return "rectangle.stack"
        default: return "circle"
        }
    }
}

// Tab 1: Basic Properties
struct ElementPropertiesTab: View {
    let element: UIElement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Basic properties
            ElementPropertyGroup(title: "Basic Properties") {
                ElementPropertyRow(name: "Name", value: element.name)
                ElementPropertyRow(name: "Role", value: element.role)
                ElementPropertyRow(name: "Description", value: element.description.isEmpty ? "-" : element.description)
                ElementPropertyRow(name: "Has Children", value: "\(element.hasChildren)")
                ElementPropertyRow(name: "Children Count", value: "\(element.children.count)")
            }
            
            // Hierarchy information
            ElementPropertyGroup(title: "Hierarchy") {
                if let parent = element.parent {
                    ElementPropertyRow(name: "Parent", value: "\(parent.role): \(parent.name)")
                } else {
                    ElementPropertyRow(name: "Parent", value: "None (Root Element)")
                }
                
                let ancestorCount = element.getAncestors().count
                ElementPropertyRow(name: "Depth in Tree", value: "\(ancestorCount)")
                
                ElementPropertyRow(name: "Siblings", value: "\(element.parent?.children.count ?? 0)")
            }
            
            // Platform-specific data (macOS)
            ElementPropertyGroup(title: "Platform Info") {
                ElementPropertyRow(name: "Platform", value: "macOS")
                ElementPropertyRow(name: "Explorer Version", value: "1.0.0")
                ElementPropertyRow(name: "Mode", value: "Static Demo")
            }
        }
        .padding(.horizontal)
    }
}

// Tab 2: Detailed Attributes
struct ElementAttributesTab: View {
    let element: UIElement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Standard attributes
            ElementPropertyGroup(title: "Standard Attributes") {
                switch element.role {
                case "Button":
                    ElementPropertyRow(name: "Enabled", value: "true")
                    ElementPropertyRow(name: "Focused", value: "false")
                    ElementPropertyRow(name: "Visible", value: "true")
                    ElementPropertyRow(name: "Position", value: "{x: 100, y: 50}")
                    ElementPropertyRow(name: "Size", value: "{width: 80, height: 24}")
                    ElementPropertyRow(name: "Title", value: element.name)
                    ElementPropertyRow(name: "Role Description", value: "button")
                    
                case "TextField", "TextArea":
                    ElementPropertyRow(name: "Value", value: "Sample text")
                    ElementPropertyRow(name: "Editable", value: "true")
                    ElementPropertyRow(name: "Focused", value: "false")
                    ElementPropertyRow(name: "Position", value: "{x: 120, y: 80}")
                    ElementPropertyRow(name: "Size", value: "{width: 200, height: 20}")
                    ElementPropertyRow(name: "Placeholder", value: "Enter text here")
                    ElementPropertyRow(name: "Selection Range", value: "none")
                    ElementPropertyRow(name: "Character Count", value: "11")
                    
                case "Window":
                    ElementPropertyRow(name: "Focused", value: "true")
                    ElementPropertyRow(name: "Main", value: "true")
                    ElementPropertyRow(name: "Minimized", value: "false")
                    ElementPropertyRow(name: "Position", value: "{x: 0, y: 0}")
                    ElementPropertyRow(name: "Size", value: "{width: 800, height: 600}")
                    ElementPropertyRow(name: "Title", value: element.name)
                    ElementPropertyRow(name: "Close Button", value: "Available")
                    ElementPropertyRow(name: "Minimize Button", value: "Available")
                    ElementPropertyRow(name: "Zoom Button", value: "Available")
                    
                case "Application":
                    ElementPropertyRow(name: "Frontmost", value: "true")
                    ElementPropertyRow(name: "Hidden", value: "false")
                    ElementPropertyRow(name: "Path", value: "/Applications/\(element.name).app")
                    ElementPropertyRow(name: "Process ID", value: "12345")
                    ElementPropertyRow(name: "Bundle ID", value: "com.example.\(element.name.lowercased())")
                    ElementPropertyRow(name: "Windows", value: "\(element.children.filter { $0.role == "Window" }.count)")
                    
                case "Menu", "MenuItem":
                    ElementPropertyRow(name: "Enabled", value: "true")
                    ElementPropertyRow(name: "Title", value: element.name)
                    ElementPropertyRow(name: "Shortcut", value: element.role == "Menu" ? "None" : "⌘\(element.name.first ?? "?")")
                    ElementPropertyRow(name: "Selected", value: "false")
                    ElementPropertyRow(name: "Child Items", value: "\(element.children.count)")
                    
                case "Group", "List", "Table":
                    ElementPropertyRow(name: "Visible", value: "true")
                    ElementPropertyRow(name: "Position", value: "{x: 50, y: 100}")
                    ElementPropertyRow(name: "Size", value: "{width: 400, height: 300}")
                    ElementPropertyRow(name: "Item Count", value: "\(element.children.count)")
                    ElementPropertyRow(name: "Selected Item Count", value: "0")
                    ElementPropertyRow(name: "Scrollable", value: "true")
                    
                default:
                    ElementPropertyRow(name: "Visible", value: "true")
                    ElementPropertyRow(name: "Enabled", value: "true")
                    ElementPropertyRow(name: "Position", value: "{x: 50, y: 50}")
                    ElementPropertyRow(name: "Size", value: "{width: 100, height: 30}")
                    ElementPropertyRow(name: "Title", value: element.name)
                }
            }
            
            // Role-specific attributes
            if let specificAttributes = roleSpecificAttributes(for: element) {
                ElementPropertyGroup(title: "\(element.role) Specific Attributes") {
                    ForEach(specificAttributes, id: \.name) { attr in
                        ElementPropertyRow(name: attr.name, value: attr.value)
                    }
                }
            }
            
            // Accessibility attributes
            ElementPropertyGroup(title: "Accessibility Attributes") {
                ElementPropertyRow(name: "Help Text", value: "This is a \(element.role.lowercased())")
                ElementPropertyRow(name: "Label", value: element.name)
                ElementPropertyRow(name: "Identifier", value: "com.example.\(element.role.lowercased()).\(element.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                ElementPropertyRow(name: "Required", value: "false")
                ElementPropertyRow(name: "Traits", value: getTraits(for: element))
            }
        }
        .padding(.horizontal)
    }
    
    // Returns role-specific attributes for various UI element types
    private func roleSpecificAttributes(for element: UIElement) -> [ElementProperty]? {
        switch element.role {
        case "Button":
            return [
                ElementProperty(name: "Button Type", value: "Push Button"),
                ElementProperty(name: "Button State", value: "Normal"),
                ElementProperty(name: "Alternative Text", value: element.name)
            ]
            
        case "TextField":
            return [
                ElementProperty(name: "Secure", value: "false"),
                ElementProperty(name: "Auto-correct", value: "true"),
                ElementProperty(name: "Spell Checking", value: "true"),
                ElementProperty(name: "Smart Quotes", value: "true")
            ]
            
        case "WebArea":
            return [
                ElementProperty(name: "URL", value: "https://example.com"),
                ElementProperty(name: "Loading", value: "false"),
                ElementProperty(name: "Can Go Back", value: "false"),
                ElementProperty(name: "Can Go Forward", value: "false")
            ]
            
        case "TabGroup":
            return [
                ElementProperty(name: "Selected Tab", value: "Tab 1"),
                ElementProperty(name: "Tab Count", value: "\(element.children.count)"),
                ElementProperty(name: "Tab Position", value: "Top")
            ]
            
        default:
            return nil
        }
    }
    
    // Returns accessibility traits for different element types
    private func getTraits(for element: UIElement) -> String {
        switch element.role {
        case "Button":
            return "Button"
        case "TextField", "TextArea":
            return "TextField"
        case "StaticText":
            return "StaticText"
        case "Image":
            return "Image"
        case "WebArea":
            return "Link"
        case "Menu", "MenuItem":
            return "Menu"
        case "TabGroup":
            return "TabGroup"
        case "Window":
            return "Window"
        default:
            return element.role
        }
    }
}

// Tab 3: Actions Tab
struct ElementActionsTab: View {
    let element: UIElement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Actions")
                .font(.headline)
                .padding(.horizontal)
            
            // Display available actions as buttons
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
            Text("Note: Actions in this demo will only be simulated and won't affect any real UI elements.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // Generate available actions based on element role
    private func availableActions(for element: UIElement) -> [(name: String, description: String)] {
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
            if element.hasChildren {
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
    
    // Get icon for action
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

struct BottomInfoPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.bottom, 4)
            
            HStack(alignment: .center) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility Explorer - Static Demo")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("All data is simulated - no actual accessibility APIs are called to prevent system freezes or high CPU usage.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ElementPropertyGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content
                .padding(.leading)
            
            Divider()
        }
        .padding(.horizontal)
    }
}

struct ElementPropertyRow: View {
    let name: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(name)
                .font(.body)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct EmptySelectionView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.left")
                .font(.system(size: 50))
                .padding()
            
            Text("Select an application from the sidebar")
                .font(.title2)
            
            Text("No actual accessibility APIs will be called")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }
}

#Preview {
    ContentView()
        .environmentObject(ExplorerViewModel())
}