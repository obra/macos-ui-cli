// ABOUTME: This file contains tests for the CLI command structure.
// ABOUTME: It tests the organization and functionality of the command-line interface.

import XCTest
import class Foundation.Bundle
@testable import MacOSUICLI

final class CommandStructureTests: XCTestCase {
    
    // Helper to run the app with arguments and capture output
    private func runApp(with arguments: [String]) throws -> (stdout: String, stderr: String, exitCode: Int32) {
        // Get the path to the built executable
        let bundle = Bundle(for: type(of: self))
        let executableURL = bundle.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(".build")
            .appendingPathComponent("debug")
            .appendingPathComponent("macos-ui-cli")
        
        // Create a process
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        
        // Capture standard output
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        
        // Capture standard error
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        
        try process.run()
        process.waitUntilExit()
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        return (stdout, stderr, process.terminationStatus)
    }
    
    // Test that the root command displays help information
    func testRootCommandHelp() throws {
        // Test that the root command's discussion includes help information
        let discussion = MacOSUICLI.configuration.discussion
        XCTAssertFalse(discussion.isEmpty, "Root command should have discussion text")
        XCTAssertTrue(discussion.contains("discover"), "Discussion should mention discover commands")
        XCTAssertTrue(discussion.contains("interact"), "Discussion should mention interact commands")
        XCTAssertTrue(discussion.contains("util"), "Discussion should mention utility commands")
        XCTAssertTrue(discussion.contains("--help"), "Discussion should mention help flag")
    }
    
    // Test that the version flag works
    func testVersionFlag() throws {
        // Test that the version is set
        XCTAssertFalse(MacOSUICLI.configuration.version.isEmpty, "Version should be set")
        XCTAssertEqual(MacOSUICLI.configuration.version, "0.2.0", "Version should match expected value")
        
        // Test that there's a version command
        let utilityCommands = MacOSUICLI.configuration.subcommands.first { $0 == UtilityCommands.self }
        XCTAssertNotNil(utilityCommands, "Utility commands should exist")
        
        let versionCommand = UtilityCommands.configuration.subcommands.first { $0 == VersionCommand.self }
        XCTAssertNotNil(versionCommand, "Version command should exist in utility commands")
    }
    
    // Test the hierarchical command structure
    func testCommandHierarchy() {
        // Verify that the main command has the expected subcommands
        let subcommands = MacOSUICLI.configuration.subcommands
        
        // Check for command groups
        let hasDiscoveryCommands = subcommands.contains { $0 == DiscoveryCommands.self }
        let hasInteractionCommands = subcommands.contains { $0 == InteractionCommands.self }
        let hasUtilityCommands = subcommands.contains { $0 == UtilityCommands.self }
        
        XCTAssertTrue(hasDiscoveryCommands, "MacOSUICLI should have discovery commands group")
        XCTAssertTrue(hasInteractionCommands, "MacOSUICLI should have interaction commands group")
        XCTAssertTrue(hasUtilityCommands, "MacOSUICLI should have utility commands group")
        
        // Check for specific required commands (for backward compatibility)
        let hasPermissions = subcommands.contains { $0 == PermissionsCommand.self }
        let hasApps = subcommands.contains { $0 == ApplicationsCommand.self }
        let hasWindows = subcommands.contains { $0 == WindowsCommand.self }
        let hasElements = subcommands.contains { $0 == ElementsCommand.self }
        let hasButton = subcommands.contains { $0 == ButtonCommand.self }
        let hasText = subcommands.contains { $0 == TextCommand.self }
        let hasWindow = subcommands.contains { $0 == WindowCommand.self }
        let hasKeyboard = subcommands.contains { $0 == KeyboardCommand.self }
        
        // Command structure should include these common commands for backward compatibility
        XCTAssertTrue(hasPermissions, "MacOSUICLI should have a permissions subcommand")
        XCTAssertTrue(hasApps, "MacOSUICLI should have an apps subcommand")
        XCTAssertTrue(hasWindows, "MacOSUICLI should have a windows subcommand")
        XCTAssertTrue(hasElements, "MacOSUICLI should have an elements subcommand")
        XCTAssertTrue(hasButton, "MacOSUICLI should have a button subcommand")
        XCTAssertTrue(hasText, "MacOSUICLI should have a text subcommand")
        XCTAssertTrue(hasWindow, "MacOSUICLI should have a window subcommand")
        XCTAssertTrue(hasKeyboard, "MacOSUICLI should have a keyboard subcommand")
        
        // Check for command group structure
        // Discovery commands
        let discoverySubcommands = DiscoveryCommands.configuration.subcommands
        XCTAssertTrue(discoverySubcommands.contains { $0 == ApplicationsCommand.self }, "Discovery commands should include apps command")
        XCTAssertTrue(discoverySubcommands.contains { $0 == WindowsCommand.self }, "Discovery commands should include windows command")
        XCTAssertTrue(discoverySubcommands.contains { $0 == ElementsCommand.self }, "Discovery commands should include elements command")
        
        // Interaction commands
        let interactionSubcommands = InteractionCommands.configuration.subcommands
        XCTAssertTrue(interactionSubcommands.contains { $0 == ButtonCommand.self }, "Interaction commands should include button command")
        XCTAssertTrue(interactionSubcommands.contains { $0 == TextCommand.self }, "Interaction commands should include text command")
        XCTAssertTrue(interactionSubcommands.contains { $0 == WindowCommand.self }, "Interaction commands should include window command")
        XCTAssertTrue(interactionSubcommands.contains { $0 == KeyboardCommand.self }, "Interaction commands should include keyboard command")
        
        // Utility commands
        let utilitySubcommands = UtilityCommands.configuration.subcommands
        XCTAssertTrue(utilitySubcommands.contains { $0 == PermissionsCommand.self }, "Utility commands should include permissions command")
        XCTAssertTrue(utilitySubcommands.contains { $0 == VersionCommand.self }, "Utility commands should include version command")
        XCTAssertTrue(utilitySubcommands.contains { $0 == InfoCommand.self }, "Utility commands should include info command")
    }
    
