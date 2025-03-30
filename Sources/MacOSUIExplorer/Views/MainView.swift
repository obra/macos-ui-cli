// ABOUTME: This file contains the main view for the SwiftUI Accessibility Explorer.
// ABOUTME: It defines the primary layout with navigation, element tree, and details panels.

import SwiftUI
import AppKit
import MacOSUICLILib

// Temporarily commenting out toolbars to get the build working
// We'll need to revisit the SwiftUI toolbar issues, but let's focus on the loading spinner issue first

/// The main view of the application with a three-panel layout
@available(macOS 13.0, *)
struct MainView: View {
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var elementTreeViewModel: ElementTreeViewModel
    
    @State private var selectedTab = 0
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - Applications List
            ApplicationSidebar()
                .frame(minWidth: 200)
                .navigationTitle("Applications")
                // Monitor the application selection state to detect and fix issues
                .onReceive(applicationViewModel.$selectedApplication) { selectedApp in
                    DebugLogger.shared.log("APP SELECTION STATE: selectedApp=\(selectedApp?.name ?? "nil")")
                    
                    // If we have an application selected but the element tree is in "No Application" state,
                    // try to force reload the application
                    if let app = selectedApp, 
                       elementTreeViewModel.rootElement == nil,
                       !elementTreeViewModel.isLoading {
                        DebugLogger.shared.log("WARNING: Application selected but element tree empty. Forcing reload.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            elementTreeViewModel.loadApplication(app)
                        }
                    }
                }
                // Toolbar temporarily commented out
                /*
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            applicationViewModel.refreshApplications()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Toggle("Safety Mode", isOn: Binding(
                                get: { SafetyMode.shared.isEnabled },
                                set: { SafetyMode.shared.isEnabled = $0 }
                            ))
                            
                            Button(action: {
                                // Display CPU usage
                                let usage = SafetyMode.shared.getCurrentCPUUsage()
                                let alert = NSAlert()
                                alert.messageText = "CPU Usage"
                                alert.informativeText = "Current CPU usage: \(String(format: "%.1f", usage))%"
                                alert.alertStyle = .informational
                                alert.addButton(withTitle: "OK")
                                alert.runModal()
                            }) {
                                Text("Check CPU Usage")
                            }
                        } label: {
                            Label("Options", systemImage: "gear")
                        }
                    }
                }
                */
        } content: {
            // Content - Element Tree
            ElementTreeView()
                .frame(minWidth: 250)
                .navigationTitle("Element Tree")
                // Add state observer to detect and fix UI state issues
                .onReceive(elementTreeViewModel.$rootElement.combineLatest(elementTreeViewModel.$selectedElement)) { root, selected in
                    // Log any state changes for debugging
                    DebugLogger.shared.log("ELEMENT TREE STATE: root=\(root != nil ? "non-nil" : "nil"), selected=\(selected != nil ? "non-nil" : "nil")")
                    
                    // Fix common issue: Root exists but selected is nil
                    if root != nil && selected == nil {
                        DebugLogger.shared.log("WARNING: Fixing common state issue - root exists but selectedElement is nil")
                        // Fix the issue by selecting the root element
                        DispatchQueue.main.async {
                            elementTreeViewModel.selectedElement = root
                        }
                    }
                }
                // Toolbar temporarily commented out
                /*
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            elementTreeViewModel.refreshCurrentView()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            elementTreeViewModel.navigateToParent()
                        }) {
                            Label("Go to Parent", systemImage: "arrow.up")
                        }
                        .disabled(elementTreeViewModel.selectedElement?.parent == nil)
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            elementTreeViewModel.navigateBack()
                        }) {
                            Label("Back", systemImage: "arrow.backward")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            elementTreeViewModel.navigateForward()
                        }) {
                            Label("Forward", systemImage: "arrow.forward")
                        }
                    }
                    
                    ToolbarItem(placement: .status) {
                        BreadcrumbView()
                    }
                }
                */
        } detail: {
            // Detail - Element Properties and Actions
            if let element = elementTreeViewModel.selectedElement {
                ElementDetailsView(viewModel: element)
                    .navigationTitle("Element Details")
                    // Toolbar temporarily commented out
                    /*
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                element.loadProperties()
                            }) {
                                Label("Refresh Properties", systemImage: "arrow.clockwise")
                            }
                        }
                        
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                elementTreeViewModel.toggleElementBoundsOverlay()
                            }) {
                                Label(
                                    elementTreeViewModel.showElementBounds ? "Hide Bounds" : "Show Bounds", 
                                    systemImage: elementTreeViewModel.showElementBounds ? "eye.slash" : "eye"
                                )
                            }
                        }
                    }
                    */
            } else {
                // Fallback for ContentUnavailableView
                VStack {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No Element Selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor))
            }
        }
        // No loading indicator - elements load asynchronously without blocking the UI
        // State monitoring - Check UI state and fix inconsistencies if needed
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            // Check the state of the main UI - does element tree match selected app?
            let hasApp = applicationViewModel.selectedApplication != nil
            let hasRoot = elementTreeViewModel.rootElement != nil
            let hasSelected = elementTreeViewModel.selectedElement != nil
            
            // Log the UI state for debugging
            DebugLogger.shared.log("UI STATE CHECK: hasApp=\(hasApp), hasRoot=\(hasRoot), hasSelected=\(hasSelected)")
            
            // If we have an app selected but no elements, try to load the app's elements
            if hasApp && !hasRoot {
                DebugLogger.shared.log("STATE MISMATCH: App selected but no elements, attempting to fix")
                if let app = applicationViewModel.selectedApplication {
                    DispatchQueue.main.async {
                        elementTreeViewModel.loadApplication(app)
                    }
                }
            }
            
            // If root exists but selected is nil, fix it
            if hasRoot && !hasSelected && elementTreeViewModel.rootElement != nil {
                DebugLogger.shared.log("STATE MISMATCH: Root exists but no element selected, fixing")
                DispatchQueue.main.async {
                    elementTreeViewModel.selectedElement = elementTreeViewModel.rootElement
                }
            }
        }
        .overlay(alignment: .center) {
            if let error = applicationViewModel.errorMessage ?? elementTreeViewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// Error message view
struct ErrorView: View {
    let message: String
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            VStack {
                Text("Error")
                    .font(.headline)
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                Button("Dismiss") {
                    withAnimation {
                        isVisible = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding()
            .transition(.opacity)
        }
    }
}

// LoadingIndicator has been completely removed - loading is now done asynchronously 
// without blocking the UI or showing a loading indicator

/// Breadcrumb navigation view
struct BreadcrumbView: View {
    @EnvironmentObject var elementTreeViewModel: ElementTreeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(elementTreeViewModel.selectionPath) { pathElement in
                    Button(action: {
                        elementTreeViewModel.selectElement(pathElement)
                    }) {
                        if pathElement.element.role == "AXWindow" {
                            Label(pathElement.element.title, systemImage: "window.casement")
                                .lineLimit(1)
                        } else {
                            Text(pathElement.displayName)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.borderless)
                    
                    if pathElement != elementTreeViewModel.selectionPath.last {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: 500)
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(macOS 13.0, *) {
            MainView()
                .environmentObject(ApplicationViewModel())
                .environmentObject(ElementTreeViewModel())
        } else {
            Text("Requires macOS 13.0 or later")
        }
    }
}
#endif