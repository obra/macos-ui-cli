#!/bin/bash
# Simple build and run script for AccessibilityExplorer

set -e

echo "Building AccessibilityExplorer..."
swiftc -parse-as-library -o AccessibilityExplorerApp BasicExplorerApp.swift

echo "Build successful! Running application..."
echo "Note: You may need to grant accessibility permissions when prompted."
echo "      If no window appears, check System Settings > Privacy & Security > Accessibility"
echo ""

./AccessibilityExplorerApp

# This script will wait for the app to exit
echo "Application exited."