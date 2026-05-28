#!/bin/bash

echo "🔌 Installing Redis for Bloom Filter Server..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Install Redis
echo "📦 Installing Redis via Homebrew..."
brew install redis

# Start Redis service
echo "🚀 Starting Redis service..."
brew services start redis

# Wait a moment for Redis to start
sleep 2

# Test Redis connection
echo "🧪 Testing Redis connection..."
if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is running successfully!"
    echo "🔌 Redis Host: 127.0.0.1"
    echo "🔌 Redis Port: 6379"
    echo ""
    echo "🚀 You can now start the Bloom Filter server:"
    echo "   lua backend/pure_lua_server.lua"
else
    echo "❌ Redis connection failed. Please check Redis status:"
    echo "   brew services list | grep redis"
    exit 1
fi
