#!/bin/bash

set -e

echo "🔧 Fixing nginx port 80 issue..."

# Check what nginx is actually listening on
echo "1️⃣  Checking what nginx is listening on..."
if command -v ss &> /dev/null; then
    sudo ss -tlnp | grep nginx || echo "No nginx processes found listening"
elif command -v netstat &> /dev/null; then
    sudo netstat -tlnp | grep nginx || echo "No nginx processes found listening"
else
    echo "⚠️  netstat/ss not found, checking with lsof..."
    sudo lsof -i :80 -P 2>/dev/null || echo "Nothing found on port 80"
fi

# Check nginx processes
echo ""
echo "2️⃣  Checking nginx processes..."
ps aux | grep nginx | grep -v grep || echo "No nginx processes running"

# Check if site is enabled
echo ""
echo "3️⃣  Checking if site is enabled..."
if [ -L /etc/nginx/sites-enabled/loveconnection ]; then
    echo "✅ Site is enabled"
else
    echo "⚠️  Site is not enabled, enabling it..."
    sudo ln -sf /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
fi

# Check nginx config
echo ""
echo "4️⃣  Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration has errors"
    exit 1
fi

# Reload nginx
echo ""
echo "5️⃣  Reloading nginx..."
sudo systemctl reload nginx

# Wait a moment
sleep 2

# Check again
echo ""
echo "6️⃣  Checking port 80 again..."
check_port80() {
    if command -v ss &> /dev/null; then
        sudo ss -tlnp | grep ":80 " || return 1
    elif command -v netstat &> /dev/null; then
        sudo netstat -tlnp | grep ":80 " || return 1
    elif command -v lsof &> /dev/null; then
        sudo lsof -i :80 -P 2>/dev/null || return 1
    else
        # Fallback: test with curl
        curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null | grep -q "200\|301\|302" && return 0 || return 1
    fi
}

if check_port80; then
    if command -v ss &> /dev/null; then
        LISTEN_ADDR=$(sudo ss -tlnp | grep ":80 " | awk '{print $4}')
    elif command -v netstat &> /dev/null; then
        LISTEN_ADDR=$(sudo netstat -tlnp | grep ":80 " | awk '{print $4}')
    elif command -v lsof &> /dev/null; then
        LISTEN_ADDR=$(sudo lsof -i :80 -P 2>/dev/null | grep LISTEN | awk '{print $9}')
    else
        LISTEN_ADDR="port 80 (checked via HTTP test)"
    fi
    echo "✅ Port 80 is now listening on: $LISTEN_ADDR"
else
    echo "⚠️  Port 80 still not listening, trying restart..."
    sudo systemctl restart nginx
    sleep 2
    if check_port80; then
        if command -v ss &> /dev/null; then
            LISTEN_ADDR=$(sudo ss -tlnp | grep ":80 " | awk '{print $4}')
        elif command -v netstat &> /dev/null; then
            LISTEN_ADDR=$(sudo netstat -tlnp | grep ":80 " | awk '{print $4}')
        else
            LISTEN_ADDR="port 80 (checked via HTTP test)"
        fi
        echo "✅ Port 80 is now listening on: $LISTEN_ADDR"
    else
        echo "⚠️  Port check failed, but testing HTTP access..."
        HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
        if [ "$HTTP_TEST" = "200" ] || [ "$HTTP_TEST" = "301" ] || [ "$HTTP_TEST" = "302" ]; then
            echo "✅ HTTP is working (got $HTTP_TEST), port 80 is likely listening"
        else
            echo "❌ Port 80 check failed and HTTP test returned: $HTTP_TEST"
            echo ""
            echo "Debugging info:"
            echo "  nginx status:"
            sudo systemctl status nginx --no-pager | head -20
            echo ""
            echo "  nginx error log (last 10 lines):"
            sudo tail -10 /var/log/nginx/error.log
            echo ""
            echo "  Testing HTTP directly:"
            curl -v http://localhost/health 2>&1 | head -10
        fi
    fi
fi

echo ""
echo "✅ nginx should now be listening on port 80"
echo "   You can now run: sudo certbot --nginx -d love-couple-connect.duckdns.org"

