# iOS App Configuration Guide

## Backend URL Configuration

The app uses different backend URLs for Debug and Release builds, configured through `Info.plist`.

## Setup Instructions

### 1. Add Info.plist to Xcode Project

1. In Xcode, right-click on `LoveConnection` folder
2. Select "New File..."
3. Choose "Property List"
4. Name it `Info.plist`
5. Add it to the target

### 2. Configure Backend URLs

Open `Info.plist` and add these keys:

```xml
<key>DEBUG_BACKEND_URL</key>
<string>http://localhost:8080</string>
<key>PRODUCTION_BACKEND_URL</key>
<string>https://api.loveconnection.app</string>
```

Or in Xcode's Property List editor:
- `DEBUG_BACKEND_URL`: `http://localhost:8080`
- `PRODUCTION_BACKEND_URL`: `https://your-production-api.com`

### 3. For Physical Device Testing (Debug)

When testing on a physical device, you need to use your computer's IP address instead of `localhost`:

1. Find your computer's IP:
   ```bash
   ipconfig getifaddr en0
   ```

2. Update `DEBUG_BACKEND_URL` in `Info.plist`:
   ```
   http://192.168.1.100:8080
   ```
   (Replace with your actual IP)

3. Make sure your device and computer are on the same Wi-Fi network

### 4. Build Configurations

The app automatically uses:
- **Debug builds**: `DEBUG_BACKEND_URL` from Info.plist (or `http://localhost:8080` as fallback)
- **Release builds**: `PRODUCTION_BACKEND_URL` from Info.plist (or `https://api.loveconnection.app` as fallback)

### 5. Custom Build Configurations (Optional)

If you want to create custom configurations (e.g., Staging):

1. In Xcode: Project → Info → Configurations
2. Duplicate Debug configuration → Name it "Staging"
3. Create a new Info.plist file for Staging
4. Update `Config.swift` to handle custom configurations

## Current Implementation

The `Config.swift` class reads the URL from `Info.plist`:
- Debug: Reads `DEBUG_BACKEND_URL`
- Release: Reads `PRODUCTION_BACKEND_URL`

Users cannot change the URL from within the app - it's set at build time.

## Troubleshooting

### URL not working
- Check that `Info.plist` is added to the target
- Verify the keys are spelled correctly
- Check that the URL doesn't have trailing slashes

### Physical device can't connect
- Use your computer's IP address, not `localhost`
- Ensure both devices are on the same network
- Check firewall settings on your computer

