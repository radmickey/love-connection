# Check Migration Status

To verify that the `apple_id` column migration has been applied:

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "SELECT character_maximum_length FROM information_schema.columns WHERE table_name='users' AND column_name='apple_id';"
```

**Expected result:** Should show `500`

**If it shows `255`**, run the migration:

```bash
sudo docker-compose exec postgres psql -U postgres -d loveconnection -c "ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);"
```

Then verify again and restart the backend:

```bash
docker-compose restart backend
```

