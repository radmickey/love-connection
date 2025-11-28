# Building iOS Application

## Prerequisites

- **macOS** (required for iOS development)
- **Xcode 14+** - [Download from App Store](https://apps.apple.com/us/app/xcode/id497799835)
- **Apple Developer Account** (for device testing and App Store distribution)
- **CocoaPods or Swift Package Manager** (if using dependencies)

## Creating Xcode Project

Since we have the source code but no Xcode project file yet, you need to create one:

### Option 1: Create New Xcode Project (Recommended)

1. Open Xcode
2. File → New → Project
3. Choose **iOS** → **App**
4. Configure:
   - **Product Name**: `LoveConnection`
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: `com.yourcompany` (or your domain)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None (we'll add files manually)
5. Save location: `/Users/radmickey/MyProjects/love-connection/iOS/`
6. Click **Create**

### Option 2: Use Command Line

```bash
cd /Users/radmickey/MyProjects/love-connection/iOS

# Create Xcode project structure
xcodebuild -project LoveConnection.xcodeproj -list 2>/dev/null || \
swift package init --type executable
```

## Adding Source Files to Xcode

1. In Xcode, right-click on the project name in the navigator
2. Select **Add Files to "LoveConnection"...**
3. Navigate to `LoveConnection/` folder
4. Select all folders:
   - `App/`
   - `Models/`
   - `Services/`
   - `Utilities/`
   - `Views/`
5. Make sure **"Copy items if needed"** is **unchecked**
6. Make sure **"Create groups"** is selected
7. Make sure your target is checked
8. Click **Add**

## Project Configuration

### 1. Set Deployment Target

1. Select project in navigator
2. Select **LoveConnection** target
3. Go to **General** tab
4. Set **iOS Deployment Target** to **16.0** (or your minimum version)

### 2. Add Info.plist

1. Right-click on project → **New File**
2. Choose **Property List**
3. Name it `Info.plist`
4. Add it to target
5. Copy content from `LoveConnection/Info.plist` or add manually:
   ```xml
   <key>DEBUG_BACKEND_URL</key>
   <string>http://localhost:8080</string>
   <key>PRODUCTION_BACKEND_URL</key>
   <string>https://api.loveconnection.app</string>
   ```

### 3. Configure Capabilities

1. Select project → **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add:
   - **Sign in with Apple**
   - **Push Notifications**
   - **Camera** (for QR code scanning)

### 4. Configure Signing

1. Select your **Team** in Signing & Capabilities
2. Xcode will automatically create a provisioning profile

## Building the App

### For Simulator

1. Select a simulator from device menu (e.g., iPhone 15)
2. Press **⌘R** (or Product → Run)
3. Wait for build to complete
4. App will launch in simulator

### For Physical Device

1. Connect your iPhone via USB
2. Trust the computer on your iPhone if prompted
3. Select your device from device menu
4. Press **⌘R**
5. On first run, you may need to:
   - Go to Settings → General → VPN & Device Management
   - Trust your developer certificate

### Build Only (without running)

```bash
# From terminal
cd /Users/radmickey/MyProjects/love-connection/iOS
xcodebuild -project LoveConnection.xcodeproj \
  -scheme LoveConnection \
  -configuration Debug \
  -sdk iphonesimulator \
  build
```

## Build Configurations

### Debug Build
- Uses `DEBUG_BACKEND_URL` from Info.plist
- Includes debug symbols
- No code optimization

### Release Build
- Uses `PRODUCTION_BACKEND_URL` from Info.plist
- Code optimization enabled
- Smaller binary size

To switch:
1. Product → Scheme → Edit Scheme
2. Select **Run** → **Info** tab
3. Change **Build Configuration** to **Release**

## Creating Archive (for Distribution)

1. Select **Any iOS Device** from device menu
2. Product → Archive
3. Wait for archive to complete
4. Organizer window will open
5. You can:
   - **Distribute App** (to App Store or TestFlight)
   - **Export** (for Ad Hoc or Enterprise distribution)

## Troubleshooting

### "No such module" errors
- Clean build folder: **⌘⇧K** then **⌘B**
- Check that all files are added to target

### Signing errors
- Select your team in Signing & Capabilities
- Make sure you have valid Apple Developer account

### Build fails
- Check Xcode version (14+ required)
- Check iOS deployment target compatibility
- Clean build folder: Product → Clean Build Folder (**⌘⇧K**)

### Simulator won't launch
- Reset simulator: Device → Erase All Content and Settings
- Or delete and recreate simulator

## Quick Start Script

Create a script to automate project setup:

```bash
#!/bin/bash
# setup-xcode.sh

cd /Users/radmickey/MyProjects/love-connection/iOS

# Open in Xcode (if project exists)
if [ -f "LoveConnection.xcodeproj/project.pbxproj" ]; then
    open LoveConnection.xcodeproj
else
    echo "Please create Xcode project first (see BUILD.md)"
    echo "Then add all files from LoveConnection/ folder to the project"
fi
```

