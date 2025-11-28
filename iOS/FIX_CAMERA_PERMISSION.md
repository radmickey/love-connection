# Fix Camera Permission Error

The error "attempted to access privacy-sensitive data without a usage description" occurs when the app tries to use the camera but the permission description is missing or not properly configured.

## Solution

The `NSCameraUsageDescription` is already in `Info.plist`, but you need to:

1. **Clean Build Folder** in Xcode:
   - Press `Cmd + Shift + K` (or Product → Clean Build Folder)

2. **Rebuild the app**:
   - Press `Cmd + B` to build
   - Or run the app again

3. **Verify Info.plist is included in the project**:
   - In Xcode, check that `Info.plist` is in the project navigator
   - Make sure it's added to the target "CoupleLoveConnection"

4. **Check Build Settings**:
   - Go to Build Settings
   - Search for "Info.plist File"
   - Make sure it points to: `LoveConnection/Info.plist`

## If the error persists:

1. **Delete Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Restart Xcode**

3. **Rebuild the project**

## Verify the key is present:

The `Info.plist` should contain:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes for pairing with your partner.</string>
```

This is already present in the file, so the issue is likely that Xcode needs to rebuild with the updated Info.plist.

