# Quick HTTPS Setup for love-couple-connect.duckdns.org

## Step 1: Configure DNS in DuckDNS

1. Go to https://www.duckdns.org
2. Log in to your account
3. Make sure `love-couple-connect` is in your domains list
4. Set the IP to: `84.252.141.42`
5. Click "Save"

Wait 5-10 minutes for DNS propagation.

## Step 2: Verify DNS

Check that DNS is working:

```bash
dig love-couple-connect.duckdns.org
# or
nslookup love-couple-connect.duckdns.org
```

Should return: `84.252.141.42`

## Step 3: Setup HTTPS on Server

On your server (84.252.141.42), run:

```bash
# Clone or copy the setup script to your server
sudo ./scripts/setup-https.sh love-couple-connect.duckdns.org 8080
```

Or manually:

```bash
# Install nginx and certbot
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d love-couple-connect.duckdns.org

# Follow the prompts:
# - Enter your email
# - Agree to terms
# - Choose to redirect HTTP to HTTPS (recommended: Yes)
```

## Step 4: Update iOS App

After HTTPS is set up, update your iOS app:

1. **Update Info.plist:**
   ```xml
   <key>PRODUCTION_BACKEND_URL</key>
   <string>https://love-couple-connect.duckdns.org</string>
   ```

2. **Remove NSAllowsArbitraryLoads from ATS:**
   - Remove or set to `false` the `NSAllowsArbitraryLoads` key
   - Keep only specific domain exceptions if needed

3. **Clean and rebuild:**
   - Product → Clean Build Folder (Cmd+Shift+K)
   - Product → Build (Cmd+B)

## Step 5: Test

```bash
# Test HTTPS endpoint
curl https://love-couple-connect.duckdns.org/health

# Should return: {"status":"healthy",...}
```

## Troubleshooting

### DNS not resolving?
- Wait a bit longer (up to 30 minutes)
- Check DuckDNS dashboard that IP is correct
- Try: `dig love-couple-connect.duckdns.org`

### Certificate error?
- Make sure DNS is pointing to your IP
- Check nginx is running: `sudo systemctl status nginx`
- Check certbot logs: `sudo certbot certificates`

### 502 Bad Gateway?
- Check Go server is running: `curl http://localhost:8080/health`
- Check nginx proxy_pass URL is correct
- Check nginx logs: `sudo tail -f /var/log/nginx/error.log`

## Auto-Renewal

Certbot automatically sets up renewal. Test it:

```bash
sudo certbot renew --dry-run
```

Certificates auto-renew every 90 days.

