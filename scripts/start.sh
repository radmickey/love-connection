#!/bin/bash

set -e

echo "🚀 Starting Love Connection services..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from example..."
    cp backend/.env.example .env
    echo "📝 Please update .env file with your configuration"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start services
echo "📦 Starting PostgreSQL and Backend..."
docker-compose up -d

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Check if backend is running
if docker-compose ps backend | grep -q "Up"; then
    echo "✅ Services started successfully!"
    echo ""
    echo "📍 Backend API: http://localhost:8080"
    echo "📍 PostgreSQL: localhost:5432"
    echo ""
    echo "📋 Useful commands:"
    echo "   make logs          - View all logs"
    echo "   make logs-backend  - View backend logs"
    echo "   make stop          - Stop all services"
    echo ""
else
    echo "❌ Backend failed to start. Check logs with: make logs-backend"
    exit 1
fi

