# Troubleshooting 500 Error on Apple Sign In

## Step 1: Verify code is updated on server

```bash
cd ~/love-connection
git pull
docker-compose restart backend
```

## Step 2: Check migration status

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT character_maximum_length FROM information_schema.columns WHERE table_name='users' AND column_name='apple_id';"
```

**Must show:** `500` (not `255`)

If it shows `255`, run:
```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);"
docker-compose restart backend
```

## Step 3: View logs in real-time

```bash
sudo docker-compose logs -f backend
```

Then try Apple Sign In in the app. You should see logs starting with:
- `🔵 Apple Sign In: Handler called`
- `🔵 Apple Sign In: UserIdentifier=...`

## Step 4: Check for specific errors

Look for these log patterns:
- `❌ Apple Sign In: Failed to create user` - Database error (likely column length issue)
- `❌ Apple Sign In: Database query error` - Query failed
- `❌ Apple Sign In: Failed to generate token` - Token generation failed

## Step 5: Test database connection

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT COUNT(*) FROM users;"
```

## Step 6: Check backend container status

```bash
sudo docker-compose ps
```

Make sure backend container is running and healthy.

## Step 7: View full error response

If logs don't show details, check the actual error response:
```bash
curl -X POST https://love-couple-connect.duckdns.org/api/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"user_identifier":"test","identity_token":"test","authorization_code":"test"}'
```

