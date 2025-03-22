// ABOUTME: This file contains the main entry point for the MacOSUICLI application.
// ABOUTME: It defines the root command and handles basic CLI argument parsing.

import Foundation
import ArgumentParser
import Haxcessibility

/// Root command for the MacOSUICLI tool
struct MacOSUICLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "macos-ui-cli",
        abstract: "Command-line tool for macOS UI automation via accessibility APIs",
        discussion: """
        MacOSUICLI provides a command-line interface for interacting with macOS applications
        through the accessibility API. It allows you to discover, inspect, and manipulate UI
        elements programmatically.
        
        The commands are organized into three main groups:
        
        - discover: Find and inspect applications, windows, and UI elements
        - interact: Manipulate UI elements like buttons, text fields, and windows
        - util: Utility commands for permissions, system info, etc.
        
        For detailed help on any command, use --help after the command:
          macos-ui-cli discover apps --help
          macos-ui-cli interact button --help
          macos-ui-cli util permissions --help
          
        Before using the tool for UI interaction, ensure accessibility permissions are granted:
          macos-ui-cli util permissions --request
          
        For improved accessibility support, create an app wrapper:
          macos-ui-cli util permissions --create-wrapper
          /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli discover apps
          
        Global output formatting options:
          --format <format>      Output format (text, json, xml)
          --verbosity <level>    Verbosity level (0-3)
          --color                Enable colorized output
        """,
        version: "0.2.0",
        subcommands: [
            DiscoveryCommands.self,
            InteractionCommands.self,
            UtilityCommands.self,
            // Keep the top-level commands for backward compatibility
            PermissionsCommand.self,
            ApplicationsCommand.self,
            WindowsCommand.self,
            ElementsCommand.self,
            ButtonCommand.self,
            TextCommand.self,
            WindowCommand.self,
            KeyboardCommand.self
        ],
        defaultSubcommand: nil
    )
    
    @OptionGroup
    var globalOptions: GlobalOptions
    
    func run() throws {
        // Update global formatting options
        FormattingOptions.shared.update(from: globalOptions)
        
        // Create a formatter based on global options
        let formatter = FormattingOptions.shared.createFormatter()
        
        // Format output using the appropriate formatter
        let message = "MacOSUICLI - Command-line tool for macOS UI automation"
        print(formatter.formatMessage(message, type: .info))
        
        print("Version: \(MacOSUICLI.configuration.version)")
        print("Use --help to see available commands")
        
        // Check if Haxcessibility is available
        let status = "Haxcessibility available: \(SystemAccessibility.isAvailable() ? "Yes" : "No")"
        print(formatter.formatMessage(status, type: SystemAccessibility.isAvailable() ? .success : .warning))
    }
}

// Start the CLI application
MacOSUICLI.main()