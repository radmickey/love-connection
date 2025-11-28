# Fixing Entitlements Error

If you see the error: `no valid "aps-environment" entitlement string found for application`

## Quick Fix in Xcode

1. **Open Xcode project:**
   ```bash
   open iOS/LoveConnection/LoveConnection.xcodeproj
   ```

2. **Select your target:**
   - Click on the project in Project Navigator
   - Select "LoveConnection" target

3. **Go to Signing & Capabilities tab:**
   - Click the "+ Capability" button
   - Add "Push Notifications"
   - This will automatically add the `aps-environment` entitlement

4. **Verify entitlements file is linked:**
   - Go to "Build Settings" tab
   - Search for "Code Signing Entitlements"
   - Should be: `LoveConnection/LoveConnection.entitlements`
   - If empty, set it manually

5. **Check entitlements file:**
   - Open `LoveConnection.entitlements` in Xcode
   - Should contain:
     ```xml
     <key>aps-environment</key>
     <string>development</string>
     ```
   - For Release builds, you may need `production` instead

6. **Clean and rebuild:**
   - Product → Clean Build Folder (Cmd+Shift+K)
   - Product → Build (Cmd+B)

## Alternative: Manual Entitlements Setup

If the above doesn't work:

1. **Ensure entitlements file is in project:**
   - Right-click project → Add Files to "LoveConnection"
   - Select `LoveConnection.entitlements`
   - Uncheck "Copy items if needed"
   - Check "LoveConnection" target

2. **Update Build Settings:**
   - Build Settings → Code Signing Entitlements
   - Set to: `LoveConnection/LoveConnection.entitlements`

3. **For Release builds:**
   - You may need to change `aps-environment` from `development` to `production`
   - Or create separate entitlements files for Debug/Release

## Testing

- Push notifications require a real device (not simulator)
- Make sure you're signed with a valid development team
- Check that provisioning profile includes Push Notifications capability

