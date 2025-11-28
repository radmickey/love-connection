#!/bin/bash

set -e

DOMAIN_OR_IP="${1:-84.252.141.42}"
BACKEND_PORT="${2:-8080}"

echo "🔒 Setting up self-signed SSL certificate for $DOMAIN_OR_IP"
echo "⚠️  WARNING: Self-signed certificates will show security warnings!"
echo "   This is for development only. Use a real domain for production."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Install nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing nginx..."
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y nginx
    elif command -v yum &> /dev/null; then
        yum install -y nginx
    else
        echo "❌ Unsupported package manager. Please install nginx manually."
        exit 1
    fi
fi

# Create SSL directory
mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
echo "🔐 Generating self-signed certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/loveconnection.key \
  -out /etc/nginx/ssl/loveconnection.crt \
  -subj "/C=US/ST=State/L=City/O=LoveConnection/CN=$DOMAIN_OR_IP"

# Create nginx configuration
echo "📝 Creating nginx configuration..."
cat > /etc/nginx/sites-available/loveconnection <<EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_OR_IP;

    ssl_certificate /etc/nginx/ssl/loveconnection.crt;
    ssl_certificate_key /etc/nginx/ssl/loveconnection.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

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

# Enable site
ln -sf /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
nginx -t

# Start nginx
echo "🚀 Starting nginx..."
systemctl enable nginx
systemctl restart nginx

# Configure firewall
echo "🔥 Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo ""
echo "✅ Self-signed SSL setup complete!"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - This certificate will show security warnings in browsers/apps"
echo "   - iOS app needs ATS exception for self-signed certificates"
echo "   - This is for DEVELOPMENT ONLY"
echo ""
echo "📋 Next steps:"
echo "1. Update iOS app Info.plist to allow self-signed certificate"
echo "2. Test: curl -k https://$DOMAIN_OR_IP/health"
echo ""
echo "💡 For production, get a free domain and use Let's Encrypt:"
echo "   See: backend/SETUP_HTTPS_NO_DOMAIN.md"

