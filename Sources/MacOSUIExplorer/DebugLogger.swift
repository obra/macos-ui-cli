// ABOUTME: This file provides debugging utilities for the MacOSUIExplorer app.
// ABOUTME: It helps trace issues in the application by writing logs to a file.

import Foundation

/// A simple debug logger for diagnosing issues in the MacOSUIExplorer app
class DebugLogger {
    /// Shared instance for the singleton
    static let shared = DebugLogger()
    
    /// File handle for writing logs
    private var fileHandle: FileHandle?
    
    /// Whether logging is enabled
    private(set) var isEnabled = true
    
    /// Initializes the debug logger
    private init() {
        setupLogFile()
    }
    
    /// Sets up the log file
    private func setupLogFile() {
        let fileManager = FileManager.default
        
        // Use more accessible locations for logs
        let tmpDir = "/tmp"
        let logsDir = URL(fileURLWithPath: tmpDir)
        let logPath = logsDir.appendingPathComponent("macos-ui-explorer-debug.log").path
        let errorLogPath = logsDir.appendingPathComponent("macos-ui-explorer-error.log").path
        
        print("Setting up logs at: \(logPath)")
        print("Error logs at: \(errorLogPath)")
        
        // Create or open log file
        if fileManager.fileExists(atPath: logPath) {
            // Append to existing file
            do {
                fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logPath))
                fileHandle?.seekToEndOfFile()
            } catch {
                print("Error opening existing log file: \(error)")
                
                // Try creating a new file as fallback
                fileManager.createFile(atPath: logPath, contents: nil)
                do {
                    fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logPath))
                } catch {
                    print("Critical error creating log file: \(error)")
                    fileHandle = nil
                    return
                }
            }
        } else {
            // Create new file
            fileManager.createFile(atPath: logPath, contents: nil)
            do {
                fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logPath))
            } catch {
                print("Error creating new log file: \(error)")
                fileHandle = nil
                return
            }
        }
        
        // Write header with process information
        let header = "\n\n------ MacOSUIExplorer Debug Log ------\n"
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let processInfo = ProcessInfo.processInfo
        let startMessage = """
        Session started at \(dateString)
        Process ID: \(processInfo.processIdentifier)
        Host name: \(processInfo.hostName)
        OS Version: \(processInfo.operatingSystemVersionString)
        Process active time: \(processInfo.systemUptime) seconds
        Running from app bundle: \(Bundle.main.bundleIdentifier != nil)
        
        """
        
        if let headerData = header.data(using: .utf8), 
           let startData = startMessage.data(using: .utf8) {
            fileHandle?.write(headerData)
            fileHandle?.write(startData)
            fileHandle?.synchronizeFile()
        }
        
        // Create a symbolic link to make it easier to find the latest log
        do {
            let linkPath = "\(tmpDir)/x"
            if fileManager.fileExists(atPath: linkPath) {
                try fileManager.removeItem(atPath: linkPath)
            }
            try fileManager.createSymbolicLink(atPath: linkPath, withDestinationPath: logPath)
            print("Created symbolic link at \(linkPath) -> \(logPath)")
        } catch {
            print("Error creating symbolic link: \(error)")
        }
    }
    
    /// Logs a message with a timestamp
    /// - Parameter message: The message to log
    func log(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        guard isEnabled else { return }
        
        // Get thread information
        let threadName = Thread.current.isMainThread ? "MainThread" : Thread.current.name ?? "BackgroundThread"
        let threadId = pthread_self()
        
        // Format timestamp
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        // Create detailed log message
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)][\(threadName):\(threadId)] \(fileName):\(line) - \(message)\n"
        
        // Get a local copy to avoid potential nil issues if fileHandle changes during execution
        if let fileHandle = fileHandle {
            if let data = logMessage.data(using: .utf8) {
                // Make sure file operations are synchronized
                fileHandle.synchronizeFile()
                fileHandle.write(data)
                fileHandle.synchronizeFile()
            }
        }
        
        // Create a separate error log file for critical errors
        if message.contains("ERROR") || message.contains("CRITICAL") || message.contains("WARNING") {
            // Log critical errors to stderr for immediate visibility
            fputs("🔴 \(logMessage)", stderr)
        }
        
        // Also print to console in debug builds
        #if DEBUG
        print(logMessage)
        #endif
        
        // Flush stdout and stderr to ensure output is written immediately
        fflush(stdout)
        fflush(stderr)
    }
    
    /// Logs debug information
    func logDebug(_ message: String) {
        log(message)
    }
    
    /// Logs an error with a timestamp
    /// - Parameter error: The error to log
    func log(error: Error, function: String = #function, file: String = #file, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        log("ERROR in \(fileName):\(line) - \(function): \(error.localizedDescription)")
    }
    
    /// Closes the log file
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }
    
    /// Enables or disables logging
    /// - Parameter enabled: Whether logging should be enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        log("Logging \(enabled ? "enabled" : "disabled")")
    }
    
    /// Deinitializer to clean up resources
    deinit {
        close()
    }
}