# Setting Up HTTPS Without a Domain

If you don't have a domain name, here are your options:

## Option 1: Get a Free Domain (Recommended)

### Free Domain Providers:

1. **Freenom** (https://www.freenom.com)
   - Free `.tk`, `.ml`, `.ga`, `.cf`, `.gq` domains
   - Easy to set up
   - Point A record to your IP: `84.252.141.42`

2. **No-IP** (https://www.noip.com)
   - Free dynamic DNS hostname
   - Format: `yourname.ddns.net`
   - Works with Let's Encrypt

3. **DuckDNS** (https://www.duckdns.org)
   - Free subdomain: `yourname.duckdns.org`
   - Simple setup
   - Works with Let's Encrypt

4. **Cloudflare** (https://www.cloudflare.com)
   - Free domain registration (limited TLDs)
   - Free SSL certificates
   - CDN included

### Quick Setup with Freenom:

1. Register at https://www.freenom.com
2. Get a free domain (e.g., `loveconnection.tk`)
3. Add A record: `api.loveconnection.tk` → `84.252.141.42`
4. Wait for DNS propagation (5-30 minutes)
5. Follow the main HTTPS setup guide with your new domain

## Option 2: Self-Signed Certificate (Development Only)

**Warning**: Self-signed certificates will show security warnings in iOS apps. Only use for development/testing.

### Generate Self-Signed Certificate:

```bash
# Create directory for certificates
sudo mkdir -p /etc/nginx/ssl

# Generate certificate (valid for 1 year)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/loveconnection.key \
  -out /etc/nginx/ssl/loveconnection.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=84.252.141.42"
```

### Configure nginx with Self-Signed Certificate:

```nginx
server {
    listen 443 ssl http2;
    server_name 84.252.141.42;  # Your IP

    ssl_certificate /etc/nginx/ssl/loveconnection.crt;
    ssl_certificate_key /etc/nginx/ssl/loveconnection.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### iOS App Configuration for Self-Signed Certificate:

You'll need to add certificate pinning or disable certificate validation for development:

**Option A: Disable Certificate Validation (Development Only)**

Add to `Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>84.252.141.42</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**Option B: Certificate Pinning (More Secure)**

You'll need to implement certificate pinning in your iOS app code. This is more complex but more secure.

## Option 3: Use Cloudflare Tunnel (Free SSL)

Cloudflare provides free SSL even without a domain:

1. Sign up at https://www.cloudflare.com
2. Use Cloudflare Tunnel (cloudflared)
3. Get a free subdomain: `yourname.trycloudflare.com`
4. Automatic HTTPS with valid certificate

### Setup Cloudflare Tunnel:

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create loveconnection

# Run tunnel (forwards port 8080)
cloudflared tunnel --url http://localhost:8080
```

This gives you a URL like: `https://loveconnection-xxxxx.trycloudflare.com`

## Option 4: Continue with HTTP (Development)

If you're only developing/testing, you can continue using HTTP with ATS exceptions:

1. Keep `NSAllowsArbitraryLoads = true` in `Info.plist`
2. Use HTTP URL: `http://84.252.141.42:8080`
3. Accept that it's not secure (OK for development)

**For App Store submission**, you'll need HTTPS, so get a free domain.

## Option 5: Use ngrok (Temporary HTTPS)

ngrok provides temporary HTTPS tunnels for development:

```bash
# Install ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# Start tunnel
ngrok http 8080
```

This gives you a temporary HTTPS URL (changes on restart).

## Recommendation

**For Development:**
- Use HTTP with ATS exceptions (current setup)
- Or use ngrok/Cloudflare Tunnel for quick HTTPS testing

**For Production/App Store:**
- Get a free domain from Freenom or DuckDNS
- Set up proper HTTPS with Let's Encrypt
- This is required for App Store submission

## Quick Start: Free Domain Setup

1. **Get free domain** from Freenom (e.g., `loveconnection.tk`)
2. **Point DNS** to your IP: `84.252.141.42`
3. **Wait 5-30 minutes** for DNS propagation
4. **Run setup script:**
   ```bash
   sudo ./scripts/setup-https.sh api.loveconnection.tk 8080
   ```

That's it! You'll have valid HTTPS with Let's Encrypt certificate.

