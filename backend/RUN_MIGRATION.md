# Run Migration to Increase apple_id Length

## On Server

Execute this command to increase apple_id column length from 255 to 500:

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);"
```

## Verify Migration

After running, verify the change:

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT character_maximum_length FROM information_schema.columns WHERE table_name='users' AND column_name='apple_id';"
```

Should show: `500`

## After Migration

Restart backend to ensure it picks up the changes:

```bash
docker-compose restart backend
```

Or if running manually, just restart the backend process.

## Why This Is Needed

Apple userIdentifier can be longer than 255 characters. The current limit causes INSERT to fail with "value too long" error.

