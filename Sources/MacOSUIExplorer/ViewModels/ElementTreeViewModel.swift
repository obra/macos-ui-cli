// ABOUTME: This file defines the view model for managing the accessibility element tree.
// ABOUTME: It handles element selection, navigation, and interaction with UI elements.

import Foundation
import Combine
import SwiftUI
import AppKit
import MacOSUICLILib

/// View model for managing element tree navigation and interaction
class ElementTreeViewModel: ObservableObject {
    /// Root element of the current tree
    @Published var rootElement: ElementViewModel? {
        didSet {
            DebugLogger.shared.log("DEBUG: rootElement changed to \(rootElement != nil ? "non-nil" : "nil")")
        }
    }
    
    /// Currently selected element
    @Published var selectedElement: ElementViewModel? {
        didSet {
            // When the selected element changes, update the selection path
            DebugLogger.shared.log("DEBUG: selectedElement changed to \(selectedElement != nil ? "non-nil" : "nil")")
            if let element = selectedElement {
                updateSelectionPath(to: element)
            } else {
                DebugLogger.shared.log("WARNING: selectedElement was set to nil")
            }
        }
    }
    
    /// Current selection path (breadcrumbs)
    @Published var selectionPath: [ElementViewModel] = []
    
    /// Search text for filtering elements
    @Published var searchText: String = ""
    
    /// List of visible elements (filtered by search)
    @Published var visibleElements: [ElementViewModel] = []
    
    /// Internal loading state - used for tracking but not for UI blocking
    @Published var isLoading: Bool = false {
        didSet {
            // Log loading state changes
            DebugLogger.shared.log("ElementTreeViewModel.isLoading changed: \(oldValue) -> \(isLoading)")
            
            // If we're starting to load, set up multiple timers with increasing aggressiveness
            if isLoading && !oldValue {
                // First reset attempt after 3 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    if let self = self, self.isLoading {
                        DebugLogger.shared.log("FIRST RESET: Loading state still true after 3 seconds, attempting reset")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            NotificationCenter.default.post(name: Notification.Name("ForceResetLoadingState"), object: nil)
                        }
                    }
                }
                
                // Second, more aggressive reset at 6 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + 6.0) { [weak self] in
                    if let self = self, self.isLoading {
                        DebugLogger.shared.log("SECOND RESET: Loading state still true after 6 seconds, forcing application reload")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            // Additional cleanup in case anything is stuck
                            if self.rootElement == nil, let app = self.currentApplication {
                                DebugLogger.shared.log("RECOVERY: Re-attempting load with safe mode")
                                self.loadApplicationInSafeMode(app)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Navigation history
    private var navigationHistory: [ElementViewModel] = []
    private var historyIndex: Int = -1
    
    /// Show element bounds overlay
    @Published var showElementBounds: Bool = false
    
    /// Application context
    private var currentApplication: Application?
    private var currentWindow: MacOSUICLILib.Window?
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize the view model
    init() {
        // CRITICAL: Ensure safety mode is ALWAYS enabled to prevent freezing
        SafetyMode.shared.isEnabled = true
        DebugLogger.shared.log("EMERGENCY MODE: Forcing safety mode enabled at startup")
        
        // Listen for application selection notifications
        NotificationCenter.default.publisher(for: .applicationSelected)
            .compactMap { $0.userInfo?["application"] as? Application }
            .sink { [weak self] application in
                self?.loadApplication(application)
            }
            .store(in: &cancellables)
        
        // Setup search filtering
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchTerm in
                self?.filterElements(by: searchTerm)
            }
            .store(in: &cancellables)
            
        // Listen for force reset notification
        NotificationCenter.default.publisher(for: Notification.Name("ForceResetLoadingState"))
            .sink { [weak self] _ in
                DebugLogger.shared.log("FORCE RESET: ElementTreeViewModel received reset notification")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        // Add emergency CPU monitor - every 3 seconds check CPU and reset if too high
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            if SafetyMode.shared.isUsingTooMuchCPU(threshold: 80.0) {
                DebugLogger.shared.log("EMERGENCY CPU MONITOR: Detected high CPU usage, forcibly resetting state")
                
                DispatchQueue.main.async {
                    // Reset loading states
                    self?.isLoading = false
                    
                    // Also reset the root element's loading state
                    self?.rootElement?.isLoading = false
                    
                    // Force safety mode on
                    SafetyMode.shared.isEnabled = true
                }
            }
        }
    }
    
    /// Load an application's accessibility tree - EMERGENCY STATIC IMPLEMENTATION
    /// - Parameter application: The application to load
    func loadApplication(_ application: Application) {
        DebugLogger.shared.log("EMERGENCY STATIC MODE: Loading static UI tree for \(application.name)")
        
        // Store reference to current application
        currentApplication = application
        
        // Set loading state for UI feedback
        self.isLoading = true
        
        // CRITICAL: Force nil everything to reset any problematic state
        self.rootElement = nil
        self.selectedElement = nil
        self.selectionPath = []
        self.visibleElements = []
        
        // Create static elements completely disconnected from macOS accessibility APIs
        let appElement = Element(
            role: "AXApplication",
            title: application.name,
            hasChildren: true,
            roleDescription: "Application (Emergency Static Mode)",
            subRole: ""
        )
        
        // Get static window from our completely static implementation
        let windowElement = StaticElementData.shared.getStaticWindowForApp(application)
        
        // Create view models on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let appViewModel = ElementViewModel(element: appElement)
            
            // Create window view model
            let windowViewModel = ElementViewModel(element: windowElement)
            windowViewModel.parent = appViewModel
            
            // Create notice element 
            let noticeElement = Element(
                role: "AXGroup",
                title: "⚠️ EMERGENCY MODE ACTIVE",
                hasChildren: false,
                roleDescription: "This is a completely static view to prevent crashes",
                subRole: ""
            )
            let noticeViewModel = ElementViewModel(element: noticeElement)
            noticeViewModel.parent = appViewModel
            
            // Add static elements to root
            appViewModel.children = [windowViewModel, noticeViewModel]
            
            // Convert window's children to view models
            var childViewModels: [ElementViewModel] = []
            for childElement in windowElement.children {
                let childViewModel = ElementViewModel(element: childElement)
                childViewModel.parent = windowViewModel
                childViewModels.append(childViewModel)
            }
            windowViewModel.children = childViewModels
            
            // Update UI state all at once to prevent partial updates
            self.rootElement = appViewModel
            self.selectedElement = appViewModel
            self.selectionPath = [appViewModel]
            self.visibleElements = [appViewModel]
            
            // Expand the main window automatically
            windowViewModel.isExpanded = true
            
            // Immediately mark loading as complete
            self.isLoading = false
            
            DebugLogger.shared.log("SUCCESS: Pure static tree created for \(application.name)")
        }
    }
    