    // Test that command help documentation is available for all commands
    func testCommandHelp() {
        // Check that all commands have help text
        XCTAssertFalse(MacOSUICLI.configuration.abstract.isEmpty, "Root command should have help text")
        XCTAssertFalse(DiscoveryCommands.configuration.abstract.isEmpty, "Discovery commands should have help text")
        XCTAssertFalse(InteractionCommands.configuration.abstract.isEmpty, "Interaction commands should have help text")
        XCTAssertFalse(UtilityCommands.configuration.abstract.isEmpty, "Utility commands should have help text")
        
        // Check that group commands have discussion text
        XCTAssertFalse(DiscoveryCommands.configuration.discussion.isEmpty, "Discovery commands should have discussion text")
        XCTAssertFalse(InteractionCommands.configuration.discussion.isEmpty, "Interaction commands should have discussion text")
        XCTAssertFalse(UtilityCommands.configuration.discussion.isEmpty, "Utility commands should have discussion text")
        
        // Check that child commands have discussion text
        XCTAssertFalse(ApplicationsCommand.configuration.discussion.isEmpty, "Applications command should have discussion text")
        XCTAssertFalse(WindowsCommand.configuration.discussion.isEmpty, "Windows command should have discussion text")
        XCTAssertFalse(ElementsCommand.configuration.discussion.isEmpty, "Elements command should have discussion text")
        XCTAssertFalse(ButtonCommand.configuration.discussion.isEmpty, "Button command should have discussion text")
        XCTAssertFalse(TextCommand.configuration.discussion.isEmpty, "Text command should have discussion text")
        XCTAssertFalse(WindowCommand.configuration.discussion.isEmpty, "Window command should have discussion text")
        XCTAssertFalse(KeyboardCommand.configuration.discussion.isEmpty, "Keyboard command should have discussion text")
        XCTAssertFalse(PermissionsCommand.configuration.discussion.isEmpty, "Permissions command should have discussion text")
        XCTAssertFalse(VersionCommand.configuration.discussion.isEmpty, "Version command should have discussion text")
        XCTAssertFalse(InfoCommand.configuration.discussion.isEmpty, "Info command should have discussion text")
    }
    
    // Test that command examples are available
    func testCommandExamples() {
        // Test that command groups include examples in their discussion
        let discoveryDiscussion = DiscoveryCommands.configuration.discussion
        XCTAssertTrue(discoveryDiscussion.contains("Examples:"), "Discovery commands should include examples")
        XCTAssertTrue(discoveryDiscussion.contains("macos-ui-cli discover"), "Discovery examples should use correct prefix")
        
        let interactionDiscussion = InteractionCommands.configuration.discussion
        XCTAssertTrue(interactionDiscussion.contains("Examples:"), "Interaction commands should include examples")
        XCTAssertTrue(interactionDiscussion.contains("macos-ui-cli interact"), "Interaction examples should use correct prefix")
        
        let utilityDiscussion = UtilityCommands.configuration.discussion
        XCTAssertTrue(utilityDiscussion.contains("Examples:"), "Utility commands should include examples")
        XCTAssertTrue(utilityDiscussion.contains("macos-ui-cli util"), "Utility examples should use correct prefix")
        
        // Test that individual commands include examples in their discussion
        let appsDiscussion = ApplicationsCommand.configuration.discussion
        XCTAssertTrue(appsDiscussion.contains("Examples:"), "Apps command should include examples")
        
        let windowsDiscussion = WindowsCommand.configuration.discussion
        XCTAssertTrue(windowsDiscussion.contains("Examples:"), "Windows command should include examples")
        
        let elementsDiscussion = ElementsCommand.configuration.discussion
        XCTAssertTrue(elementsDiscussion.contains("Examples:"), "Elements command should include examples")
    }
}

extension CommandStructureTests {
    static var allTests = [
        ("testRootCommandHelp", testRootCommandHelp),
        ("testVersionFlag", testVersionFlag),
        ("testCommandHierarchy", testCommandHierarchy),
        ("testCommandHelp", testCommandHelp),
        ("testCommandExamples", testCommandExamples),
    ]
}