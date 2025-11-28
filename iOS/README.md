# iOS App Configuration

## Backend URL Configuration

The iOS app needs to know where to connect to the backend server. There are several ways to configure this:

### 1. Default Configuration (Development)

By default, the app uses:
- **Simulator**: `http://localhost:8080`
- **Physical Device**: You need to configure the URL manually (see below)

### 2. Using Settings Screen

1. Open the app
2. Go to the "Settings" tab
3. Enter your backend URL in the "Backend URL" field
4. Tap "Save URL"

The URL will be saved and used for all API requests.

### 3. For Physical Device Testing

When testing on a physical device, you cannot use `localhost`. Instead:

1. Find your computer's IP address:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Or use
   ipconfig getifaddr en0
   ```

2. Update the backend URL in Settings to:
   ```
   http://YOUR_IP_ADDRESS:8080
   ```
   Example: `http://192.168.1.100:8080`

3. Make sure your computer and device are on the same network

4. Ensure your firewall allows connections on port 8080

### 4. For Production

Update `Constants.swift`:
```swift
static let baseURL = "https://your-production-api.com"
```

Or use the Settings screen to configure it at runtime.

## Network Requirements

- The device must be able to reach the backend server
- For local development, ensure backend is running: `make start`
- For production, use HTTPS URLs

## Troubleshooting

### "Cannot connect to server" error

1. Check if backend is running: `curl http://localhost:8080/api/user/me`
2. Verify the URL in Settings matches your backend
3. For physical device, ensure you're using your computer's IP, not `localhost`
4. Check firewall settings

### Simulator can't connect

- Make sure backend is running on `localhost:8080`
- Try `http://127.0.0.1:8080` instead

### Physical device can't connect

- Verify both device and computer are on the same Wi-Fi network
- Check that your computer's firewall allows port 8080
- Try pinging your computer's IP from the device
- Use `http://` not `https://` for local development

