# Checking Apple Sign In Backend Logs

## To see detailed error logs:

**If using Docker Compose:**
```bash
docker-compose logs -f backend | grep -i "apple\|error\|❌"
```

**Or view all backend logs:**
```bash
docker-compose logs -f backend
```

**If running directly:**
```bash
# Check logs where backend is running
# Look for lines with:
# - 🔵 Apple Sign In: ...
# - ❌ Apple Sign In: Failed to create user: ...
# - ✅ Apple Sign In: User created with ID=...
```

## Common Error Messages:

### 1. "value too long for type character varying(255)"
**Solution:** Run migration to increase apple_id length:
```sql
ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);
```

### 2. "duplicate key value violates unique constraint"
**Solution:** User already exists, this is normal - should find existing user instead

### 3. "null value in column \"username\" violates not-null constraint"
**Solution:** Username is empty - check that default "User" is being set

### 4. "relation \"users\" does not exist"
**Solution:** Run migrations:
```bash
# In backend directory
go run cmd/server/main.go
# Or check migrations were run
```

## Quick Fix Commands:

```bash
# 1. Check if migration is needed
docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT character_maximum_length FROM information_schema.columns WHERE table_name='users' AND column_name='apple_id';"

# 2. Run migration if needed
docker-compose exec postgres psql -U postgres -d loveconnection -c "ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);"

# 3. Check backend logs
docker-compose logs backend | tail -50
```

## Expected Log Flow:

When Apple Sign In works correctly, you should see:
```
🔵 Apple Sign In: UserIdentifier=001944.69f7f6585fbf4892a26069aef898dfdc.1923, Username=...
🔵 Apple Sign In: User not found, creating new user
🔵 Apple Sign In: Creating user with apple_id=..., username=...
✅ Apple Sign In: User created with ID=...
```

If user already exists:
```
🔵 Apple Sign In: UserIdentifier=...
✅ Found existing user
```

