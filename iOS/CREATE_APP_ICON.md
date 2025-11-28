# Creating App Icon for Couple Love Connection

## Option 1: Using SVG (Recommended)

1. **Open the SVG file** in a vector graphics editor (Sketch, Figma, Adobe Illustrator, or online tool like https://boxy-svg.com)

2. **Export as PNG** in the following sizes:
   - 1024x1024 (App Store)
   - 180x180 (iPhone App - 60pt @3x)
   - 120x120 (iPhone App - 60pt @2x)
   - 167x167 (iPad Pro App - 83.5pt @2x)
   - 152x152 (iPad App - 76pt @2x)

3. **Add to Xcode:**
   - Open `Assets.xcassets` in Xcode
   - Select `AppIcon`
   - Drag and drop PNG files to appropriate slots

## Option 2: Using Online Icon Generator

1. Go to https://www.appicon.co or https://appicon.build
2. Upload the SVG file or a 1024x1024 PNG
3. Download the generated icon set
4. Extract and add to Xcode Assets

## Option 3: Quick Script (macOS)

If you have ImageMagick or sips installed:

```bash
# Convert SVG to PNG (requires Inkscape or rsvg-convert)
# Or use online converter first

# Then resize using sips (built-in macOS tool)
sips -z 1024 1024 AppIcon.svg --out AppIcon-1024.png
sips -z 180 180 AppIcon.svg --out AppIcon-180.png
sips -z 120 120 AppIcon.svg --out AppIcon-120.png
sips -z 167 167 AppIcon.svg --out AppIcon-167.png
sips -z 152 152 AppIcon.svg --out AppIcon-152.png
```

## Option 4: Simple Heart Icon (Quick)

If you want a simpler approach, you can use SF Symbols heart icon:

1. In Xcode, open `Assets.xcassets`
2. Create a new Image Set
3. Use SF Symbol "heart.fill" with red color
4. Or create a simple colored square with heart shape

## Current Icon Design

The SVG includes:
- White background circle
- Gradient heart (pink to red)
- Subtle inner heart for depth
- Clean, modern design suitable for App Store

## Adding to Xcode

1. Open `iOS/LoveConnection/LoveConnection.xcodeproj`
2. Navigate to `Assets.xcassets` → `AppIcon`
3. Drag PNG files to appropriate size slots:
   - **App Store**: 1024x1024
   - **iPhone**: 180x180, 120x120
   - **iPad**: 167x167, 152x152

## Notes

- Icon should not have transparency for App Store submission
- Ensure icon looks good at small sizes
- Test on device to see how it appears on home screen

