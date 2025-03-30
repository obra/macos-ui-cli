// ABOUTME: This file defines the view model for managing applications in the UI Explorer.
// ABOUTME: It handles loading, selecting, and switching between applications.

import Foundation
import Combine
import AppKit
import MacOSUICLILib

/// View model for managing applications in the UI Explorer
class ApplicationViewModel: ObservableObject {
    /// List of available applications
    @Published var applications: [Application] = []
    
    /// Currently selected application
    @Published var selectedApplication: Application? {
        didSet {
            DebugLogger.shared.log("DEBUG: selectedApplication changed to \(selectedApplication?.name ?? "nil")")
            if let app = selectedApplication {
                DebugLogger.shared.log("DEBUG: Posting notification for selected application: \(app.name)")
                NotificationCenter.default.post(
                    name: .applicationSelected,
                    object: nil,
                    userInfo: ["application": app]
                )
            }
        }
    }
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Internal loading state - used for tracking but not for UI blocking
    @Published var isLoading: Bool = false {
        didSet {
            // Log loading state changes for debugging
            DebugLogger.shared.log("ApplicationViewModel.isLoading changed: \(oldValue) -> \(isLoading)")
            
            // Add failsafe timer for loading state
            if isLoading && !oldValue {
                DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) { [weak self] in
                    guard let self = self else { return }
                    
                    if self.isLoading {
                        DebugLogger.shared.log("WARNING: ApplicationViewModel loading state stuck at true for > 10 seconds")
                        
                        // Force reset immediately instead of waiting
                        DispatchQueue.main.async {
                            DebugLogger.shared.log("CRITICAL: Forcing ApplicationViewModel.isLoading reset to false")
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    /// Recent applications for quick access
    @Published var recentApplications: [Application] = []
    
    /// Flag to prevent multiple simultaneous refreshes
    private var isRefreshing = false
    
    /// Loading operation queue to ensure only one operation runs at a time
    private let loadingQueue = DispatchQueue(label: "com.macos-ui-cli.applicationLoading")
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize the view model
    init() {
        // Load recent applications from user defaults
        loadRecentApplications()
        
        // Listen for force reset notification
        NotificationCenter.default.publisher(for: Notification.Name("ForceResetLoadingState"))
            .sink { [weak self] _ in
                DebugLogger.shared.log("FORCE RESET: ApplicationViewModel received reset notification")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    /// Refresh the list of running applications - REPLACED WITH PURE STATIC IMPLEMENTATION
    /// to completely bypass any real macOS accessibility API calls
    func refreshApplications() {
        DebugLogger.shared.log("🚨 EMERGENCY STATIC MODE: Providing 100% static application list")
        
        // Immediately show loading state for UI feedback
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            
            // Create totally static applications
            var staticApps: [Application] = []
            
            // Use the static element data class to get apps
            staticApps = StaticElementData.shared.getStaticApplications()
            
            // If we still couldn't get any apps after all that, make one last attempt
            if staticApps.isEmpty {
                DebugLogger.shared.log("CRITICAL: No applications found. Creating fallback application")
                
                // Try to get any application
                let allApps = ApplicationManager.getAllApplicationsNoThrow()
                if !allApps.isEmpty {
                    DebugLogger.shared.log("Got application from system: \(allApps[0].name)")
                    staticApps = [allApps[0]]
                }
            }
            
            // Update applications list
            self.applications = staticApps
            self.isLoading = false
            
            DebugLogger.shared.log("📱 Updated with \(staticApps.count) static applications")
            
            // Auto-select TextEdit or first app
            if self.selectedApplication == nil, !staticApps.isEmpty {
                if let textEdit = staticApps.first(where: { $0.name.contains("TextEdit") }) {
                    DebugLogger.shared.log("Auto-selecting TextEdit application")
                    self.selectApplication(textEdit)
                } else {
                    DebugLogger.shared.log("Auto-selecting first application: \(staticApps[0].name)")
                    self.selectApplication(staticApps[0])
                }
            }
        }
    }
    
    /// Select an application and load its windows - REPLACED WITH STATIC IMPLEMENTATION
    /// to prevent any real macOS accessibility API calls
    /// - Parameter application: The application to select
    func selectApplication(_ application: Application) {
        DebugLogger.shared.log("EMERGENCY STATIC MODE: Selecting application: \(application.name)")
        
        // Immediately update the application selection on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Set the selected application
            self.selectedApplication = application
            DebugLogger.shared.log("Static application selected: \(application.name)")
            
            // Update recent applications list
            if !self.recentApplications.contains(where: { $0.name == application.name }) {
                self.recentApplications.insert(application, at: 0)
                
                // Keep only the last 3 recent applications
                if self.recentApplications.count > 3 {
                    self.recentApplications.removeLast()
                }
            }
            
            // Post notification that will trigger element tree loading
            NotificationCenter.default.post(
                name: .applicationSelected,
                object: nil,
                userInfo: ["application": application]
            )
        }
    }
    
    /// Get the focused application - REPLACED WITH STATIC IMPLEMENTATION
    /// to prevent any real macOS accessibility API calls
    func selectFocusedApplication() {
        DebugLogger.shared.log("EMERGENCY STATIC MODE: Selecting static focused application")
        
        isLoading = true
        
        // Just use a static app instead of trying to detect the real focused app
        let staticApps = StaticElementData.shared.getStaticApplications()
        
        // Use TextEdit as our fake "focused" app
        if let textEdit = staticApps.first(where: { $0.name == "TextEdit" }) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.selectApplication(textEdit)
                self.isLoading = false
            }
        } else if !staticApps.isEmpty {
            // Fall back to first app if TextEdit not found
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.selectApplication(staticApps[0])
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "No applications available"
                self.isLoading = false
            }
        }
    }
    
    /// Load recently used applications from UserDefaults
    private func loadRecentApplications() {
        // In a real implementation, this would load from UserDefaults
        // For now, we'll use an empty list since we can't save/load Application objects directly
        recentApplications = []
    }
    
    /// Save recently used applications to UserDefaults
    private func saveRecentApplications() {
        // In a real implementation, this would save to UserDefaults
        // For now, this is a placeholder since we can't save Application objects directly
    }
}

// Define notification name constants
extension Notification.Name {
    static let applicationSelected = Notification.Name("applicationSelected")
}