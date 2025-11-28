# Setting Up HTTPS for Backend Server

This guide explains how to set up HTTPS for your Go backend server using nginx as a reverse proxy with Let's Encrypt SSL certificate.

## Prerequisites

- Server with root/sudo access
- Domain name pointing to your server IP (84.252.141.42)
- Ports 80 and 443 open in firewall
- nginx installed (or install it)

## Option 1: Using nginx Reverse Proxy (Recommended)

### Step 1: Install nginx and Certbot

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install nginx certbot python3-certbot-nginx
```

### Step 2: Configure Domain DNS

Point your domain to your server IP:
- Add A record: `api.loveconnection.app` → `84.252.141.42`
- Or use your existing domain

### Step 3: Configure nginx

Create nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/loveconnection
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name api.loveconnection.app;  # Replace with your domain

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.loveconnection.app;  # Replace with your domain

    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/api.loveconnection.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.loveconnection.app/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy settings
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # WebSocket support
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    # Increase body size for file uploads if needed
    client_max_body_size 10M;
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl reload nginx
```

### Step 4: Get SSL Certificate with Let's Encrypt

```bash
sudo certbot --nginx -d api.loveconnection.app
```

Follow the prompts:
- Enter your email
- Agree to terms
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

Certbot will automatically:
- Obtain SSL certificate
- Update nginx configuration
- Set up auto-renewal

### Step 5: Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

### Step 6: Update Backend Configuration

Your Go server should continue running on port 8080. nginx will handle HTTPS on port 443 and proxy to your Go server.

## Option 2: Self-Signed Certificate (Development Only)

**Warning**: Self-signed certificates will show security warnings in browsers/apps. Only use for development.

### Generate Self-Signed Certificate

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/loveconnection.key \
  -out /etc/nginx/ssl/loveconnection.crt
```

Answer the prompts (you can use any values for development).

### Update nginx Configuration

Use the same nginx config as above, but point to your self-signed certificate:

```nginx
ssl_certificate /etc/nginx/ssl/loveconnection.crt;
ssl_certificate_key /etc/nginx/ssl/loveconnection.key;
```

## Option 3: HTTPS Directly in Go (Advanced)

You can also configure HTTPS directly in your Go server, but using nginx is recommended for:
- Better SSL/TLS configuration
- Easier certificate management
- Better performance
- Security headers

If you want to do it in Go, you'll need to:

1. Get SSL certificate
2. Update `main.go` to use TLS:

```go
package main

import (
    "log"
    "net/http"
    "os"
)

func main() {
    // ... your existing code ...

    certFile := os.Getenv("SSL_CERT_FILE") // e.g., "/etc/ssl/certs/server.crt"
    keyFile := os.Getenv("SSL_KEY_FILE")   // e.g., "/etc/ssl/private/server.key"

    if certFile != "" && keyFile != "" {
        log.Fatal(http.ListenAndServeTLS(":443", certFile, keyFile, router))
    } else {
        log.Fatal(http.ListenAndServe(":8080", router))
    }
}
```

## Firewall Configuration

Make sure ports are open:

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## Testing HTTPS

After setup, test your HTTPS endpoint:

```bash
curl https://api.loveconnection.app/health
```

Should return your health check response.

## Updating iOS App

After setting up HTTPS:

1. Update `Info.plist`:
   - Change `PRODUCTION_BACKEND_URL` to `https://api.loveconnection.app`
   - Remove `NSAllowsArbitraryLoads` from ATS settings
   - Keep only specific domain exceptions if needed

2. Update `Config.swift` if needed (should automatically use HTTPS URL from Info.plist)

3. Rebuild and test the app

## Troubleshooting

### Certificate not working
- Check DNS: `dig api.loveconnection.app`
- Verify nginx is running: `sudo systemctl status nginx`
- Check nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Test SSL: `openssl s_client -connect api.loveconnection.app:443`

### 502 Bad Gateway
- Check if Go server is running: `curl http://localhost:8080/health`
- Check nginx proxy_pass URL is correct
- Check firewall allows localhost connections

### Certificate renewal fails
- Check certbot logs: `sudo certbot certificates`
- Manually renew: `sudo certbot renew`
- Check cron job: `sudo systemctl status certbot.timer`

## Security Best Practices

1. **Use Let's Encrypt** for production (free, trusted certificates)
2. **Enable HSTS** (already in nginx config above)
3. **Use strong ciphers** (already configured)
4. **Keep certificates updated** (auto-renewal is set up)
5. **Monitor certificate expiration**: `sudo certbot certificates`

## Next Steps

1. Set up domain DNS
2. Install nginx and certbot
3. Configure nginx
4. Get SSL certificate
5. Update iOS app to use HTTPS URL
6. Remove ATS exceptions from iOS app
7. Test everything works

