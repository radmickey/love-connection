# iOS App Setup

## Quick Start

1. Open the project in Xcode:
   ```bash
   open iOS/LoveConnection.xcodeproj
   ```

2. **Configure Backend URL** (see `CONFIGURATION.md` for details):
   - Add `Info.plist` to the project
   - Set `DEBUG_BACKEND_URL` for development
   - Set `PRODUCTION_BACKEND_URL` for production

3. Configure capabilities in Xcode:
   - Sign in with Apple
   - Push Notifications
   - Camera (for QR code scanning)

4. Build and run (⌘R)

## Backend URL Configuration

The app uses different URLs for Debug and Release builds:

- **Debug**: Reads from `Info.plist` → `DEBUG_BACKEND_URL` (default: `http://localhost:8080`)
- **Release**: Reads from `Info.plist` → `PRODUCTION_BACKEND_URL` (default: `https://api.loveconnection.app`)

**Users cannot change the URL** - it's configured at build time through `Info.plist`.

See `CONFIGURATION.md` for detailed setup instructions.

## For Physical Device Testing

When testing on a physical device:

1. Find your computer's IP:
   ```bash
   ipconfig getifaddr en0
   ```

2. Update `DEBUG_BACKEND_URL` in `Info.plist`:
   ```
   http://YOUR_IP:8080
   ```

3. Ensure device and computer are on the same Wi-Fi network

4. Make sure backend is running: `make start`

## Project Structure

```
LoveConnection/
├── App/              # App entry point and state
├── Models/           # Data models
├── Services/         # API, Auth, Notifications, WebSocket
├── Views/            # SwiftUI views
│   ├── Auth/        # Login, Sign up
│   ├── Pairing/     # QR scanning, pair requests
│   ├── Main/        # Heart button, tabs
│   ├── History/     # Love events history
│   ├── Stats/       # Statistics
│   └── Settings/    # Settings screen
└── Utilities/        # Helpers, Config, Constants
```
