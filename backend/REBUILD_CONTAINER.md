# How to Rebuild Backend Container After Code Changes

Since the backend code is compiled into the Docker image, you need to **rebuild** the container after code changes.

## Quick Rebuild (Recommended)

```bash
cd ~/love-connection
git pull
docker-compose build backend
docker-compose up -d backend
```

Or in one command:
```bash
cd ~/love-connection && git pull && docker-compose build backend && docker-compose up -d backend
```

## Verify the rebuild worked

```bash
# Check logs - you should see the new log messages
sudo docker-compose logs -f backend
```

Then try Apple Sign In - you should see logs like:
```
🔵 Apple Sign In: Handler called
🔵 Apple Sign In: UserIdentifier=...
```

## Alternative: Rebuild without cache (if changes don't appear)

```bash
cd ~/love-connection
git pull
docker-compose build --no-cache backend
docker-compose up -d backend
```

## Check current container status

```bash
docker-compose ps
```

## View container logs

```bash
sudo docker-compose logs -f backend
```

