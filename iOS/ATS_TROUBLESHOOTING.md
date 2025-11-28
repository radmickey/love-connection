# ATS Troubleshooting

If you're still getting ATS errors after adding the configuration:

## 1. Clean Build Folder

**In Xcode:**
- Product → Clean Build Folder (`Cmd+Shift+K`)
- Product → Build (`Cmd+B`)

**Or via command line:**
```bash
cd iOS/LoveConnection
xcodebuild clean -project LoveConnection.xcodeproj -scheme LoveConnection
```

## 2. Verify Info.plist is Being Used

Check that your project is using the correct Info.plist:

1. Open Xcode project
2. Select target "LoveConnection"
3. Go to **Build Settings**
4. Search for "Info.plist File"
5. Should point to: `LoveConnection/Info.plist`

## 3. Check Info.plist Location

Make sure the Info.plist you're editing is the one being used:
- The file should be in: `iOS/LoveConnection/Info.plist`
- It should be added to the Xcode project
- Check Build Settings → Info.plist File path

## 4. Restart Xcode

Sometimes Xcode caches Info.plist settings. Try:
1. Quit Xcode completely
2. Reopen the project
3. Clean and rebuild

## 5. Verify ATS Settings

Check that ATS settings are correct:
```bash
plutil -p iOS/LoveConnection/Info.plist | grep -A 20 NSAppTransportSecurity
```

Should show:
- `NSAllowsArbitraryLoads = 1` (for development)
- Or `NSExceptionDomains` with your IP

## 6. Test on Device vs Simulator

- ATS behavior can differ between simulator and device
- Try testing on a real device if simulator has issues

## 7. Check for Multiple Info.plist Files

Make sure there's only one Info.plist:
```bash
find iOS -name "Info.plist" -type f
```

## 8. For Production

**Important**: `NSAllowsArbitraryLoads = true` allows ALL HTTP connections, which is:
- ✅ OK for development/testing
- ❌ NOT recommended for App Store submission

For production, remove `NSAllowsArbitraryLoads` and use only specific domain exceptions with HTTPS.

## Current Configuration

The current setup uses `NSAllowsArbitraryLoads = true` which:
- Allows HTTP connections to any server
- Is acceptable for development
- Should be removed/changed for production

## Alternative: Use HTTPS

The best solution is to set up HTTPS on your backend:
1. Get SSL certificate (Let's Encrypt is free)
2. Configure nginx/reverse proxy with SSL
3. Update backend URL to `https://`
4. Remove ATS exceptions