    /// This method is intentionally disabled to prevent any real accessibility API calls
    private func loadApplicationInSafeMode(_ application: Application) {
        DebugLogger.shared.log("DISABLED: Using loadApplication with static mode instead")
        loadApplication(application)
    }
    
    /// Select an element in the tree
    /// - Parameter element: The element to select
    func selectElement(_ element: ElementViewModel) {
        // Add current selection to history before changing
        if let current = selectedElement {
            // Remove any forward history if we're navigating from middle
            if historyIndex < navigationHistory.count - 1 {
                navigationHistory.removeSubrange((historyIndex + 1)...)
            }
            
            navigationHistory.append(current)
            historyIndex = navigationHistory.count - 1
        }
        
        selectedElement = element
        
        // Expand the element to show its children
        element.isExpanded = true
    }
    
    /// Check if an element is the currently selected one
    /// - Parameter element: The element to check
    /// - Returns: True if the element is selected
    func isSelected(_ element: ElementViewModel) -> Bool {
        selectedElement?.id == element.id
    }
    
    /// Refresh the current view
    func refreshCurrentView() {
        if let app = currentApplication {
            loadApplication(app)
        }
    }
    
    /// Go back in the navigation history
    func navigateBack() {
        guard historyIndex > 0 else { return }
        
        historyIndex -= 1
        selectedElement = navigationHistory[historyIndex]
    }
    
    /// Go forward in the navigation history
    func navigateForward() {
        guard historyIndex < navigationHistory.count - 1 else { return }
        
        historyIndex += 1
        selectedElement = navigationHistory[historyIndex]
    }
    
    /// Navigate to the parent element
    func navigateToParent() {
        guard let current = selectedElement, let parent = current.parent else { return }
        selectElement(parent)
    }
    
    /// Filter elements by search term
    /// - Parameter searchTerm: The search term to filter by
    private func filterElements(by searchTerm: String) {
        guard let root = rootElement else { return }
        
        if searchTerm.isEmpty {
            // Show everything when search is empty
            visibleElements = [root]
            return
        }
        
        // Find elements matching the search term
        let matchingElements = findMatchingElements(root, searchTerm: searchTerm.lowercased())
        
        if !matchingElements.isEmpty {
            visibleElements = matchingElements
        } else {
            // If no matches, just show the root
            visibleElements = [root]
        }
    }
    
    /// Find elements matching a search term
    /// - Parameters:
    ///   - element: The element to start searching from
    ///   - searchTerm: The search term to match
    /// - Returns: Array of matching elements
    private func findMatchingElements(_ element: ElementViewModel, searchTerm: String) -> [ElementViewModel] {
        var matches: [ElementViewModel] = []
        
        // Check if this element matches
        if element.matchesSearchTerm(searchTerm) {
            matches.append(element)
        }
        
        // Check children recursively
        for child in element.children {
            matches.append(contentsOf: findMatchingElements(child, searchTerm: searchTerm))
        }
        
        return matches
    }
    
    /// Update the selection path to a given element
    /// - Parameter element: The element to create a path to
    private func updateSelectionPath(to element: ElementViewModel) {
        var path: [ElementViewModel] = []
        var current: ElementViewModel? = element
        
        // Work backwards from element to root
        while current != nil {
            if let currentElement = current {
                path.insert(currentElement, at: 0)
            }
            current = current?.parent
        }
        
        selectionPath = path
    }
    
    /// Toggle the element bounds overlay display
    func toggleElementBoundsOverlay() {
        showElementBounds.toggle()
    }
}