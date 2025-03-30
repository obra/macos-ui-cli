// ABOUTME: This file contains the main entry point for the SwiftUI Accessibility Explorer application.
// ABOUTME: It sets up the environment and launches the SwiftUI app.

import Foundation
import AppKit
import SwiftUI
import MacOSUICLILib

// Initialize the debug logger
_ = DebugLogger.shared
DebugLogger.shared.log("Application starting")

// Set up global exception handler to catch any unhandled exceptions
NSSetUncaughtExceptionHandler { exception in
    DebugLogger.shared.log("FATAL ERROR: Uncaught exception: \(exception.name) - \(exception.reason ?? "No reason")")
    DebugLogger.shared.log("Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
}

// Check if we're running from an app bundle
let isRunningFromAppBundle = Bundle.main.bundleIdentifier != nil
DebugLogger.shared.log("Is running from app bundle: \(isRunningFromAppBundle)")

// Check for app wrapper presence
let appWrapperPath = "/Applications/MacOSUIExplorer.app"
let appWrapperExists = FileManager.default.fileExists(atPath: appWrapperPath)
DebugLogger.shared.log("App wrapper exists at \(appWrapperPath): \(appWrapperExists)")

// Function to create a more robust app wrapper
func createAppWrapper(at path: String, executable: String) -> Bool {
    DebugLogger.shared.log("Creating app wrapper at \(path) for executable \(executable)")
    
    // Create a proper app bundle structure instead of just using osacompile
    let appContentsPath = "\(path)/Contents"
    let appMacOSPath = "\(appContentsPath)/MacOS"
    let appResourcesPath = "\(appContentsPath)/Resources"
    
    // Create the directory structure
    do {
        try FileManager.default.createDirectory(atPath: appMacOSPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: appResourcesPath, withIntermediateDirectories: true)
    } catch {
        DebugLogger.shared.log("Error creating app directory structure: \(error)")
        return false
    }
    
    // Create Info.plist with accessibility usage description
    let infoPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>com.macos-ui-cli.explorer</string>
        <key>CFBundleName</key>
        <string>MacOSUIExplorer</string>
        <key>CFBundleDisplayName</key>
        <string>macOS UI Explorer</string>
        <key>CFBundleVersion</key>
        <string>1.0</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleExecutable</key>
        <string>MacOSUIExplorer</string>
        <key>NSPrincipalClass</key>
        <string>NSApplication</string>
        <key>NSAccessibilityUsageDescription</key>
        <string>This app needs accessibility permissions to analyze and interact with user interface elements in other applications.</string>
        <key>LSMinimumSystemVersion</key>
        <string>10.13</string>
        <key>LSApplicationCategoryType</key>
        <string>public.app-category.developer-tools</string>
        <key>NSHighResolutionCapable</key>
        <true/>
    </dict>
    </plist>
    """
    
    do {
        // Write Info.plist
        try infoPlist.write(toFile: "\(appContentsPath)/Info.plist", atomically: true, encoding: .utf8)
        
        // Copy executable to app bundle
        let appExecutablePath = "\(appMacOSPath)/MacOSUIExplorer"
        try FileManager.default.copyItem(atPath: executable, toPath: appExecutablePath)
        
        // Make executable
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "chmod +x \"\(appExecutablePath)\""]
        try task.run()
        task.waitUntilExit()
        
        // Create a simple icon (empty for now)
        let iconTask = Process()
        iconTask.launchPath = "/bin/sh"
        iconTask.arguments = ["-c", "touch \"\(appResourcesPath)/AppIcon.icns\""]
        try iconTask.run()
        iconTask.waitUntilExit()
        
        DebugLogger.shared.log("Successfully created app wrapper with proper structure")
        return true
    } catch {
        DebugLogger.shared.log("Error finalizing app wrapper: \(error)")
        return false
    }
}

// If we're not running from an app bundle and no wrapper exists, create one
if !isRunningFromAppBundle {
    DebugLogger.shared.log("Not running from app bundle - checking if wrapper needed")
    
    // Check if we NEED the app wrapper by verifying permissions
    let permissionStatus = AccessibilityPermissions.checkPermission()
    if permissionStatus != .granted || !appWrapperExists {
        DebugLogger.shared.log("App wrapper needed. Permission status: \(permissionStatus), wrapper exists: \(appWrapperExists)")
        
        let alert = NSAlert()
        alert.messageText = "Create App Wrapper"
        alert.informativeText = """
        This application needs to be run from an app bundle to get proper accessibility permissions.
        
        Current permission status: \(permissionStatus)
        
        Would you like to create an app wrapper at \(appWrapperPath)?
        
        If you already granted permissions to the app wrapper, select "Open App Wrapper".
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: appWrapperExists ? "Open App Wrapper" : "Create App Wrapper")
        alert.addButton(withTitle: "Continue Anyway")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            DebugLogger.shared.log("User chose to \(appWrapperExists ? "open" : "create") app wrapper")
            
            // Get path to current executable
            let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
            DebugLogger.shared.log("Executable path: \(executablePath)")
            
            var wrapperCreatedOrExists = false
            
            // Create the app wrapper if it doesn't exist
            if !appWrapperExists {
                wrapperCreatedOrExists = createAppWrapper(at: appWrapperPath, executable: executablePath)
            } else {
                wrapperCreatedOrExists = true
            }
            
            if wrapperCreatedOrExists {
                DebugLogger.shared.log("App wrapper is available")
                
                // Open the app wrapper and show system preferences for permissions
                let wrapperAlert = NSAlert()
                wrapperAlert.messageText = appWrapperExists ? "App Wrapper Available" : "App Wrapper Created"
                wrapperAlert.informativeText = """
                You must grant accessibility permissions to the app wrapper in System Settings.
                
                After clicking "Open App Wrapper", the System Settings accessibility panel will open.
                
                Please follow these steps:
                1. Click the lock icon to make changes (if needed)
                2. Find and check "MacOSUIExplorer" in the list
                3. If it's already checked, uncheck and recheck it
                4. Close System Settings
                5. The app wrapper will launch automatically
                """
                wrapperAlert.alertStyle = .informational
                wrapperAlert.addButton(withTitle: "Open App Wrapper & Settings")
                wrapperAlert.addButton(withTitle: "Continue Anyway")
                
                let wrapperResponse = wrapperAlert.runModal()
                if wrapperResponse == .alertFirstButtonReturn {
                    DebugLogger.shared.log("Opening app wrapper and accessibility settings")
                    
                    // First open accessibility settings
                    AccessibilityPermissions.openAccessibilityPreferences()
                    
                    // Wait a moment for settings to open
                    Thread.sleep(forTimeInterval: 1.0)
                    
                    // Then open the app wrapper
                    NSWorkspace.shared.open(URL(fileURLWithPath: appWrapperPath))
                    
                    // Exit this instance
                    exit(0)
                }
            } else {
                DebugLogger.shared.log("Failed to create app wrapper")
                
                // Show error message
                let errorAlert = NSAlert()
                errorAlert.messageText = "Error Creating App Wrapper"
                errorAlert.informativeText = "Could not create the app wrapper. Please make sure you have write permissions to /Applications."
                errorAlert.alertStyle = .critical
                errorAlert.addButton(withTitle: "Continue Anyway")
                errorAlert.addButton(withTitle: "Quit")
                
                if errorAlert.runModal() == .alertSecondButtonReturn {
                    exit(1)
                }
            }
        } else if response == .alertThirdButtonReturn {
            DebugLogger.shared.log("User chose to quit")
            exit(0)
        }
    }
} else {
    DebugLogger.shared.log("Running from app bundle - no wrapper needed")
}

