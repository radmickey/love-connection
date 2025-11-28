#!/bin/bash

set -e

echo "🛑 Stopping Love Connection services..."

docker-compose down

echo "✅ Services stopped"

