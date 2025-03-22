#!/bin/bash
# Create a Haxcessibility directory inside vendor/Haxcessibility
# to satisfy angle bracket imports like <Haxcessibility/HAXElement.h>

cd "$(dirname "$0")"
VENDOR_DIR="vendor/Haxcessibility"
INCLUDE_DIR="$VENDOR_DIR/Haxcessibility"

# Create the Haxcessibility subdirectory if it doesn't exist
mkdir -p "$INCLUDE_DIR"

# Create symbolic links to all headers from Classes and Other Sources
# This allows <Haxcessibility/Header.h> imports to work without modifying source files
for header in "$VENDOR_DIR/Classes"/*.h; do
  basename=$(basename "$header")
  ln -sf "../Classes/$basename" "$INCLUDE_DIR/$basename"
done

for header in "$VENDOR_DIR/Other Sources"/*.h; do
  basename=$(basename "$header")
  ln -sf "../Other Sources/$basename" "$INCLUDE_DIR/$basename"
done

echo "Haxcessibility symbolic links created successfully!"