// Check accessibility permissions on startup
DebugLogger.shared.log("Checking accessibility permissions")
let permissionStatus = AccessibilityPermissions.checkPermission()
DebugLogger.shared.log("Permission status: \(permissionStatus)")

if permissionStatus != .granted {
    DebugLogger.shared.log("Accessibility permissions required, requesting")
    let result = AccessibilityPermissions.requestPermission()
    DebugLogger.shared.log("Permission request result: \(result)")
    
    if result != .granted {
        DebugLogger.shared.log("Permission request denied")
        print("Accessibility permissions not granted")
        print("Please enable accessibility permissions in System Settings > Privacy & Security > Accessibility")
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "This app needs accessibility permissions to inspect UI elements of other applications. Please enable permissions in System Settings.\n\nIf you're running from Terminal, try using the app wrapper at: \(appWrapperPath)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Continue Anyway")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            DebugLogger.shared.log("Opening accessibility preferences")
            AccessibilityPermissions.openAccessibilityPreferences()
            
            // Wait a bit for the user to add permissions
            Thread.sleep(forTimeInterval: 3.0)
            
            // Check one more time
            let finalCheck = AccessibilityPermissions.checkPermission()
            DebugLogger.shared.log("Final permission check: \(finalCheck)")
            
            if finalCheck != .granted {
                DebugLogger.shared.log("Still no permissions, exiting")
                exit(1)
            }
        } else if response == .alertThirdButtonReturn {
            DebugLogger.shared.log("User chose to quit")
            exit(1)
        } else {
            DebugLogger.shared.log("User chose to continue anyway")
        }
    } else {
        DebugLogger.shared.log("Permission granted after request")
    }
} else {
    DebugLogger.shared.log("Accessibility permissions already granted")
}

// Launch the SwiftUI application
import SwiftUI

DebugLogger.shared.log("Creating application instance")
let app = MacOSUIExplorerApp()

// Keep a strong reference to the app delegate
DebugLogger.shared.log("Creating application delegate")
let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
DebugLogger.shared.log("Starting NSApplicationMain")
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

// App delegate to handle application lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLogger.shared.log("Application did finish launching")
        
        // Create the SwiftUI window
        DebugLogger.shared.log("Creating main window")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "macOS UI Explorer"
        
        // Create view models
        DebugLogger.shared.log("Creating view models")
        let appViewModel = ApplicationViewModel()
        let elementTreeViewModel = ElementTreeViewModel()
        
        // Set the app's content view (MainView) as the window's content
        DebugLogger.shared.log("Creating main view")
        let mainView = MainView()
            .environmentObject(appViewModel)
            .environmentObject(elementTreeViewModel)
        
        DebugLogger.shared.log("Creating hosting view")
        let hostingView = NSHostingView(rootView: mainView)
        window.contentView = hostingView
        
        // Show the window
        DebugLogger.shared.log("Showing main window")
        window.makeKeyAndOrderFront(nil)
        
        // Initial application loading
        DebugLogger.shared.log("Triggering initial application refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appViewModel.refreshApplications()
        }
    }
}