# AccessibilityExplorer

A safe macOS accessibility explorer that provides a visual interface for exploring the accessibility hierarchy of macOS applications without freezing or causing high CPU usage.

## Features

- **Safe Mode**: Static mock data to completely avoid accessibility API calls
- **Real-time Mode**: Carefully controlled access to real accessibility APIs with safety measures
- **Automatic Safeguards**: 
  - CPU usage monitoring with automatic fallback to mock data
  - Strict timeouts for all operations (0.5-1.0 seconds)
  - Limited recursive depth (prevents deep traversal that causes freezing)
  - Limited children count (only loads first 20 elements to prevent overload)
  - Semaphore to prevent too many parallel operations
- **Detailed Interface**:
  - Application sidebar with all running apps
  - Hierarchical tree view of UI elements
  - Detailed properties panel with tabbed views
  - Elements can be expanded to explore children
  - Shows position, size, role, and other accessibility attributes

## Getting Started

1. Launch the AccessibilityExplorer app
2. By default, it starts in "Safe Mode" which uses static mock data
3. To use real accessibility data, turn off "Safe Mode" in the toolbar
4. Select an application from the sidebar to view its UI hierarchy
5. Click elements in the tree to view their properties
6. Use the tabbed interface to view different property categories
7. If the app detects high CPU usage, it will automatically revert to Safe Mode

## Architecture

- **SafeAccessibility.swift**: Core bridge to macOS accessibility APIs with safety measures
- **SafeExplorerApp.swift**: Main application with UI views and view models
- **UINode**: Data structure for representing accessibility element hierarchy
- **MockDataProvider**: Provides static data when not using real accessibility APIs

## Requirements

- macOS 12.0 or later
- Accessibility permissions (for real-time mode)

## Important Notes

- To explore an application's UI elements, you must enable accessibility permissions in System Settings
- Some applications may still cause high CPU usage even with safety measures
- If the explorer becomes unresponsive, force-restart it and it will return to Safe Mode automatically
- Limited recursive depth means very deep hierarchies may not be fully visible
- For complex applications, stick to Safe Mode for best performance

## Troubleshooting

If the app becomes unresponsive:

1. Force quit the app using Command+Option+Escape
2. Restart the app - it will automatically start in Safe Mode
3. Try exploring a different, simpler application
4. If needed, open Settings and increase timeout thresholds

## Implementation Details

The app uses a carefully controlled bridge to macOS Accessibility APIs that:

1. Creates an AXUIElement for the selected application
2. Gets top-level windows and the menu bar
3. Retrieves only the first level of children by default
4. Loads deeper elements only on user request (when expanding nodes)
5. Enforces strict timeouts on all operations
6. Monitors CPU usage and automatically falls back to safe mode when needed