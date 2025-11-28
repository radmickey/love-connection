#!/bin/bash

# Quick fix script if nginx config has SSL paths before certificates exist

DOMAIN="${1:-love-couple-connect.duckdns.org}"
BACKEND_PORT="${2:-8080}"

echo "🔧 Fixing nginx configuration for $DOMAIN"

# Create temporary HTTP-only config
cat > /tmp/loveconnection-http <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    client_max_body_size 10M;
}
EOF

# Replace config
sudo cp /tmp/loveconnection-http /etc/nginx/sites-available/loveconnection

# Test and reload
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Fixed! Now run: sudo certbot --nginx -d $DOMAIN"

