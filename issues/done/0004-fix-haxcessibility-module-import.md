# Issue 0004: Fix Haxcessibility Module Import

## Overview

This issue addresses the problem with importing the Haxcessibility Objective-C library into our Swift package. The Haxcessibility library is essential for accessing macOS accessibility APIs, which is fundamental to the functionality of our CLI tool.

## Problem

The Haxcessibility library wasn't being properly imported when HAXCESSIBILITY_AVAILABLE flag was defined. This resulted in compilation errors that prevented using Haxcessibility functionality in our Swift code.

## Solution Implemented

We fixed the Haxcessibility module import using the following approach:

1. Properly configured the module map in Sources/Haxcessibility/module.modulemap to correctly export the Haxcessibility module.
2. Created an appropriate umbrella header in Sources/Haxcessibility/Haxcessibility.h that imports all necessary headers.
3. Updated Swift files to use the correct API for interacting with Haxcessibility:
   - Changed HAXSystem.system() to HAXSystem()
   - Changed HAXApplication.application(withPID:) to HAXApplication(pid:)
   - Fixed issues with casting between HAXElement and its subclasses
4. Modified the Application and Window classes to access HAXApplication instances via SystemAccessibility.

## Testing

The solution has been tested by:
1. Successfully building the project with `swift build`
2. Verifying that all Swift files can correctly import and use Haxcessibility types
3. Ensuring that all warnings have been addressed and the build is clean

## References

- [Objective-C and Swift Interoperability](https://developer.apple.com/documentation/swift/importing-objective-c-into-swift)
- [Module Map Format Reference](https://clang.llvm.org/docs/Modules.html#module-map-language)