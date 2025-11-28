# Building Release Version for Production

This guide explains how to build a Release version of the iOS app that connects to your production backend.

## Backend Configuration

The production backend URL is configured in `Info.plist`:
- **Key**: `PRODUCTION_BACKEND_URL`
- **Value**: `http://84.252.141.42:8080`

## Building Release Version in Xcode

### Method 1: Using Xcode UI

1. **Open the project in Xcode**
   ```bash
   open iOS/LoveConnection/LoveConnection.xcodeproj
   ```

2. **Select Release Scheme**
   - In the top toolbar, click on the scheme selector (next to the play/stop buttons)
   - Select "LoveConnection" scheme
   - Click on "Edit Scheme..." (or press `⌘<`)
   - Go to "Run" → "Info" tab
   - Set "Build Configuration" to **Release**

3. **Select Target Device**
   - Choose a physical device or "Any iOS Device" for archive
   - For simulator testing, select a simulator (but use Debug for simulator)

4. **Build for Archive**
   - Go to **Product** → **Archive** (or press `⌘B` then `⌘Shift+B`)
   - Wait for the build to complete

5. **Distribute App**
   - After archive completes, Organizer window will open
   - Click "Distribute App"
   - Choose distribution method:
     - **App Store Connect** - for App Store submission
     - **Ad Hoc** - for testing on registered devices
     - **Enterprise** - for enterprise distribution
     - **Development** - for development builds

### Method 2: Using Command Line

```bash
# Build Release for device
xcodebuild -project iOS/LoveConnection/LoveConnection.xcodeproj \
  -scheme LoveConnection \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  clean build

# Create archive
xcodebuild -project iOS/LoveConnection/LoveConnection.xcodeproj \
  -scheme LoveConnection \
  -configuration Release \
  -archivePath ./build/LoveConnection.xcarchive \
  archive
```

## Verification

After building, verify the backend URL:

1. Run the app on a device
2. Go to Settings (if you have a settings screen)
3. Check that it shows: `http://84.252.141.42:8080`

Or check in code by adding a debug print:
```swift
print("Backend URL: \(Config.shared.baseURL)")
```

## Important Notes

- **Debug builds** use `DEBUG_BACKEND_URL` (default: `http://localhost:8080`)
- **Release builds** use `PRODUCTION_BACKEND_URL` (set to: `http://84.252.141.42:8080`)
- The URL is determined at **build time**, not runtime
- Make sure your backend is accessible from the internet (firewall, security groups, etc.)

## Backend Accessibility

Ensure your backend at `84.252.141.42:8080` is:
- ✅ Accessible from the internet
- ✅ Firewall allows incoming connections on port 8080
- ✅ CORS configured to allow requests from iOS app
- ✅ SSL/TLS configured (recommended for production - use `https://`)

## Switching Between Debug and Release

- **Debug**: Product → Scheme → Edit Scheme → Run → Build Configuration = Debug
- **Release**: Product → Scheme → Edit Scheme → Run → Build Configuration = Release

Or use the scheme selector in Xcode toolbar.

