# Love Connection

iOS application for long-distance couples to send "love" to each other by holding an animated heart button. When released, the partner receives a push notification with the duration information.

## Project Structure

- `iOS/` - iOS application built with SwiftUI
- `backend/` - Backend server built with Go and Gin framework
- `docker-compose.yml` - Configuration for running PostgreSQL and backend

## Requirements

- Go 1.21+
- PostgreSQL 15+
- Docker and Docker Compose
- Xcode 14+ (for iOS development)

## Backend Setup

1. Install dependencies:
```bash
cd backend
go mod download
```

2. Configure environment variables (create `.env` file or export):
```bash
export JWT_SECRET=your-secret-key
export APNS_KEY_PATH=/path/to/apns/key.p8
export APNS_KEY_ID=your-key-id
export APNS_TEAM_ID=your-team-id
export APNS_BUNDLE_ID=com.yourapp.loveconnection
```

3. Run with Docker Compose:
```bash
docker-compose up -d
```

Or run locally:
```bash
# Make sure PostgreSQL is running
cd backend
go run cmd/server/main.go
```

## iOS App Setup

1. Open the project in Xcode
2. Update `Constants.swift` with your backend server URL
3. Configure Sign in with Apple in Xcode capabilities
4. Configure Push Notifications in Xcode capabilities

## API Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/apple` - Sign in with Apple
- `GET /api/user/me` - Get current user
- `POST /api/user/device-token` - Update device token
- `POST /api/pairs/create` - Create pair connection
- `GET /api/pairs/current` - Get current pair
- `POST /api/love/send` - Send love event
- `GET /api/love/history` - Get love events history
- `GET /api/stats` - Get statistics
- `WebSocket /ws` - Real-time connection

## Security Features

All security measures from the plan are implemented:
- HTTPS/TLS for all connections
- JWT tokens with short expiration time
- Bcrypt password hashing
- Input validation for all data
- SQL injection protection via prepared statements
- CORS configuration
- Rate limiting ready (can be added)

## Features

- User authentication (Email/Password and Sign in with Apple)
- Pair connection via QR code scanning
- Heart button with pulse animation
- Real-time updates via WebSocket
- Push notifications via APNs
- Love events history
- Statistics dashboard

## Development

### Backend Development

```bash
cd backend
go run cmd/server/main.go
```

### Database Migrations

Migrations are automatically run on server startup from `backend/internal/database/migrations/`.

### Testing

To test the API, you can use tools like Postman or curl:

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","username":"testuser"}'
```

## License

MIT License
