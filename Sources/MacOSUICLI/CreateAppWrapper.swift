// ABOUTME: This file provides a utility to create a minimal app wrapper for command-line tools.
// ABOUTME: It helps with accessibility permission issues that are specific to command-line apps.

import Foundation

/// Utility to create an app wrapper for command-line tools
/// This is useful for granting accessibility permissions
public struct AppWrapperCreator {
    /// Creates a minimal app wrapper for the current executable
    /// - Parameter appName: The name of the app to create
    /// - Returns: true if successful, false otherwise
    public static func createAppWrapper(named appName: String = "macos-ui-cli") -> Bool {
        // Get the path to the binary itself, not the bundle
        let currentExecPath = ProcessInfo.processInfo.arguments[0]
        let appPath = "/Applications/\(appName).app"
        let executablePath = "\(appPath)/Contents/MacOS/\(appName)"
        
        // Create Info.plist content
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.example.\(appName)</string>
            <key>CFBundleName</key>
            <string>\(appName)</string>
            <key>CFBundleVersion</key>
            <string>0.1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>0.1.0</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleExecutable</key>
            <string>\(appName)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>LSApplicationCategoryType</key>
            <string>public.app-category.utilities</string>
            <key>LSMinimumSystemVersion</key>
            <string>11.0</string>
            <key>NSPrincipalClass</key>
            <string>NSApplication</string>
            <key>NSAccessibilityUsageDescription</key>
            <string>This application requires accessibility permissions to automate UI interactions.</string>
        </dict>
        </plist>
        """
        
        do {
            // Create app bundle structure
            try FileManager.default.createDirectory(atPath: "\(appPath)/Contents/MacOS", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(appPath)/Contents/Resources", withIntermediateDirectories: true)
            
            // Create Info.plist
            try infoPlist.write(toFile: "\(appPath)/Contents/Info.plist", atomically: true, encoding: .utf8)
            
            // Copy executable
            if FileManager.default.fileExists(atPath: executablePath) {
                try FileManager.default.removeItem(atPath: executablePath)
            }
            try FileManager.default.copyItem(atPath: currentExecPath, toPath: executablePath)
            
            // Make executable
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", executablePath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()
            
            // Add a script to diagnose the permission issues
            let diagScriptPath = "\(appPath)/Contents/Resources/diagnose.sh"
            let diagScript = """
            #!/bin/bash
            echo "Accessibility Permission Diagnostic Script"
            echo "=========================================="
            echo "Testing AXIsProcessTrusted API..."
            osascript -e 'tell application "System Events" to get UI elements of window 1 of (first process whose frontmost is true)'
            echo "Exit code: $?"
            echo
            echo "App bundle location:"
            ls -la "\(appPath)"
            echo
            echo "Info.plist contents:"
            cat "\(appPath)/Contents/Info.plist"
            echo
            echo "Executable path:"
            ls -la "\(executablePath)"
            echo
            echo "Security Assessment:"
            spctl --assess --verbose "\(appPath)"
            """
            
            try diagScript.write(toFile: diagScriptPath, atomically: true, encoding: .utf8)
            
            let chmodDiagProcess = Process()
            chmodDiagProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodDiagProcess.arguments = ["+x", diagScriptPath]
            try chmodDiagProcess.run()
            chmodDiagProcess.waitUntilExit()
            
            // Create a launcher shell script
            let launcherPath = "\(appPath)/run-app.sh"
            let launcherScript = """
            #!/bin/bash
            # Run the app with full diagnostic output
            echo "Starting macos-ui-cli with diagnostic output..."
            "\(appPath)/Contents/MacOS/\(appName)" "$@"
            """
            
            try launcherScript.write(toFile: launcherPath, atomically: true, encoding: .utf8)
            
            let chmodLauncherProcess = Process()
            chmodLauncherProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodLauncherProcess.arguments = ["+x", launcherPath]
            try chmodLauncherProcess.run()
            chmodLauncherProcess.waitUntilExit()
            
            print("Created app wrapper at: \(appPath)")
            print("You can now grant accessibility permissions to this app in System Preferences.")
            print("\nTo run the diagnostic script:")
            print("\(appPath)/Contents/Resources/diagnose.sh")
            print("\nTo run the app with the wrapper:")
            print("\(appPath)/run-app.sh permissions")
            return true
        } catch {
            print("Error creating app wrapper: \(error)")
            return false
        }
    }
}