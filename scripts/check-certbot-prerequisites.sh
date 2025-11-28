#!/bin/bash

DOMAIN="${1:-love-couple-connect.duckdns.org}"

echo "🔍 Checking prerequisites for Certbot..."
echo "Domain: $DOMAIN"
echo ""

# Check DNS
echo "1️⃣  Checking DNS resolution..."
DNS_IP=$(dig +short $DOMAIN | head -1)
if [ -z "$DNS_IP" ]; then
    echo "❌ DNS not resolving for $DOMAIN"
    echo "   → Check DuckDNS dashboard"
    echo "   → Wait 10-30 minutes for propagation"
else
    echo "✅ DNS resolves to: $DNS_IP"
    if [ "$DNS_IP" != "84.252.141.42" ]; then
        echo "⚠️  Warning: DNS IP ($DNS_IP) doesn't match server IP (84.252.141.42)"
        echo "   → Update DuckDNS with correct IP"
    fi
fi
echo ""

# Check port 80
echo "2️⃣  Checking port 80..."
if sudo netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    LISTEN_ADDR=$(sudo netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $4}')
    echo "✅ Port 80 is listening on: $LISTEN_ADDR"
    if [[ "$LISTEN_ADDR" == "0.0.0.0:80" ]] || [[ "$LISTEN_ADDR" == "*:80" ]]; then
        echo "   ✅ Listening on all interfaces (correct)"
    else
        echo "   ⚠️  Warning: Not listening on all interfaces"
        echo "   → Should be 0.0.0.0:80, not 127.0.0.1:80"
    fi
else
    echo "❌ Port 80 is not listening"
    echo "   → Check nginx is running: sudo systemctl status nginx"
fi
echo ""

# Check nginx status
echo "3️⃣  Checking nginx status..."
if systemctl is-active --quiet nginx; then
    echo "✅ nginx is running"
else
    echo "❌ nginx is not running"
    echo "   → Start it: sudo systemctl start nginx"
fi
echo ""

# Check firewall
echo "4️⃣  Checking firewall..."
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "80/tcp.*ALLOW"; then
        echo "✅ Port 80 is allowed in firewall"
    else
        echo "⚠️  Port 80 might be blocked"
        echo "   → Run: sudo ufw allow 80/tcp"
    fi
    if sudo ufw status | grep -q "443/tcp.*ALLOW"; then
        echo "✅ Port 443 is allowed in firewall"
    else
        echo "⚠️  Port 443 might be blocked"
        echo "   → Run: sudo ufw allow 443/tcp"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --list-ports | grep -q "80/tcp"; then
        echo "✅ Port 80 is allowed in firewall"
    else
        echo "⚠️  Port 80 might be blocked"
    fi
else
    echo "⚠️  Could not check firewall (ufw/firewalld not found)"
fi
echo ""

# Test HTTP access
echo "5️⃣  Testing HTTP access..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$DOMAIN/health 2>/dev/null)
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "✅ HTTP access works (got 200)"
elif [ -n "$HTTP_RESPONSE" ]; then
    echo "⚠️  HTTP access returned: $HTTP_RESPONSE"
else
    echo "❌ HTTP access failed (timeout or connection refused)"
    echo "   → Server might not be accessible from internet"
    echo "   → Check firewall and port forwarding"
fi
echo ""

# Check from external
echo "6️⃣  Checking external accessibility..."
echo "   (This might take a moment...)"
EXTERNAL_CHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://$DOMAIN/health 2>/dev/null)
if [ "$EXTERNAL_CHECK" = "200" ]; then
    echo "✅ Server is accessible from internet"
else
    echo "⚠️  Server might not be accessible from internet"
    echo "   → Check router port forwarding (80 → 84.252.141.42:80)"
    echo "   → Check hosting provider firewall rules"
fi
echo ""

echo "📋 Summary:"
echo "   If all checks pass, try certbot again:"
echo "   sudo certbot --nginx -d $DOMAIN"
echo ""
echo "   If DNS check failed, wait and try again later"
echo "   If HTTP access failed, check firewall and port forwarding"

