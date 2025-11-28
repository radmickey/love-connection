# Setting Up Entitlements in Xcode

This guide explains how to configure entitlements for Push Notifications and Sign in with Apple.

## Steps

1. **Open the Xcode project**
   ```bash
   open iOS/LoveConnection/LoveConnection.xcodeproj
   ```

2. **Add the entitlements file to the project**
   - In Xcode, right-click on the `LoveConnection` folder in the Project Navigator
   - Select "Add Files to 'LoveConnection'..."
   - Navigate to `iOS/LoveConnection/LoveConnection.entitlements`
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure "LoveConnection" target is selected
   - Click "Add"

3. **Configure the entitlements in Build Settings**
   - Select the project in the Project Navigator
   - Select the "LoveConnection" target
   - Go to the "Signing & Capabilities" tab
   - Click "+ Capability" and add:
     - **Push Notifications**
     - **Sign in with Apple**
   - These capabilities will automatically update the entitlements file

4. **Link the entitlements file in Build Settings**
   - Go to "Build Settings" tab
   - Search for "Code Signing Entitlements"
   - Set the value to: `LoveConnection/LoveConnection.entitlements`

5. **Configure Signing**
   - In "Signing & Capabilities" tab
   - Select your development team
   - Xcode will automatically manage provisioning profiles

## Notes

- **Simulator Limitations**: 
  - Push notifications don't work fully in the iOS Simulator
  - Apple Sign In may require additional configuration in simulator
  - For full testing, use a real device

- **Development vs Production**:
  - The entitlements file uses `development` for `aps-environment`
  - For production builds, you may need to create a separate entitlements file or use build configurations

## Verification

After setup, you should see:
- No errors about missing `aps-environment` entitlement
- Apple Sign In button works (may require real device)
- Push notifications work on real devices

