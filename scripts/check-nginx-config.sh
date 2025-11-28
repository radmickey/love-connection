#!/bin/bash

echo "🔍 Checking nginx configuration..."
echo ""

# Check nginx config file
echo "1️⃣  Checking nginx config file..."
if [ -f /etc/nginx/sites-available/loveconnection ]; then
    echo "✅ Config file exists: /etc/nginx/sites-available/loveconnection"
    echo ""
    echo "Current configuration:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat /etc/nginx/sites-available/loveconnection
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if port 80 is configured
    if grep -q "listen 80" /etc/nginx/sites-available/loveconnection; then
        echo "✅ Port 80 is configured"
    else
        echo "❌ Port 80 is NOT configured!"
    fi

    # Check if proxy_pass points to 8080
    if grep -q "proxy_pass http://localhost:8080" /etc/nginx/sites-available/loveconnection; then
        echo "✅ proxy_pass points to port 8080 (correct)"
    else
        echo "⚠️  proxy_pass might not point to port 8080"
        grep "proxy_pass" /etc/nginx/sites-available/loveconnection || echo "No proxy_pass found"
    fi
else
    echo "❌ Config file not found!"
fi

echo ""
echo "2️⃣  Testing HTTP access to backend (port 8080)..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    echo "✅ Backend is responding on port 8080"
else
    echo "❌ Backend not responding on port 8080 (got: $BACKEND_RESPONSE)"
fi

echo ""
echo "3️⃣  Testing HTTP access via nginx (port 80)..."
NGINX_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
if [ "$NGINX_RESPONSE" = "200" ]; then
    echo "✅ nginx proxy is working (port 80 → 8080)"
else
    echo "⚠️  nginx proxy not working (got: $NGINX_RESPONSE)"
fi

echo ""
echo "4️⃣  Checking what ports nginx is actually using..."
if command -v ss &> /dev/null; then
    echo "Using ss command:"
    sudo ss -tlnp | grep nginx || echo "No nginx listening ports found"
elif command -v lsof &> /dev/null; then
    echo "Using lsof command:"
    sudo lsof -i -P -n | grep nginx || echo "No nginx processes found"
else
    echo "⚠️  Cannot check ports (ss/lsof not available)"
    echo "Testing with curl instead..."
    curl -v http://localhost/health 2>&1 | head -15
fi

echo ""
echo "5️⃣  Checking nginx main config..."
if [ -f /etc/nginx/nginx.conf ]; then
    if grep -q "include.*sites-enabled" /etc/nginx/nginx.conf; then
        echo "✅ sites-enabled is included in main config"
    else
        echo "⚠️  sites-enabled might not be included"
    fi
fi

echo ""
echo "📋 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backend should run on: port 8080"
echo "nginx should listen on: port 80"
echo "nginx should proxy: 80 → 8080"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

