# Love Connection

iOS application for long-distance couples to send "love" to each other by holding an animated heart button. When released, the partner receives a push notification with the duration information.

## Project Structure

```
love-connection/
├── iOS/                    # iOS application (SwiftUI)
├── backend/                # Backend server (Go + Gin)
├── scripts/               # Helper scripts
├── docker-compose.yml     # Docker configuration
├── Makefile              # Convenient commands
└── README.md             # This file
```

## Quick Start

### Prerequisites

- **Go 1.21+** - [Install Go](https://golang.org/dl/)
- **Docker & Docker Compose** - [Install Docker](https://www.docker.com/get-started)
- **Xcode 14+** (for iOS development)
- **PostgreSQL 15+** (or use Docker)

### 1. Initial Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd love-connection

# Run setup script
./scripts/setup.sh

# Or use Make
make setup
```

### 2. Configure Environment

Edit `.env` file (created from `backend/.env.example`):

```bash
# Required
JWT_SECRET=your-very-secure-secret-key-minimum-32-characters

# Optional (for push notifications)
APNS_KEY_PATH=/path/to/apns/key.p8
APNS_KEY_ID=your-key-id
APNS_TEAM_ID=your-team-id
APNS_BUNDLE_ID=com.yourapp.loveconnection
```

### 3. Start Services

**Option A: Using Make (Recommended)**
```bash
make start
```

**Option B: Using Docker Compose directly**
```bash
docker-compose up -d
```

**Option C: Using scripts**
```bash
./scripts/start.sh
```

The backend will be available at `http://localhost:8080`

### 4. Stop Services

```bash
make stop
# or
docker-compose down
# or
./scripts/stop.sh
```

## Development

### Backend Development

**Run backend locally (without Docker):**
```bash
make backend
```

**Run with hot reload (requires [air](https://github.com/cosmtrek/air)):**
```bash
make dev
```

**View logs:**
```bash
make logs              # All services
make logs-backend      # Backend only
make logs-db          # Database only
```

**Database operations:**
```bash
make db-shell         # Open PostgreSQL shell
make db-reset         # Reset database (WARNING: deletes all data)
```

**Build backend:**
```bash
make build-backend
```

### iOS Development

1. Open the project in Xcode:
   ```bash
   open iOS/LoveConnection.xcodeproj
   ```

2. **Configure Backend URL:**
   
   Add `Info.plist` to the project and configure:
   - `DEBUG_BACKEND_URL`: `http://localhost:8080` (or your IP for physical device)
   - `PRODUCTION_BACKEND_URL`: `https://your-production-api.com`
   
   The app automatically uses:
   - Debug builds → `DEBUG_BACKEND_URL`
   - Release builds → `PRODUCTION_BACKEND_URL`
   
   **Note:** Users cannot change the URL - it's set at build time.

3. Configure capabilities in Xcode:
   - Sign in with Apple
   - Push Notifications
   - Camera (for QR code scanning)

4. Build and run in Xcode (⌘R)

See `iOS/CONFIGURATION.md` for detailed setup instructions.

## Available Make Commands

```bash
make help          # Show all available commands
make setup         # Initial project setup
make start         # Start all services
make stop          # Stop all services
make restart       # Restart all services
make logs          # View logs
make backend       # Run backend locally
make db-shell      # Open database shell
make db-reset      # Reset database
make clean         # Clean up Docker volumes
make test-backend  # Run backend tests
make build-backend # Build backend binary
```

## API Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/apple` - Sign in with Apple
- `GET /api/user/me` - Get current user
- `POST /api/user/device-token` - Update device token
- `POST /api/pairs/request` - Create pair request
- `POST /api/pairs/respond` - Respond to pair request
- `GET /api/pairs/requests` - Get pending pair requests
- `GET /api/pairs/current` - Get current pair
- `DELETE /api/pairs/current` - Delete current pair
- `POST /api/love/send` - Send love event
- `GET /api/love/history` - Get love events history
- `GET /api/stats` - Get statistics
- `WebSocket /ws` - Real-time connection

## Testing the API

```bash
# Register a user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "username": "testuser"
  }'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Database Migrations

Migrations are automatically run on server startup from `backend/internal/database/migrations/`.

To run migrations manually:
```bash
make db-migrate
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Backend server port | `8080` |
| `DB_HOST` | PostgreSQL host | `postgres` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | PostgreSQL user | `postgres` |
| `DB_PASSWORD` | PostgreSQL password | `postgres` |
| `DB_NAME` | Database name | `loveconnection` |
| `JWT_SECRET` | JWT signing secret | **Required** |
| `APNS_KEY_PATH` | Path to APNs key file | Optional |
| `APNS_KEY_ID` | APNs key ID | Optional |
| `APNS_TEAM_ID` | APNs team ID | Optional |
| `APNS_BUNDLE_ID` | App bundle ID | Optional |

## Troubleshooting

### Backend won't start
- Check if PostgreSQL is running: `docker-compose ps`
- Check logs: `make logs-backend`
- Verify `.env` file exists and has correct values

### Database connection errors
- Ensure PostgreSQL container is running: `docker-compose ps postgres`
- Check database credentials in `.env`
- Try resetting database: `make db-reset`

### iOS app can't connect to backend
- Verify backend is running: `curl http://localhost:8080/api/user/me`
- Check `Constants.swift` has correct URL
- For physical device, use your computer's IP address instead of `localhost`

## Production Deployment

For production deployment:

1. Set strong `JWT_SECRET` (minimum 32 characters)
2. Use production PostgreSQL database
3. Configure HTTPS/TLS
4. Set up proper APNs keys
5. Update iOS app with production backend URL
6. Configure environment variables securely
7. Set up monitoring and logging

## Security Features

- HTTPS/TLS for all connections
- JWT tokens with short expiration
- Bcrypt password hashing
- Input validation
- SQL injection protection
- CORS configuration

## License

MIT License
