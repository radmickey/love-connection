#!/bin/bash

set -e

echo "🔧 Setting up Love Connection project..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or later."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Go version $GO_VERSION is too old. Please install Go $REQUIRED_VERSION or later."
    exit 1
fi

echo "✅ Go version check passed"

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
go mod download
cd ..

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp backend/.env.example .env
    echo "⚠️  Please update .env file with your configuration before starting services"
else
    echo "✅ .env file already exists"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker is not installed. You'll need Docker to run PostgreSQL."
    echo "   Install Docker from: https://www.docker.com/get-started"
else
    echo "✅ Docker is installed"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Run 'make start' or './scripts/start.sh' to start services"
echo "3. For iOS app, open the project in Xcode"

