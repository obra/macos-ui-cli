# macOS UI CLI

A command-line tool for macOS UI automation via accessibility APIs, utilizing the Haxcessibility library.

## Overview

macOS UI CLI provides a command-line interface to interact with macOS applications through the accessibility API, allowing you to automate UI tasks, retrieve UI element information, and perform actions on UI elements.

## Installation

### Prerequisites

- macOS 11.0 or later
- Xcode 13.0 or later (for development)
- Swift 5.5 or later

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/macos-ui-cli.git
   cd macos-ui-cli
   ```

2. Build the project:
   ```
   swift build
   ```

3. Create the app wrapper for accessibility permissions:
   ```
   ./.build/debug/macos-ui-cli permissions --create-wrapper
   ```

4. Run the executable through the app wrapper:
   ```
   /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli
   ```

5. Grant accessibility permissions when prompted by macOS

## Usage

```
USAGE: macos-ui-cli [--version] [--help] [--format FORMAT] [--verbosity LEVEL] [--color] [<subcommand>]

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.
  --format FORMAT         Output format: text, json, or xml (default: text)
  --verbosity LEVEL       Verbosity level 0-3 (default: 1)
  --color                 Enable colorized output

SUBCOMMANDS:
  discover                Commands for discovering UI elements
    apps                  List and find applications
    windows               List and find windows
    elements              Find, inspect, and interact with UI elements
  
  interact                Commands for interacting with UI elements
    button                Interact with buttons
    text                  Read from or write to text fields
    window                Manipulate windows (move, resize, focus, etc.)
    keyboard              Simulate keyboard input
    
  util                    Utility commands for the tool
    permissions           Check and request accessibility permissions
    version               Show detailed version information
    info                  Display system information
    format                Configure output formatting
    
  # Original commands for backward compatibility
  permissions             Check and request accessibility permissions
  apps                    List and find applications
  windows                 List and find windows
  elements                Find, inspect, and interact with UI elements
  button                  Interact with buttons
  text                    Read from or write to text fields
  window                  Manipulate windows (move, resize, focus, etc.)
  keyboard                Simulate keyboard input
```

## Examples

The examples below assume you've created and granted permissions to the app wrapper. Replace `/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli` with your path if different.

### Basic Usage

To see the version information:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --version
```

To display help information:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --help
```

For convenience, you can create an alias in your shell profile:
```
alias macos-ui-cli="/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli"
```

### Permissions Management

Check current accessibility permissions status:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli permissions
```

Request accessibility permissions (shows prompt to user):
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli permissions --request
```

Open System Settings to Accessibility settings:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli permissions --open
```

### Application Management

Get information about the currently focused application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli apps --focused
```

Find an application by name:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli apps --name "Calculator"
```

Find an application by PID:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli apps --pid 12345
```

List all accessible applications:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli apps
```

### Window Management

List windows of the focused application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli windows
```

List windows of a specific application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli windows --app "Calculator"
```

List windows of an application by PID:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli windows --pid 12345
```

### UI Element Discovery

Find the currently focused UI element:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli elements --focused
```

Find all buttons in the focused application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli elements --role button
```

Find elements with a specific title:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli elements --title "OK"
```

Find elements by path:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli elements --path "window[Calculator]/button[=]"
```

Search within a specific application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli elements --app "Calculator" --role button
```

### UI Interaction

Press a button in an application:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli button --app "Calculator" --title "=" --press
```

Read text from a text field:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli text --app "Notes" --field "Text Area" --read
```

Write text to a text field:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli text --app "Notes" --field "Text Area" --value "Hello, World!"
```

Manipulate a window (move and resize):
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli window --app "Calculator" --position "100,100" --size "400,300"
```

Focus a window:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli window --app "Calculator" --focus
```

Minimize a window:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli window --app "Calculator" --minimize
```

Toggle fullscreen mode:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli window --app "Calculator" --fullscreen
```

Simulate keyboard input:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli keyboard --text "Hello, World!"
```

Simulate key combinations:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli keyboard --combo "cmd+c"
```

## Development

### Setting up the Development Environment

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/macos-ui-cli.git
   cd macos-ui-cli
   ```

2. Open the package in Xcode (optional):
   ```
   open Package.swift
   ```

### Running Tests

To run the test suite:
```
swift test
```

## Accessibility Permissions

This tool requires macOS Accessibility permissions to function properly. Command-line tools cannot directly receive accessibility permissions in macOS, so you must create and use an app wrapper.

### App Wrapper for Accessibility Permissions

To create the app wrapper:
```
macos-ui-cli permissions --create-wrapper
```

