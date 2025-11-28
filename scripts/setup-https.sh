#!/bin/bash

set -e

DOMAIN="${1:-api.loveconnection.app}"
BACKEND_PORT="${2:-8080}"

echo "🔒 Setting up HTTPS for $DOMAIN"
echo "Backend will run on port $BACKEND_PORT"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Install nginx and certbot
echo "📦 Installing nginx and certbot..."
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx
elif command -v yum &> /dev/null; then
    yum install -y nginx certbot python3-certbot-nginx
else
    echo "❌ Unsupported package manager. Please install nginx and certbot manually."
    exit 1
fi

# Create nginx configuration (HTTP only first, certbot will add HTTPS)
echo "📝 Creating nginx configuration..."
cat > /etc/nginx/sites-available/loveconnection <<EOF
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

# Enable site
ln -sf /etc/nginx/sites-available/loveconnection /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # Remove default site if exists

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
nginx -t

# Start nginx
echo "🚀 Starting nginx..."
systemctl enable nginx
systemctl restart nginx

# Get SSL certificate
echo "🔐 Obtaining SSL certificate from Let's Encrypt..."
echo "Make sure DNS is configured: $DOMAIN → $(hostname -I | awk '{print $1}')"
echo ""
read -p "Press Enter to continue with certbot (or Ctrl+C to cancel)..."

# Certbot will automatically:
# 1. Obtain SSL certificate
# 2. Update nginx configuration to add HTTPS
# 3. Set up HTTP to HTTPS redirect
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

# Verify nginx config after certbot changes
echo "🧪 Verifying nginx configuration after certbot..."
nginx -t
systemctl reload nginx

# Test certificate renewal
echo "🧪 Testing certificate auto-renewal..."
certbot renew --dry-run

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
echo "✅ HTTPS setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update iOS app Info.plist: PRODUCTION_BACKEND_URL = https://$DOMAIN"
echo "2. Remove NSAllowsArbitraryLoads from ATS settings"
echo "3. Test: curl https://$DOMAIN/health"
echo ""
echo "🔍 Check status:"
echo "  - nginx: systemctl status nginx"
echo "  - certbot: certbot certificates"
echo "  - logs: tail -f /var/log/nginx/error.log"

