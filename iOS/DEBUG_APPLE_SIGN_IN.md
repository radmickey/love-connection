# Debugging Apple Sign In Issues

## Common Issues

### 1. Nothing happens when clicking button

**Possible causes:**
- Running on simulator (Apple Sign In doesn't work fully in simulator)
- Entitlements not configured
- Capability not added in Xcode

**Solutions:**

1. **Test on real device** - Apple Sign In requires a real device
2. **Check entitlements:**
   - Open Xcode
   - Select target → Signing & Capabilities
   - Make sure "Sign in with Apple" capability is added
   - Check that `LoveConnection.entitlements` file exists and contains:
     ```xml
     <key>com.apple.developer.applesignin</key>
     <array>
         <string>Default</string>
     </array>
     ```

3. **Check Build Settings:**
   - Code Signing Entitlements should point to: `LoveConnection/LoveConnection.entitlements`

4. **Check console logs:**
   - Look for messages starting with 🔵 (button tapped)
   - Look for ❌ (errors)
   - Look for ⚠️ (warnings)

### 2. Error: "no valid aps-environment entitlement"

This is a different issue (push notifications), but can affect Apple Sign In setup.

**Solution:**
- Add "Push Notifications" capability in Xcode
- Make sure entitlements file includes `aps-environment`

### 3. Error: "Authorization failed" or Code 1001

**Possible causes:**
- Entitlements not properly configured
- App not signed with correct team
- Bundle ID mismatch

**Solutions:**
1. Clean build folder: `Cmd+Shift+K`
2. Check signing: Target → Signing & Capabilities → Team
3. Verify Bundle ID matches in:
   - Xcode project settings
   - Apple Developer portal
   - Entitlements file

### 4. Button appears but doesn't respond

**Check:**
- Is button disabled? (check `.disabled()` modifier)
- Are there any overlays blocking the button?
- Check console for any errors

### 5. Works in simulator but not on device

**Note:** Apple Sign In has limited support in simulator. Always test on real device.

## Debugging Steps

1. **Add logging** (already added in code):
   - Check console for 🔵, ✅, ❌, ⚠️ messages
   - These show the flow of Apple Sign In

2. **Check entitlements file:**
   ```bash
   cat iOS/LoveConnection/LoveConnection.entitlements
   ```

3. **Verify in Xcode:**
   - Target → Signing & Capabilities
   - Should see "Sign in with Apple" capability
   - Should see "Push Notifications" capability (if using)

4. **Test on real device:**
   - Connect iPhone/iPad
   - Build and run on device
   - Try Apple Sign In

5. **Check Apple Developer account:**
   - App ID should have "Sign in with Apple" enabled
   - Provisioning profile should include this capability

## Quick Test

1. Run on **real device** (not simulator)
2. Click "Sign in with Apple"
3. Check console for:
   - `🔵 Apple Sign In button tapped` - button works
   - `🔵 Apple Sign In completion handler called` - system responded
   - `✅ Got credentials` - credentials received
   - `✅ Sign in successful` - backend accepted

If you don't see "button tapped", the button might not be properly connected.

## Current Code Features

The updated code now includes:
- ✅ Debug logging (🔵, ✅, ❌, ⚠️)
- ✅ Error messages displayed to user
- ✅ Alert for errors
- ✅ Better error handling

Check the console output to see where the flow stops.

