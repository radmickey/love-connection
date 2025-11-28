# Quick Fix: nginx Not Listening on Port 80

## Problem
nginx is running but port 80 is not listening.

## Solution

### Option 1: Use Fix Script (Recommended)

On your server:
```bash
sudo ./scripts/fix-nginx-port80.sh
```

### Option 2: Manual Fix

**1. Check nginx configuration:**
```bash
sudo nginx -t
```

**2. Make sure site is enabled:**
```bash
sudo ln -sf /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
```

**3. Reload nginx:**
```bash
sudo systemctl reload nginx
```

**4. If that doesn't work, restart nginx:**
```bash
sudo systemctl restart nginx
```

**5. Check if port 80 is now listening:**
```bash
sudo netstat -tlnp | grep :80
```

Should show: `0.0.0.0:80` or `*:80`

**6. Check nginx error log if still not working:**
```bash
sudo tail -20 /var/log/nginx/error.log
```

## Common Issues

### Issue: nginx config has errors
**Fix:**
```bash
sudo nginx -t
# Fix any errors shown
sudo systemctl reload nginx
```

### Issue: Site not enabled
**Fix:**
```bash
sudo ln -sf /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Issue: Port conflict
**Fix:**
```bash
# Check what's using port 80
sudo lsof -i :80
# Stop conflicting service or change nginx config
```

### Issue: nginx not starting
**Fix:**
```bash
# Check status
sudo systemctl status nginx

# Check error log
sudo tail -50 /var/log/nginx/error.log

# Try starting manually
sudo nginx
```

## After Fix

Once port 80 is listening, run Certbot:
```bash
sudo certbot --nginx -d love-couple-connect.duckdns.org
```

