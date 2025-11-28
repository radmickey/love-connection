# Remote Server Diagnosis

## Quick Commands to Run on Server

After SSH'ing to your server, run these commands:

### 1. Update repository
```bash
cd /path/to/love-connection  # or wherever you cloned it
git pull
```

### 2. Run diagnostic script
```bash
sudo ./scripts/diagnose-server.sh
```

### 3. Or check manually:

**Check DNS:**
```bash
dig love-couple-connect.duckdns.org
# Should return: 84.252.141.42
```

**Check nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t
sudo netstat -tlnp | grep :80
```

**Check firewall:**
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Test local access:**
```bash
curl http://localhost:8080/health
curl http://localhost/health
```

**Test external access:**
```bash
curl http://love-couple-connect.duckdns.org/health
```

### 4. If all checks pass, try Certbot again:
```bash
sudo certbot --nginx -d love-couple-connect.duckdns.org
```

### 5. If DNS is the issue, wait and retry:
```bash
# Wait 10-30 minutes, then:
sudo certbot --nginx -d love-couple-connect.duckdns.org
```

