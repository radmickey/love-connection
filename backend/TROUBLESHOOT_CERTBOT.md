# Troubleshooting Certbot DNS Errors

## Error: DNS problem: query timed out looking up CAA

This error means Let's Encrypt can't verify your domain via DNS. Here's how to fix it:

## Step 1: Verify DNS is Working

Check if DNS is resolving correctly:

```bash
# On your server
dig love-couple-connect.duckdns.org
# or
nslookup love-couple-connect.duckdns.org
# or
host love-couple-connect.duckdns.org
```

Should return: `84.252.141.42`

If it doesn't:
- Wait 10-30 minutes for DNS propagation
- Check DuckDNS dashboard that IP is set correctly
- Try updating IP in DuckDNS again

## Step 2: Verify Server is Accessible

Let's Encrypt needs to access your server on port 80. Check:

```bash
# Check if port 80 is open
sudo netstat -tlnp | grep :80
# or
sudo ss -tlnp | grep :80

# Check firewall
sudo ufw status
# Make sure 80 and 443 are allowed:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Step 3: Test HTTP Access

From another machine (or use online tool):

```bash
# Should return your backend response
curl http://love-couple-connect.duckdns.org/health
```

If this doesn't work, nginx might not be accessible from internet.

## Step 4: Check nginx is Running and Accessible

```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx is listening on all interfaces (0.0.0.0)
sudo netstat -tlnp | grep nginx
# Should show: 0.0.0.0:80 and 0.0.0.0:443
```

## Step 5: Verify DuckDNS IP Update

1. Go to https://www.duckdns.org
2. Log in
3. Check that `love-couple-connect` domain shows IP: `84.252.141.42`
4. If different, update it and wait 5-10 minutes

## Step 6: Try Certbot Again

After verifying DNS and accessibility:

```bash
# Try with verbose output to see more details
sudo certbot --nginx -d love-couple-connect.duckdns.org -v

# Or try standalone mode (stops nginx temporarily)
sudo certbot certonly --standalone -d love-couple-connect.duckdns.org
```

## Step 7: Alternative - Use DNS Challenge

If HTTP challenge fails, try DNS challenge:

```bash
sudo certbot certonly --manual --preferred-challenges dns -d love-couple-connect.duckdns.org
```

This will ask you to add a TXT record to DNS. For DuckDNS, you can add it via their API or dashboard.

## Common Issues

### Issue: DNS not propagating
**Solution**: Wait longer (up to 1 hour), or use a different DNS provider

### Issue: Port 80 blocked by firewall
**Solution**:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

### Issue: nginx not listening on 0.0.0.0
**Solution**: Check nginx config, ensure `listen 80;` not `listen 127.0.0.1:80;`

### Issue: ISP blocking port 80
**Solution**: Some ISPs block port 80. You may need to:
- Use DNS challenge instead
- Contact your hosting provider
- Use a different port (not recommended)

### Issue: DuckDNS update not working
**Solution**:
- Check DuckDNS token is correct
- Try updating IP via DuckDNS API:
  ```bash
  curl "https://www.duckdns.org/update?domains=love-couple-connect&token=YOUR_TOKEN&ip=84.252.141.42"
  ```

## Quick Test Script

Run this to check everything:

```bash
#!/bin/bash
echo "1. Checking DNS..."
dig +short love-couple-connect.duckdns.org

echo "2. Checking port 80..."
sudo netstat -tlnp | grep :80

echo "3. Checking nginx status..."
sudo systemctl status nginx --no-pager

echo "4. Testing HTTP access..."
curl -I http://love-couple-connect.duckdns.org/health

echo "5. Checking firewall..."
sudo ufw status | grep -E "80|443"
```

## If All Else Fails

1. **Wait 24 hours** - Sometimes DNS propagation takes time
2. **Use Cloudflare Tunnel** - Free HTTPS without domain verification
3. **Use self-signed certificate** - For development only
4. **Contact hosting provider** - They might block port 80

