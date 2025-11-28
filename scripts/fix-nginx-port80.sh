#!/bin/bash

set -e

echo "🔧 Fixing nginx port 80 issue..."

# Check what nginx is actually listening on
echo "1️⃣  Checking what nginx is listening on..."
sudo netstat -tlnp | grep nginx || echo "No nginx processes found listening"

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
if sudo netstat -tlnp | grep -q ":80 "; then
    LISTEN_ADDR=$(sudo netstat -tlnp | grep ":80 " | awk '{print $4}')
    echo "✅ Port 80 is now listening on: $LISTEN_ADDR"
else
    echo "⚠️  Port 80 still not listening, trying restart..."
    sudo systemctl restart nginx
    sleep 2
    if sudo netstat -tlnp | grep -q ":80 "; then
        LISTEN_ADDR=$(sudo netstat -tlnp | grep ":80 " | awk '{print $4}')
        echo "✅ Port 80 is now listening on: $LISTEN_ADDR"
    else
        echo "❌ Port 80 still not listening"
        echo ""
        echo "Debugging info:"
        echo "  nginx status:"
        sudo systemctl status nginx --no-pager | head -20
        echo ""
        echo "  nginx error log (last 10 lines):"
        sudo tail -10 /var/log/nginx/error.log
        exit 1
    fi
fi

echo ""
echo "✅ nginx should now be listening on port 80"
echo "   You can now run: sudo certbot --nginx -d love-couple-connect.duckdns.org"

