// ABOUTME: This file implements safety features to prevent high CPU usage and crashes.
// ABOUTME: It handles potentially problematic applications with fallback strategies.

import Foundation
import MacOSUICLILib

/// Class to handle safety mode for problematic applications
class SafetyMode {
    /// Shared instance for singleton access
    static let shared = SafetyMode()
    
    /// List of application names known to cause high CPU usage
    private var problematicAppNames: [String] = [
        "Safari",
        "Finder",
        "Mail",
        "Photos",
        "Music"
    ]
    
    /// Whether safety mode is enabled
    private var _enabled: Bool = true
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Initialize with safety mode on by default
        DebugLogger.shared.log("SafetyMode initialized with safety mode enabled")
    }
    
    /// Whether safety mode is currently enabled
    var isEnabled: Bool {
        get {
            return _enabled
        }
        set {
            DebugLogger.shared.log("Safety mode \(newValue ? "enabled" : "disabled")")
            _enabled = newValue
        }
    }
    
    /// Check if an application is known to be problematic
    /// - Parameter appName: The name of the application
    /// - Returns: True if the application is known to be problematic
    func isProblematicApp(_ appName: String) -> Bool {
        guard isEnabled else { return false }
        
        let lowercasedName = appName.lowercased()
        return problematicAppNames.contains { name in
            lowercasedName.contains(name.lowercased())
        }
    }
    
    /// Creates a simplified element tree for an application
    /// - Parameter application: The application to create a simplified tree for
    /// - Returns: A root element with a simplified tree
    func createSimplifiedElementTree(for application: Application) -> Element {
        DebugLogger.shared.log("Creating simplified element tree for \(application.name) in safety mode")
        
        // Create a simple root element
        let safeRootElement = Element(
            role: "AXApplication",
            title: application.name,
            hasChildren: true,
            roleDescription: "Application (Ultra-Safe Mode)",
            subRole: ""
        )
        
        // Create a simple window element - this uses just one level of nesting
        let safeWindowElement = Element(
            role: "AXWindow",
            title: "Main Window",
            hasChildren: true,
            roleDescription: "Main window",
            subRole: ""
        )
        
        // Create a simple info element
        let safeInfoElement = Element(
            role: "AXGroup",
            title: "Safety Mode Active",
            hasChildren: false,
            roleDescription: "Safe mode prevents CPU spikes and freezing",
            subRole: ""
        )
        
        // Create a detailed explanation element
        let safeExplanationElement = Element(
            role: "AXStaticText",
            title: "Click the arrow by 'Main Window' to see common UI elements. Use this simplified view to prevent app freezing.",
            hasChildren: false,
            roleDescription: "Safe mode explanation",
            subRole: ""
        )
        
        // Create an instruction element
        let instructionsElement = Element(
            role: "AXGroup",
            title: "Manual Element Exploration",
            hasChildren: false,
            roleDescription: "Instructions for safe exploration",
            subRole: ""
        )
        
        // Create some dummy UI elements based on the application type
        let commonElements = createCommonElementsFor(application: application)
        
        // Connect the elements
        safeRootElement.addChild(safeWindowElement)
        
        // Add an option to explore more interactively
        let exploreModeElement = Element(
            role: "AXButton",
            title: "Explore Elements",
            hasChildren: false,
            roleDescription: "Explore UI elements interactively (click to expand elements in tree)",
            subRole: ""
        )
        
        // Add the key elements to the root - simplified hierarchy
        safeRootElement.addChild(safeInfoElement)
        safeRootElement.addChild(instructionsElement)
        safeRootElement.addChild(exploreModeElement)
        
        // Add explanation to the window
        safeWindowElement.addChild(safeExplanationElement)
        
        // Add common elements directly to window to avoid too much nesting
        for element in commonElements {
            safeWindowElement.addChild(element)
        }
        
        return safeRootElement
    }
    
    /// Creates common UI elements for different application types
    /// - Parameter application: The application to create elements for
    /// - Returns: Array of common elements
    private func createCommonElementsFor(application: Application) -> [Element] {
        let appName = application.name.lowercased()
        var elements: [Element] = []
        
        // For Safari
        if appName.contains("safari") {
            elements.append(Element(
                role: "AXToolbar",
                title: "Toolbar",
                hasChildren: true,
                roleDescription: "toolbar",
                subRole: ""
            ))
            
            elements.append(Element(
                role: "AXTextField",
                title: "Address Bar",
                hasChildren: false,
                roleDescription: "address field",
                subRole: ""
            ))
            
            elements.append(Element(
                role: "AXGroup",
                title: "Web Content",
                hasChildren: true,
                roleDescription: "web content",
                subRole: ""
            ))
        }
        // For Finder
        else if appName.contains("finder") {
            elements.append(Element(
                role: "AXToolbar",
                title: "Toolbar",
                hasChildren: true,
                roleDescription: "toolbar",
                subRole: ""
            ))
            
            elements.append(Element(
                role: "AXSplitGroup",
                title: "Sidebar",
                hasChildren: true,
                roleDescription: "sidebar",
                subRole: ""
            ))
            
            elements.append(Element(
                role: "AXTable",
                title: "File List",
                hasChildren: true,
                roleDescription: "file list",
                subRole: ""
            ))
        }
        // For other applications
        else {
            elements.append(Element(
                role: "AXToolbar",
                title: "Toolbar",
                hasChildren: true,
                roleDescription: "toolbar",
                subRole: ""
            ))
            
            elements.append(Element(
                role: "AXGroup",
                title: "Content Area",
                hasChildren: true,
                roleDescription: "content area",
                subRole: ""
            ))
        }
        
        return elements
    }
    
    /// Monitor CPU usage and detect high usage situations
    /// - Returns: Current CPU usage percentage of the process
    func getCurrentCPUUsage() -> Double {
        var cpuUsage = 0.0
        
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
                cpuUsage = Double(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                
                // Log if CPU usage is high
                if cpuUsage > 50.0 {
                    DebugLogger.shared.log("High CPU usage detected: \(cpuUsage)%")
                }
            }
        } catch {
            DebugLogger.shared.log("Error getting CPU usage: \(error)")
        }
        
        return cpuUsage
    }
    
    /// Check if the process is using too much CPU
    /// - Parameter threshold: The threshold percentage (default 80%)
    /// - Returns: True if CPU usage exceeds the threshold
    func isUsingTooMuchCPU(threshold: Double = 80.0) -> Bool {
        let usage = getCurrentCPUUsage()
        return usage > threshold
    }
}