# Fix "database does not exist" Error

This error occurs when the PostgreSQL database hasn't been created yet.

## Solution: Create the database

```bash
cd ~/love-connection

# Check if postgres container is running
docker-compose ps postgres

# Connect to postgres and create the database
sudo docker-compose exec postgres psql -U postgres -c "CREATE DATABASE loveconnection;"

# Verify it was created
sudo docker-compose exec postgres psql -U postgres -c "\l" | grep loveconnection

# Restart backend to run migrations
docker-compose restart backend
```

## Alternative: Recreate everything (if you don't need existing data)

```bash
cd ~/love-connection

# Stop everything
docker-compose down

# Remove volumes (WARNING: This deletes all data!)
docker volume rm love-connection_postgres_data

# Start everything fresh
docker-compose up -d

# Wait for postgres to be ready, then create database
sleep 5
sudo docker-compose exec postgres psql -U postgres -c "CREATE DATABASE loveconnection;"

# Restart backend
docker-compose restart backend
```

## Check database status

```bash
# List all databases
sudo docker-compose exec postgres psql -U postgres -c "\l"

# Check if loveconnection exists
sudo docker-compose exec postgres psql -U postgres -c "SELECT datname FROM pg_database WHERE datname='loveconnection';"
```

