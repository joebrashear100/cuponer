#!/bin/bash
#
# add_to_xcode.sh
# Helper script to add files to Xcode project
#
# Usage: ./add_to_xcode.sh <file_path> <target_name>
# Example: ./add_to_xcode.sh Furg/Utils/UIVerifier.swift Furg

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file_path> <target_name>"
    echo "Example: $0 Furg/Utils/UIVerifier.swift Furg"
    exit 1
fi

FILE_PATH="$1"
TARGET="$2"
PROJECT_FILE="Furg.xcodeproj/project.pbxproj"

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "📝 This script requires manual Xcode setup."
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Open Furg.xcodeproj in Xcode"
echo "2. Right-click on the '$TARGET' group in Project Navigator"
echo "3. Select 'Add Files to $TARGET...'"
echo "4. Navigate to: $FILE_PATH"
echo "5. Ensure '$TARGET' target is checked"
echo "6. Click 'Add'"
echo ""
echo "The file '$FILE_PATH' will be added to the Xcode project."
echo ""
echo "To verify the file was added:"
echo "  xcodebuild -list"
echo ""
