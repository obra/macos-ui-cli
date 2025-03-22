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

### Future Features
- Window enumeration
- Element hierarchy traversal
- Element property inspection
- Button pressing and text field interaction
- Window manipulation
- Scripting support

## License

[License information to be added]

## Acknowledgments

- [Haxcessibility](https://github.com/nst/Haxcessibility) - The Objective-C library providing access to macOS accessibility APIs