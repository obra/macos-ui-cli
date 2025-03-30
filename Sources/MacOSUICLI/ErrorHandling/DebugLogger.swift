// ABOUTME: This file provides debug logging functionality for detailed error information.
// ABOUTME: It allows capturing and logging detailed information for debugging purposes.

import Foundation

/// Debug logging level
public enum LogLevel: Int, Comparable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case trace = 5
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Logger for debug messages
public class DebugLogger {
    /// Shared instance of the logger
    public static let shared = DebugLogger()
    
    /// The current log level
    public var logLevel: LogLevel = .none
    
    /// Whether to log to a file
    public var logToFile: Bool = false
    
    /// The path to the log file
    public var logFilePath: String = ""
    
    /// The formatter to use for log messages
    private var formatter: OutputFormatter?
    
    /// Timestamp of when the logger was initialized
    private let startTime = Date()
    
    /// Returns the time elapsed since logger initialization
    public var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    /// Returns a formatted timestamp for the current elapsed time
    public var elapsedTimeString: String {
        let totalSeconds = elapsedTime
        let minutes = Int(totalSeconds / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Use more accessible locations for logs
        let logDirectory = URL(fileURLWithPath: "/tmp/macos-ui-cli-logs")
        
        // Create the directory if it doesn't exist
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // Set the log file path
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        logFilePath = logDirectory.appendingPathComponent("debug_\(timestamp).log").path
        
        // Enable logging to file by default
        logToFile = true
        logLevel = .debug
        
        // Log startup information
        let logStart = "--- MacOS UI CLI Debug Log Started at \(timestamp) ---"
        print(logStart)
        log(logStart, level: .info)
    }
    
    /// Sets the formatter to use for log messages
    /// - Parameter formatter: The formatter to use
    public func setFormatter(_ formatter: OutputFormatter) {
        self.formatter = formatter
    }
    
    /// Logs a message at the specified level
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func log(
        _ message: String,
        level: LogLevel,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Only log if the level is high enough
        guard level <= logLevel else { return }
        
        // Get thread information
        let threadName = Thread.current.isMainThread ? "MainThread" : Thread.current.name ?? "BackgroundThread"
        let threadId = pthread_self()
        
        // Create the log message
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        
        // Include elapsed time in the log message
        let logMessage = "[\(timestamp)] [\(elapsedTimeString)] [\(level)] [\(threadName):\(threadId)] [\(fileName):\(line)] \(function): \(message)"
        
        // Print to console if appropriate
        if level <= .error || logLevel >= .debug {
            print(logMessage)
        }
        
        // Write to file if enabled
        if logToFile, let data = (logMessage + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFilePath) {
                if let fileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logFilePath)) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logFilePath))
            }
        }
    }
    
    /// Logs an error
    /// - Parameters:
    ///   - error: The error to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func logError(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var message = "Error: \(error.localizedDescription)"
        
        // Add additional information for ApplicationError types
        if let appError = error as? ApplicationError {
            message += "\nCode: \(appError.errorCode)"
            message += "\nRecovery: \(appError.recoverySuggestion)"
            if let debugInfo = appError.debugInfo {
                message += "\nDebug Info: \(debugInfo)"
            }
        }
        
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Logs a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func logWarning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Logs an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func logInfo(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Logs a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func logDebug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
}