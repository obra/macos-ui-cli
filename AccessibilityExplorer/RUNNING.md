# Running the AccessibilityExplorer

This document explains how to build and run the AccessibilityExplorer app.

## Building with Xcode

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. Select the `AccessibilityExplorer` target from the schemes dropdown in the toolbar.

3. Choose a simulator or your Mac as the run destination.

4. Click the Run button or press Cmd+R to build and run the app.

## Building from Command Line

You can also build and run the app from the command line:

```bash
# Navigate to the project directory
cd /path/to/macos-ui-cli

# Build the AccessibilityExplorer target
swift build --target AccessibilityExplorer -c release

# Run the built application
./.build/release/AccessibilityExplorer
```

## Granting Accessibility Permissions

To use real accessibility API access (when not in Safe Mode), you'll need to grant permissions:

1. When you first try to switch to real accessibility API access by turning off Safe Mode, the system will prompt you to grant permissions.

2. Alternatively, you can manually enable permissions:
   - Open System Settings/Preferences
   - Go to Privacy & Security > Accessibility
   - Add the AccessibilityExplorer app to the list of allowed apps
   - Toggle the permission switch to ON

## Usage Tips

1. **Start in Safe Mode**: By default, the app starts in Safe Mode (using mock data). This is the safest way to explore the interface without risking freezes.

2. **Testing Real Access**: When ready to test real accessibility API access:
   - Start with simple applications that have relatively flat UI hierarchies
   - Toggle Safe Mode off in the toolbar
   - Watch for any performance issues

3. **Gradual Exploration**: When exploring an application's hierarchy:
   - Start by expanding just one or two top-level elements
   - Avoid rapidly expanding many nodes at once
   - If you notice performance degradation, switch back to Safe Mode

4. **Monitoring Performance**: The status bar at the bottom shows:
   - Current mode (Safe or Connected)
   - Loading status
   - Any error messages
   - The currently selected application

5. **Recovery from Freeze**: If the app becomes unresponsive:
   - Force quit (Cmd+Option+Escape)
   - Restart with Safe Mode enabled (default)
   - Try exploring a different application

## Debugging

If you encounter issues:

1. Check the debug console for logs about timeouts or high CPU usage
2. Enable the Debug toggle at the bottom-right to see additional debugging information
3. If exploring a particular application causes consistent freezes, please report the issue