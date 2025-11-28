# How to View Backend Logs

## View all backend logs (last 50 lines)
```bash
sudo docker-compose logs backend | tail -50
```

## View logs in real-time (follow mode)
```bash
sudo docker-compose logs -f backend
```

## View only Apple Sign In related logs
```bash
sudo docker-compose logs backend | grep -E "(Apple Sign In|❌|✅|🔵)"
```

## View last 100 lines with Apple Sign In logs
```bash
sudo docker-compose logs --tail=100 backend | grep -E "(Apple Sign In|❌|✅|🔵)"
```

## View all logs from all services
```bash
sudo docker-compose logs
```

## View logs since last 10 minutes
```bash
sudo docker-compose logs --since 10m backend
```

## View logs with timestamps
```bash
sudo docker-compose logs -t backend
```

## Recommended: Watch logs in real-time and filter for Apple Sign In
```bash
sudo docker-compose logs -f backend | grep --line-buffered -E "(Apple Sign In|❌|✅|🔵|POST.*apple)"
```

