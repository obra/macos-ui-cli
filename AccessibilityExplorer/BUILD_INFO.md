# Building the AccessibilityExplorer App

There are two ways to build and run the AccessibilityExplorer:

## Option 1: Using Swift Package Manager from CLI

We've integrated the app with Swift Package Manager, but there are some limitations with accessing accessibility APIs directly from a command-line tool. For the best experience, you may want to use the Xcode approach.

```bash
# Build the app
swift build --target AccessibilityExplorer

# Find and run the executable (path may vary)
find ./.build -name "AccessibilityExplorer" -type f -perm +111 | xargs $1
```

## Option 2: Using Xcode (Recommended)

For the best development and debugging experience, open the project in Xcode:

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. Select the "AccessibilityExplorer" target in the scheme dropdown

3. Build and run (⌘R)

This will build and run the app with proper entitlements for accessibility permissions.

## Creating a Standalone App

For distribution purposes, you can create a standalone .app bundle:

1. Create a macOS app project in Xcode with the same target name

2. Copy the BasicExplorerApp.swift file into the project

3. Set appropriate entitlements for accessibility access

4. Build and archive for distribution

## Debugging

If you have problems with the build:

1. Make sure Xcode command line tools are up to date:
   ```bash
   xcode-select --install
   ```

2. Try cleaning and rebuilding:
   ```bash
   swift package clean
   swift build --target AccessibilityExplorer
   ```

3. Check that the proper target exists in Package.swift

4. Ensure the app has proper entitlements for accessibility APIs

5. When running, you'll need to grant accessibility permissions to the app:
   - System Settings > Privacy & Security > Accessibility
   - Add the app to the allowed list

## Implementation Notes

The current implementation uses a simplified, single-file approach for the app to ensure stability while still providing real accessibility API access. The app includes safety measures like timeouts and CPU usage monitoring to prevent freezing issues that were encountered with more complex implementations.