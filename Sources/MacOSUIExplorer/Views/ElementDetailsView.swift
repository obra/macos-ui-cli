// ABOUTME: This file contains the details view for displaying element properties and actions.
// ABOUTME: It shows properties, available actions, and a visualization of the element.

import SwiftUI
import MacOSUICLILib

/// Details view for displaying element information and actions
struct ElementDetailsView: View {
    @ObservedObject var viewModel: ElementViewModel
    @State private var selectedCategory: ElementProperty.PropertyCategory = .general
    
    var body: some View {
        // Debug logging - add invisible element that logs details
        Text("UIDebug")
            .font(.system(size: 1)) // Practically invisible
            .foregroundColor(.clear)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onAppear {
                DebugLogger.shared.log("DETAILS_VIEW: Showing element: role=\(viewModel.element.role), title=\(viewModel.element.title)")
                DebugLogger.shared.log("DETAILS_VIEW: Element has \(viewModel.properties.count) properties and \(viewModel.actions.count) actions")
                if let parentTitle = viewModel.parent?.element.title {
                    DebugLogger.shared.log("DETAILS_VIEW: Element has parent: \(parentTitle)")
                } else {
                    DebugLogger.shared.log("DETAILS_VIEW: Element has no parent")
                }
            }

        VStack(spacing: 0) {
            // Tab selection for property categories
            Picker("Category", selection: $selectedCategory) {
                ForEach(ElementProperty.PropertyCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Properties list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Display properties for the selected category
                    ForEach(filteredProperties) { property in
                        PropertyRow(property: property)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Actions section
            ActionsView(viewModel: viewModel)
                .frame(height: 150)
            
            Divider()
            
            // Element visualization
            ElementVisualizationView(element: viewModel.element)
                .frame(height: 150)
        }
        .alert(
            "Error", 
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: {
                Button("OK") { viewModel.errorMessage = nil }
            },
            message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        )
    }
    
    /// Filter properties by the selected category
    var filteredProperties: [ElementProperty] {
        viewModel.properties.filter { $0.category == selectedCategory }
    }
}

/// Row view for displaying a property
struct PropertyRow: View {
    let property: ElementProperty
    @State private var isCopied = false
    
    var body: some View {
        HStack(alignment: .top) {
            // Property name
            Text(property.name)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 150, alignment: .leading)
                .lineLimit(1)
                .help(property.name)
            
            Divider()
            
            // Property value
            Group {
                if property.value.contains("\n") {
                    Text(property.value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(property.value)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .help(property.value)
            
            // Copy button
            Button(action: {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(property.value, forType: .string)
                #endif
                
                // Show feedback
                withAnimation {
                    isCopied = true
                }
                
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isCopied = false
                    }
                }
            }) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundColor(isCopied ? .green : .primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(4)
        .padding(.vertical, 2)
    }
}

/// View for displaying and executing element actions
struct ActionsView: View {
    @ObservedObject var viewModel: ElementViewModel
    @State private var isExecutingAction = false
    @State private var actionTask: Task<Void, Never>?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Available Actions")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if viewModel.actions.isEmpty {
                Text("No actions available for this element")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.actions) { action in
                            Button(action: {
                                executeAction(action)
                            }) {
                                Label(action.name, systemImage: "hand.tap")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isExecutingAction)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            if isExecutingAction {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Executing action...")
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Execute an action asynchronously
    /// - Parameter action: The action to execute
    private func executeAction(_ action: ElementAction) {
        isExecutingAction = true
        
        // Cancel any existing task
        actionTask?.cancel()
        
        // Create a new task
        actionTask = Task {
            do {
                try await action.action()
                
                // Update on main thread
                await MainActor.run {
                    isExecutingAction = false
                }
            } catch {
                await MainActor.run {
                    isExecutingAction = false
                }
            }
        }
    }
}

/// View for visualizing an element's position and size
struct ElementVisualizationView: View {
    let element: Element
    
    var body: some View {
        VStack {
            Text("Element Visualization")
                .font(.headline)
                .padding(.top, 8)
            
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .border(Color.secondary.opacity(0.3), width: 1)
                    
                    // Element visualization
                    if let frameValue = element.getAttributesNoThrow()["AXFrame"] as? CGRect, 
                       frameValue != .zero {
                        // Scale down to fit in our view
                        let screenBounds = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
                        let scaleX = geometry.size.width / screenBounds.width
                        let scaleY = geometry.size.height / screenBounds.height
                        let scale = min(scaleX, scaleY) * 0.9
                        
                        let scaledX = frameValue.origin.x * scale
                        let scaledY = frameValue.origin.y * scale
                        let scaledWidth = frameValue.width * scale
                        let scaledHeight = frameValue.height * scale
                        
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.3))
                            .border(Color.accentColor, width: 2)
                            .frame(width: scaledWidth, height: scaledHeight)
                            .position(x: geometry.size.width / 2 - (screenBounds.width * scale / 2) + scaledX + scaledWidth / 2,
                                      y: geometry.size.height / 2 - (screenBounds.height * scale / 2) + scaledY + scaledHeight / 2)
                    } else {
                        Text("No position information available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

#if DEBUG
struct ElementDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ElementViewModel for preview
        let mockViewModel = ElementViewModel()
        ElementDetailsView(viewModel: mockViewModel)
    }
}
#endif

// Extension for preview support
extension ElementViewModel {
    /// Initialize with mock data for previews
    convenience init() {
        self.init(element: Element(
            role: "AXButton",
            title: "OK Button",
            hasChildren: false,
            roleDescription: "A button that confirms the action",
            subRole: ""
        ))
        
        // Add mock properties
        self.properties = [
            ElementProperty(name: "Role", value: "AXButton"),
            ElementProperty(name: "Title", value: "OK Button"),
            ElementProperty(name: "Description", value: "A button that confirms the action")
        ]
        
        // Add mock actions
        self.actions = [
            ElementAction(name: "press") { 
                // No-op for preview
            },
            ElementAction(name: "focus") { 
                // No-op for preview
            }
        ]
    }
}