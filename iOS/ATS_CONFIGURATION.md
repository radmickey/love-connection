# App Transport Security (ATS) Configuration

## Current Setup

The app is configured to allow HTTP connections to the backend server at `84.252.141.42:8080` for development purposes.

## Configuration in Info.plist

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>84.252.141.42</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## What This Does

- **NSExceptionAllowsInsecureHTTPLoads**: Allows HTTP (non-HTTPS) connections to this specific IP
- **NSExceptionRequiresForwardSecrecy**: Disables forward secrecy requirement for this domain
- **NSIncludesSubdomains**: Applies to subdomains (not applicable for IP, but included for completeness)

## Security Notes

⚠️ **Important**: This configuration allows insecure HTTP connections. This is acceptable for:
- Development/testing environments
- Internal networks
- Temporary setups

❌ **Not recommended for**:
- Production apps in App Store
- Apps handling sensitive user data
- Public-facing applications

## For Production

When moving to production, you should:

1. **Set up HTTPS** on your backend server
2. **Remove or restrict this ATS exception** to only allow HTTPS
3. **Use a proper domain name** instead of IP address
4. **Configure SSL certificate** on your server

## Alternative: Disable ATS Globally (Not Recommended)

If you need to disable ATS for all domains (NOT recommended):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Warning**: This disables ATS for all connections, which is a security risk. Only use for development.

## Testing

After adding this configuration:
1. Clean build folder: `Cmd+Shift+K`
2. Rebuild the app: `Cmd+B`
3. HTTP connections to `84.252.141.42:8080` should now work

