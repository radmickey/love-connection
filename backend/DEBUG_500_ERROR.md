# Debugging 500 Error on Apple Sign In

## Check Backend Logs

**On server, run:**

```bash
# View recent backend logs
docker-compose logs backend | tail -100

# Or follow logs in real-time
docker-compose logs -f backend
```

**Look for these log messages:**
- `🔵 Apple Sign In: UserIdentifier=...` - Shows the identifier being used
- `🔵 Apple Sign In: User not found, creating new user` - Shows it's trying to create
- `🔵 Apple Sign In: Creating user with apple_id=..., username=...` - Shows the values
- `❌ Apple Sign In: Failed to create user: ...` - Shows the actual error

## Common Errors and Solutions

### 1. "value too long for type character varying(255)"
**Solution:** Migration not run yet
```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);"
docker-compose restart backend
```

### 2. "duplicate key value violates unique constraint"
**Solution:** User already exists - this should be handled, but check if user lookup is working

### 3. "null value in column \"username\" violates not-null constraint"
**Solution:** Username is somehow empty - check default value logic

### 4. "relation \"users\" does not exist"
**Solution:** Database not initialized - run migrations

## Quick Diagnostic Commands

```bash
# 1. Check apple_id column length
docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT character_maximum_length FROM information_schema.columns WHERE table_name='users' AND column_name='apple_id';"

# 2. Check if user already exists
docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT id, apple_id, username FROM users WHERE apple_id LIKE '001944%';"

# 3. Check backend logs for Apple Sign In
docker-compose logs backend | grep -i "apple\|❌\|🔵" | tail -20

# 4. Test database connection
docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT COUNT(*) FROM users;"
```

## Next Steps

1. **Check logs** - See the actual error message
2. **Verify migration** - Make sure apple_id is VARCHAR(500)
3. **Check if user exists** - Maybe user already exists but lookup fails
4. **Restart backend** - After migration, restart to ensure changes apply

