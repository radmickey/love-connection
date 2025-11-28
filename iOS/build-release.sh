#!/bin/bash

set -e

PROJECT_PATH="iOS/LoveConnection/LoveConnection.xcodeproj"
SCHEME="LoveConnection"
ARCHIVE_PATH="./build/LoveConnection.xcarchive"

echo "🧹 Cleaning build folder..."
xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Release

echo "📦 Building Release archive..."
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS'

echo "✅ Archive created at: $ARCHIVE_PATH"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Go to Window → Organizer"
echo "3. Select your archive"
echo "4. Click 'Distribute App'"

