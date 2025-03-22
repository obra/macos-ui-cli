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

3. Run the executable:
   ```
   swift run macos-ui-cli
   ```

## Usage

```
USAGE: macos-ui-cli [--version] [--help] [<subcommand>]

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
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

### Basic Usage

To see the version information:
```
macos-ui-cli --version
```

To display help information:
```
macos-ui-cli --help
```

### Permissions Management

Check current accessibility permissions status:
```
macos-ui-cli permissions
```

Request accessibility permissions (shows prompt to user):
```
macos-ui-cli permissions --request
```

Open System Preferences to Accessibility settings:
```
macos-ui-cli permissions --open
```

### Application Management

Get information about the currently focused application:
```
macos-ui-cli apps --focused
```

Find an application by name:
```
macos-ui-cli apps --name "Calculator"
```

Find an application by PID:
```
macos-ui-cli apps --pid 12345
```

List all accessible applications:
```
macos-ui-cli apps
```

### Window Management

List windows of the focused application:
```
macos-ui-cli windows
```

List windows of a specific application:
```
macos-ui-cli windows --app "Calculator"
```

List windows of an application by PID:
```
macos-ui-cli windows --pid 12345
```

### UI Element Discovery

Find the currently focused UI element:
```
macos-ui-cli elements --focused
```

Find all buttons in the focused application:
```
macos-ui-cli elements --role button
```

Find elements with a specific title:
```
macos-ui-cli elements --title "OK"
```

Find elements by path:
```
macos-ui-cli elements --path "window[Calculator]/button[=]"
```

Search within a specific application:
```
macos-ui-cli elements --app "Calculator" --role button
```

### UI Interaction

Press a button in an application:
```
macos-ui-cli button --app "Calculator" --title "=" --press
```

Read text from a text field:
```
macos-ui-cli text --app "Notes" --field "Text Area" --read
```

Write text to a text field:
```
macos-ui-cli text --app "Notes" --field "Text Area" --value "Hello, World!"
```

Manipulate a window (move and resize):
```
macos-ui-cli window --app "Calculator" --position "100,100" --size "400,300"
```

Focus a window:
```
macos-ui-cli window --app "Calculator" --focus
```

Minimize a window:
```
macos-ui-cli window --app "Calculator" --minimize
```

Toggle fullscreen mode:
```
macos-ui-cli window --app "Calculator" --fullscreen
```

Simulate keyboard input:
```
macos-ui-cli keyboard --text "Hello, World!"
```

Simulate key combinations:
```
macos-ui-cli keyboard --combo "cmd+c"
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

This tool requires macOS Accessibility permissions to function properly. When you run the tool, it will check if permissions are granted and guide you through enabling them if needed.

To manually manage permissions:

1. Open System Preferences > Security & Privacy > Privacy
2. Select 'Accessibility' from the sidebar
3. Click the lock icon to make changes
4. Add or check this application in the list
5. Restart the application if needed

You can also use the built-in permissions command:
```
macos-ui-cli permissions --open
```

## Features

### Implemented
- Accessibility permission management
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