This creates a macOS application bundle at `/Applications/macos-ui-cli.app` that contains your command-line tool. You must then run the tool through this wrapper:

```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli
```

After running the wrapped app for the first time, macOS will prompt you to grant accessibility permissions:

1. System Settings (or System Preferences) will open to the Accessibility section
2. Click the lock icon to make changes (if needed)
3. Check the box next to "macos-ui-cli"
4. Close System Settings

You can check your current permission status:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli permissions
```

To manually open the accessibility settings:
```
macos-ui-cli permissions --open
```

### Why an App Wrapper is Needed

macOS restricts accessibility API access for security reasons. Pure command-line tools cannot appear in the Accessibility permissions list in System Settings because:

1. They don't have proper application bundles with Info.plist files
2. They don't have the required `NSAccessibilityUsageDescription` entry
3. They aren't launched through Launch Services which tracks permission grants

The app wrapper technique solves these issues by:
- Creating a proper application bundle structure
- Including the necessary Info.plist entries
- Providing a launchable application that can appear in System Settings

Without this wrapper, the accessibility API calls will always fail, even if you try to grant permissions manually.

### Output Formatting

The tool supports different output formats to match your needs:

Test different output formats:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli util format --format json --sample apps
```

Configure output format for any command:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --format json apps
```

Adjust verbosity level (0-3):
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --verbosity 2 elements --app "Calculator"
```

Enable colorized output:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --color apps
```

#### Available Output Formats

- **Text** (default): Human-readable text output
  ```
  /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli apps
  ```

- **JSON**: Structured JSON for machine processing
  ```
  /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --format json apps
  ```

- **XML**: XML format for integration with XML-based tools
  ```
  /Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --format xml apps
  ```

#### Verbosity Levels

- **0 (minimal)**: Basic information only
- **1 (normal)**: Standard level of detail (default)
- **2 (detailed)**: Additional details and attributes
- **3 (debug)**: All available information

Example with detailed verbosity:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli --verbosity 2 elements --focused
```

#### Hierarchical Visualization

Visualize element hierarchies in different formats:
```
/Applications/macos-ui-cli.app/Contents/MacOS/macos-ui-cli util format --sample hierarchy
```

### Error Handling

The tool implements comprehensive error handling with detailed error information, error codes, and recovery suggestions.

#### Error Types

- **Accessibility Errors**: Issues with accessibility permissions or API usage
- **UI Element Errors**: Problems finding or interacting with UI elements
- **Operation Errors**: Timeouts, failures, or unsupported operations
- **Application Manager Errors**: Issues accessing or controlling applications
- **Window Errors**: Problems with window management
- **Input Errors**: Keyboard or mouse input failures
- **Validation Errors**: Command argument validation issues

#### Error Recovery Suggestions

Error messages include recovery suggestions to help resolve issues:

```
Error: Permission denied for accessibility access
Error Code: 101
Recovery Suggestion: Grant permission for this application in System Preferences → Security & Privacy → Privacy → Accessibility
```

#### Timeout and Retry Mechanisms

UI operations can be flaky due to application responsiveness issues. The tool implements:

- **Timeouts**: Prevent operations from hanging indefinitely
- **Automatic Retry**: Retry flaky operations with configurable attempts and delay
- **Combined Approach**: Both timeout and retry for maximum reliability

UI operations use these mechanisms automatically, but you can adjust them in scripting mode:

```
# Example of timeout and retry configuration in a future scripting mode
macos-ui-cli script --execute "
  set timeout 5.0  
  set retry-count 3
  set retry-delay 1.0
  press button 'OK' in 'Dialog'
"
```

## Features

### Implemented
- Accessibility permission management with app wrapper support
- Application discovery and access
- PID and name-based application lookup
- Application property inspection
- Window enumeration and inspection
- UI element discovery and traversal
- Element property inspection
- Element filtering by role or title
- Path-based element lookup
- Button pressing and text field interaction
- Window manipulation (resize, move, focus, minimize, fullscreen)
- Element action discovery and execution
- Keyboard input simulation
- Comprehensive error handling with recovery suggestions
- Input validation for commands and arguments
- Timeout and retry mechanisms for UI operations
- Flexible output formatting (plain text, JSON, XML)
- Adjustable verbosity levels
- Colorized output
- Element hierarchy visualization

### Future Features
- Scripting support
- Recording and replaying UI interactions
- Advanced element selection strategies
- Interactive mode
- Integration with common development workflows

## License

[License information to be added]

## Acknowledgments

- [Haxcessibility](https://github.com/nst/Haxcessibility) - The Objective-C library providing access to macOS accessibility APIs