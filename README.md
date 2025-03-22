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
USAGE: macos-ui-cli [--version] [--help]

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.
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

## Future Features

- Process discovery and application connection
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