# Creating Xcode Project - Step by Step Guide

## Method 1: Using Xcode GUI (Recommended)

### Step 1: Open Xcode
1. Open **Xcode** (install from App Store if needed)
2. If you see "Welcome to Xcode" window, click **Create a new Xcode project**
3. Or go to **File → New → Project**

### Step 2: Choose Template
1. Select **iOS** tab at the top
2. Choose **App** template
3. Click **Next**

### Step 3: Configure Project
Fill in the form:

- **Product Name**: `LoveConnection`
- **Team**: Select your Apple Developer team (or "None" for now)
- **Organization Identifier**: `com.yourcompany` (or your domain, e.g., `com.radmickey`)
- **Bundle Identifier**: Will auto-fill as `com.yourcompany.LoveConnection`
- **Interface**: Select **SwiftUI**
- **Language**: Select **Swift**
- **Storage**: Select **None** ✅
  - *Why?* We use backend API for data storage, not local Core Data/CloudKit
- **Testing System**: Select **XCTest** ✅
  - *Why?* Standard iOS testing framework (you can add tests later if needed)
- **Include Tests**: You can check or uncheck (optional)

Click **Next**

### Step 4: Choose Location
1. Navigate to: `/Users/radmickey/MyProjects/love-connection/iOS/`
2. **Important**: Make sure "Create Git repository" is **unchecked** (we already have git)
3. Click **Create**

### Step 5: Delete Default Files
Xcode created some default files. Delete them:

1. In Project Navigator (left sidebar), find:
   - `ContentView.swift` (we have our own)
   - `LoveConnectionApp.swift` (we have our own)
   - `Assets.xcassets` (optional, keep if you want)
   - `Preview Content` folder (optional)

2. Right-click each → **Delete** → **Move to Trash**

### Step 6: Add Existing Source Files
1. Right-click on **LoveConnection** (blue project icon) in Project Navigator
2. Select **Add Files to "LoveConnection"...**
3. Navigate to `iOS/LoveConnection/` folder
4. Select **all folders and files**:
   - `App/`
   - `Models/`
   - `Services/`
   - `Utilities/`
   - `Views/`
   - `LoveConnectionApp.swift`
   - `Info.plist`
5. **Important settings**:
   - ✅ **Copy items if needed**: **UNCHECKED** (files already in right place)
   - ✅ **Create groups**: **CHECKED**
   - ✅ **Add to targets**: **LoveConnection** should be **CHECKED**
6. Click **Add**

### Step 7: Configure Project Settings

#### 7.1 Set Deployment Target
1. Click on **LoveConnection** project (blue icon) in navigator
2. Select **LoveConnection** target
3. Go to **General** tab
4. Under **Deployment Info**, set **iOS** to **16.0** (or your minimum version)

#### 7.2 Configure Info.plist
1. In Project Navigator, find `Info.plist`
2. If it's not there, right-click project → **New File** → **Property List** → Name it `Info.plist`
3. Open `Info.plist` and add (or verify these keys exist):
   ```xml
   <key>DEBUG_BACKEND_URL</key>
   <string>http://localhost:8080</string>
   <key>PRODUCTION_BACKEND_URL</key>
   <string>https://api.loveconnection.app</string>
   ```

#### 7.3 Add Capabilities
1. Still in target settings, go to **Signing & Capabilities** tab
2. Click **+ Capability** button
3. Add these capabilities:
   - **Sign in with Apple**
   - **Push Notifications**
   - **Camera** (for QR code scanning)

#### 7.4 Configure Signing
1. In **Signing & Capabilities** tab
2. Select your **Team** (or "None" for simulator-only)
3. Xcode will automatically manage provisioning profile

### Step 8: Verify Build Settings
1. Go to **Build Settings** tab
2. Search for "Swift Language Version"
3. Make sure it's set to **Swift 5** or latest

### Step 9: Build and Run
1. Select a simulator from device menu (top toolbar, e.g., "iPhone 15")
2. Press **⌘R** (or Product → Run)
3. Wait for build to complete
4. App should launch in simulator!

## Method 2: Using Command Line (Advanced)

If you prefer command line, you can use `xcodegen` or create project manually:

```bash
cd /Users/radmickey/MyProjects/love-connection/iOS

# Install xcodegen (optional)
brew install xcodegen

# Create project.yml (see below)
# Then run: xcodegen generate
```

## Troubleshooting

### "Cannot find 'ContentView' in scope"
- Make sure you deleted the default `ContentView.swift` that Xcode created
- Our `ContentView.swift` is in `Views/` folder

### "No such module" errors
- Clean build: **⌘⇧K** (Product → Clean Build Folder)
- Build again: **⌘B**

### Files not appearing in project
- Make sure files were added to the target
- Check File Inspector (right panel) → Target Membership → LoveConnection should be checked

### Signing errors
- For simulator: You can use "None" for team
- For device: You need Apple Developer account ($99/year)

### Build fails with Swift version
- Check Xcode version (14+ required)
- Update Swift Language Version in Build Settings

## Quick Checklist

- [ ] Xcode project created
- [ ] Default files deleted
- [ ] All source files added to project
- [ ] Info.plist configured
- [ ] iOS Deployment Target set to 16.0
- [ ] Capabilities added (Sign in with Apple, Push Notifications, Camera)
- [ ] Signing configured
- [ ] Project builds successfully (⌘B)
- [ ] App runs in simulator (⌘R)

## Next Steps

After project is created and builds successfully:

1. **Test backend connection**: Make sure backend is running (`make start`)
2. **Test on device**: Connect iPhone and run on physical device
3. **Configure for production**: Update `PRODUCTION_BACKEND_URL` in Info.plist

