#!/bin/bash
# This script fixes the imports in Haxcessibility files to use proper relative paths

set -e

cd "$(dirname "$0")/.."

# Fix import statements in header files
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXElement.h>|#import "HAXElement.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXApplication.h>|#import "HAXApplication.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXWindow.h>|#import "HAXWindow.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXView.h>|#import "HAXView.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXButton.h>|#import "HAXButton.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXSystem.h>|#import "HAXSystem.h"|g' {} \;

# Fix import statements in implementation files
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXElement.h>|#import "HAXElement.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXApplication.h>|#import "HAXApplication.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXWindow.h>|#import "HAXWindow.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXView.h>|#import "HAXView.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXButton.h>|#import "HAXButton.h"|g' {} \;
find Sources/Haxcessibility/Classes -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/HAXSystem.h>|#import "HAXSystem.h"|g' {} \;

# Fix Other Sources
find Sources/Haxcessibility/Other\ Sources -name "*.h" -type f -exec sed -i '' -e 's|#import <Haxcessibility/|#import "../Classes/|g' {} \;
find Sources/Haxcessibility/Other\ Sources -name "*.m" -type f -exec sed -i '' -e 's|#import <Haxcessibility/|#import "../Classes/|g' {} \;

echo "Haxcessibility imports fixed"