#!/bin/bash

set -e

DOMAIN="love-couple-connect.duckdns.org"
SERVER_IP="84.252.141.42"

echo "🔍 Diagnosing server for Certbot setup..."
echo "Domain: $DOMAIN"
echo "Server IP: $SERVER_IP"
echo ""

# Check DNS
echo "1️⃣  Checking DNS resolution..."
DNS_IP=$(dig +short $DOMAIN | head -1)
if [ -z "$DNS_IP" ]; then
    echo "❌ DNS not resolving for $DOMAIN"
    echo "   → Check DuckDNS dashboard"
    echo "   → Wait 10-30 minutes for propagation"
    DNS_OK=false
else
    echo "✅ DNS resolves to: $DNS_IP"
    if [ "$DNS_IP" = "$SERVER_IP" ]; then
        echo "   ✅ DNS IP matches server IP"
        DNS_OK=true
    else
        echo "   ⚠️  Warning: DNS IP ($DNS_IP) doesn't match server IP ($SERVER_IP)"
        echo "   → Update DuckDNS with correct IP"
        DNS_OK=false
    fi
fi
echo ""

# Check port 80
echo "2️⃣  Checking port 80..."
if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    LISTEN_ADDR=$(netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $4}')
    echo "✅ Port 80 is listening on: $LISTEN_ADDR"
    if [[ "$LISTEN_ADDR" == "0.0.0.0:80" ]] || [[ "$LISTEN_ADDR" == "*:80" ]]; then
        echo "   ✅ Listening on all interfaces (correct)"
        PORT_OK=true
    else
        echo "   ⚠️  Warning: Not listening on all interfaces"
        echo "   → Should be 0.0.0.0:80, not 127.0.0.1:80"
        PORT_OK=false
    fi
else
    echo "❌ Port 80 is not listening"
    echo "   → Check nginx is running: systemctl status nginx"
    PORT_OK=false
fi
echo ""

# Check nginx status
echo "3️⃣  Checking nginx status..."
if systemctl is-active --quiet nginx; then
    echo "✅ nginx is running"
    NGINX_OK=true
else
    echo "❌ nginx is not running"
    echo "   → Start it: systemctl start nginx"
    NGINX_OK=false
fi
echo ""

# Check nginx config
echo "4️⃣  Checking nginx configuration..."
if [ -f /etc/nginx/sites-available/loveconnection ]; then
    echo "✅ nginx config file exists"
    if grep -q "server_name $DOMAIN" /etc/nginx/sites-available/loveconnection; then
        echo "   ✅ Domain configured correctly"
    else
        echo "   ⚠️  Domain might not be configured correctly"
    fi
    if nginx -t 2>&1 | grep -q "test is successful"; then
        echo "   ✅ nginx configuration is valid"
        CONFIG_OK=true
    else
        echo "   ❌ nginx configuration has errors:"
        nginx -t 2>&1 | grep -i error || true
        CONFIG_OK=false
    fi
else
    echo "❌ nginx config file not found"
    CONFIG_OK=false
fi
echo ""

# Check firewall
echo "5️⃣  Checking firewall..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    echo "UFW Status: $UFW_STATUS"
    if ufw status | grep -q "80/tcp.*ALLOW"; then
        echo "✅ Port 80 is allowed in firewall"
    else
        echo "⚠️  Port 80 might be blocked"
        echo "   → Run: ufw allow 80/tcp"
    fi
    if ufw status | grep -q "443/tcp.*ALLOW"; then
        echo "✅ Port 443 is allowed in firewall"
    else
        echo "⚠️  Port 443 might be blocked"
        echo "   → Run: ufw allow 443/tcp"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
        echo "✅ Port 80 is allowed in firewall"
    else
        echo "⚠️  Port 80 might be blocked"
    fi
else
    echo "⚠️  Could not check firewall (ufw/firewalld not found)"
fi
echo ""

# Test local HTTP access
echo "6️⃣  Testing local HTTP access..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8080/health 2>/dev/null || echo "000")
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "✅ Backend is responding on localhost:8080"
    BACKEND_OK=true
else
    echo "❌ Backend not responding (got: $HTTP_RESPONSE)"
    echo "   → Check if Go server is running"
    BACKEND_OK=false
fi
echo ""

# Test nginx proxy
echo "7️⃣  Testing nginx proxy..."
NGINX_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost/health 2>/dev/null || echo "000")
if [ "$NGINX_RESPONSE" = "200" ]; then
    echo "✅ nginx proxy is working"
    PROXY_OK=true
else
    echo "❌ nginx proxy not working (got: $NGINX_RESPONSE)"
    PROXY_OK=false
fi
echo ""

# Test external access
echo "8️⃣  Testing external accessibility..."
echo "   (This might take a moment...)"
EXTERNAL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://$DOMAIN/health 2>/dev/null || echo "000")
if [ "$EXTERNAL_RESPONSE" = "200" ]; then
    echo "✅ Server is accessible from internet via domain"
    EXTERNAL_OK=true
else
    echo "⚠️  Server might not be accessible from internet (got: $EXTERNAL_RESPONSE)"
    echo "   → Check router port forwarding (80 → $SERVER_IP:80)"
    echo "   → Check hosting provider firewall rules"
    EXTERNAL_OK=false
fi
echo ""

# Summary
echo "📋 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$DNS_OK" = true ] && [ "$PORT_OK" = true ] && [ "$NGINX_OK" = true ] && [ "$CONFIG_OK" = true ] && [ "$BACKEND_OK" = true ] && [ "$PROXY_OK" = true ]; then
    echo "✅ All checks passed! Ready for Certbot."
    echo ""
    echo "Next step:"
    echo "  sudo certbot --nginx -d $DOMAIN"
else
    echo "⚠️  Some checks failed. Fix issues above before running Certbot."
    echo ""
    if [ "$DNS_OK" != true ]; then
        echo "  → Fix DNS: Wait for propagation or update DuckDNS"
    fi
    if [ "$PORT_OK" != true ] || [ "$NGINX_OK" != true ] || [ "$CONFIG_OK" != true ]; then
        echo "  → Fix nginx: Check configuration and restart"
    fi
    if [ "$BACKEND_OK" != true ]; then
        echo "  → Fix backend: Start Go server on port 8080"
    fi
    if [ "$EXTERNAL_OK" != true ]; then
        echo "  → Fix external access: Check firewall and port forwarding"
    fi
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

