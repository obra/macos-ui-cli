// ABOUTME: This file defines global options for the CLI tool.
// ABOUTME: It provides a centralized place for formatting and output options.

import Foundation
import ArgumentParser

/// Global options that apply to all commands
public struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Output format (text, json, xml)")
    public var format: String = "text"
    
    @Option(name: .long, help: "Verbosity level (0-3)")
    public var verbosity: Int = 1
    
    @Flag(name: .long, help: "Enable colorized output")
    public var color: Bool = false
    
    /// Required initializer for ParsableArguments protocol
    public init() {}
    
    /// Get the OutputFormat enum from the string option
    public var outputFormat: OutputFormat {
        return OutputFormat.fromString(format)
    }
    
    /// Get the VerbosityLevel enum from the integer option
    public var verbosityLevel: VerbosityLevel {
        return VerbosityLevel.fromInt(verbosity)
    }
    
    /// Create a formatter based on the global options
    public func createFormatter() -> OutputFormatter {
        return FormatterFactory.createWithErrorHandling(
            format: outputFormat,
            verbosity: verbosityLevel,
            colorized: color
        )
    }
}

/// Singleton to store the current global formatting options
public class FormattingOptions {
    /// The shared instance
    public static let shared = FormattingOptions()
    
    /// The output format to use
    public var format: OutputFormat = .plainText
    
    /// The verbosity level to use
    public var verbosity: VerbosityLevel = .normal
    
    /// Whether to use colorized output
    public var colorized: Bool = false
    
    /// Get a formatter with the current settings
    public func createFormatter() -> OutputFormatter {
        return FormatterFactory.createWithErrorHandling(
            format: format,
            verbosity: verbosity,
            colorized: colorized
        )
    }
    
    /// Update from GlobalOptions
    public func update(from options: GlobalOptions) {
        self.format = options.outputFormat
        self.verbosity = options.verbosityLevel
        self.colorized = options.color
    }
    
    /// Private initializer for singleton
    private init() {}
}