// ABOUTME: This file contains the tree view for displaying UI elements.
// ABOUTME: It shows a hierarchical view of UI elements that can be expanded and collapsed.

import SwiftUI
import MacOSUICLILib
import Combine

/// Tree view for displaying UI elements
struct ElementTreeView: View {
    @EnvironmentObject var viewModel: ElementTreeViewModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            if let rootElement = viewModel.rootElement {
                // Debug log when root element exists
                Text("UIDebug")
                    .font(.system(size: 1)) // Practically invisible
                    .foregroundColor(.clear)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onAppear {
                        DebugLogger.shared.log("TREE_VIEW: Has rootElement. Title=\(rootElement.element.title), Role=\(rootElement.element.role)")
                    }
                
                ScrollView {
                    elementTreeRecursive(rootElement)
                        .padding(.horizontal)
                }
                .searchable(text: $searchText, prompt: "Search Elements")
                // Use onReceive for the searchText
                .onReceive(Just($searchText.wrappedValue)) { value in
                    viewModel.searchText = value
                }
            } else {
                // Debug log for the no element case
                Text("UIDebug")
                    .font(.system(size: 1)) // Practically invisible
                    .foregroundColor(.clear)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onAppear {
                        DebugLogger.shared.log("TREE_VIEW: Missing rootElement. viewModel.rootElement is nil!")
                        DebugLogger.shared.log("TREE_VIEW: Has selectionPath? \(viewModel.selectionPath.count > 0 ? "Yes" : "No")")
                        DebugLogger.shared.log("TREE_VIEW: Has selectedElement? \(viewModel.selectedElement != nil ? "Yes" : "No")")
                        DebugLogger.shared.log("TREE_VIEW: Is Loading? \(viewModel.isLoading ? "Yes" : "No")")
                    }
                
                // Fallback for ContentUnavailableView
                VStack {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No Application Selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor))
            }
        }
    }
    
    /// Recursively render the element tree
    /// - Parameter element: The element to render
    /// - Returns: A view representing the element and its children
    func elementTreeRecursive(_ element: ElementViewModel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Element row with expand/collapse button
            ElementTreeRow(element: element)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectElement(element)
                }
                .background(viewModel.isSelected(element) ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(4)
            
            // Children (if expanded)
            if element.isExpanded {
                Group {
                    if element.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.leading, 24)
                    } else if element.children.isEmpty && element.element.hasChildren {
                        HStack {
                            Spacer()
                            Button("Load Children") {
                                // CRITICAL FIX: Prevent UI freezing by loading asynchronously
                                // Show a loading state immediately, then do the actual loading
                                DispatchQueue.main.async {
                                    // First set loading state to true to show the spinner
                                    element.isLoading = true
                                    
                                    // Then perform the actual loading after a tiny delay
                                    // to ensure UI updates first
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        element.loadChildren()
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.leading, 24)
                    } else {
                        ForEach(element.children) { child in
                            ElementTreeRecursiveView(element: child, viewModel: viewModel)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
}

/// Helper view to break the recursive cycle in SwiftUI
struct ElementTreeRecursiveView: View {
    let element: ElementViewModel
    @ObservedObject var viewModel: ElementTreeViewModel
    
    var body: some View {
        ElementTreeView().elementTreeRecursive(element)
    }
}

/// Row view for displaying an element in the tree
struct ElementTreeRow: View {
    @ObservedObject var element: ElementViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            // Expand/collapse button
            if element.element.hasChildren {
                Button(action: {
                    // CRITICAL FIX: First set expanded state, then perform child loading
                    // after a slight delay to avoid blocking the UI
                    withAnimation {
                        element.isExpanded.toggle()
                    }
                    
                    // Only load if expanding AND children are empty
                    if element.isExpanded && element.children.isEmpty {
                        // Add small delay before loading to let animation complete
                        // This prevents blocking the UI thread during animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            element.loadChildren()
                        }
                    }
                }) {
                    Image(systemName: element.isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
            }
            
            // Element icon
            elementIcon
                .foregroundColor(.primary)
                .frame(width: 20)
            
            // Element text
            VStack(alignment: .leading, spacing: 2) {
                Text(element.element.role)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                if !element.element.title.isEmpty {
                    Text(element.element.title)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if !element.element.roleDescription.isEmpty {
                    Text(element.element.roleDescription)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action indicator
            if !element.element.getAvailableActionsNoThrow().isEmpty {
                Image(systemName: "hand.tap")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Get an appropriate icon for the element type
    var elementIcon: some View {
        let iconName: String
        
        switch element.element.role {
        case "AXWindow":
            iconName = "window.casement"
        case "AXButton":
            iconName = "button.programmable"
        case "AXTextField", "AXTextArea":
            iconName = "text.field"
        case "AXCheckBox":
            iconName = "checkmark.square"
        case "AXRadioButton":
            iconName = "circle.circle"
        case "AXMenu", "AXMenuBar":
            iconName = "menubar.rectangle"
        case "AXMenuItem":
            iconName = "menubar.arrow.down"
        case "AXToolbar":
            iconName = "toolbar"
        case "AXList":
            iconName = "list.bullet"
        case "AXImage":
            iconName = "photo"
        case "AXScrollArea":
            iconName = "scroll"
        case "AXTabGroup":
            iconName = "tablecells"
        case "AXGroup":
            iconName = "square.on.square"
        default:
            iconName = "rectangle.dashed"
        }
        
        return Image(systemName: iconName)
    }
}

#if DEBUG
struct ElementTreeView_Previews: PreviewProvider {
    static var previews: some View {
        ElementTreeView()
            .environmentObject(ElementTreeViewModel())
            .frame(width: 300, height: 400)
    }
}
#endif