#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SVG_FILE="$PROJECT_ROOT/iOS/LoveConnection/Assets/AppIcon.svg"
OUTPUT_DIR="$PROJECT_ROOT/iOS/LoveConnection/LoveConnection/Assets/AppIcon"

cd "$PROJECT_ROOT"

echo "🎨 Generating App Icon from SVG..."
echo "SVG: $SVG_FILE"
echo "Output: $OUTPUT_DIR"

if ! command -v rsvg-convert &> /dev/null && ! command -v convert &> /dev/null; then
    echo "❌ Image conversion tools not found."
    echo ""
    echo "Please install one of:"
    echo "  - librsvg (brew install librsvg) for rsvg-convert"
    echo "  - ImageMagick (brew install imagemagick) for convert"
    echo ""
    echo "Or use online converter:"
    echo "  1. Go to https://cloudconvert.com/svg-to-png"
    echo "  2. Upload $SVG_FILE"
    echo "  3. Set size to 1024x1024"
    echo "  4. Download and save as AppIcon-1024.png"
    echo "  5. Then resize using: sips -z 180 180 AppIcon-1024.png --out AppIcon-180.png"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > "$OUTPUT_DIR/AppIcon-1024.png"
    rsvg-convert -w 180 -h 180 "$SVG_FILE" > "$OUTPUT_DIR/AppIcon-180.png"
    rsvg-convert -w 120 -h 120 "$SVG_FILE" > "$OUTPUT_DIR/AppIcon-120.png"
    rsvg-convert -w 167 -h 167 "$SVG_FILE" > "$OUTPUT_DIR/AppIcon-167.png"
    rsvg-convert -w 152 -h 152 "$SVG_FILE" > "$OUTPUT_DIR/AppIcon-152.png"
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick convert..."
    convert -background none -resize 1024x1024 "$SVG_FILE" "$OUTPUT_DIR/AppIcon-1024.png"
    convert -background none -resize 180x180 "$SVG_FILE" "$OUTPUT_DIR/AppIcon-180.png"
    convert -background none -resize 120x120 "$SVG_FILE" "$OUTPUT_DIR/AppIcon-120.png"
    convert -background none -resize 167x167 "$SVG_FILE" "$OUTPUT_DIR/AppIcon-167.png"
    convert -background none -resize 152x152 "$SVG_FILE" "$OUTPUT_DIR/AppIcon-152.png"
fi

echo "✅ Icons generated in $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Navigate to Assets.xcassets → AppIcon"
echo "3. Drag PNG files from $OUTPUT_DIR to appropriate slots"

