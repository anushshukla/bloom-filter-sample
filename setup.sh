#!/bin/bash

# Bloom Filter System Setup Script
# This script helps set up the Redis backend and frontend application

echo "🚀 Setting up Bloom Filter System..."

# Check if Redis is installed
if ! command -v redis-server &> /dev/null; then
    echo "❌ Redis is not installed. Please install Redis first:"
    echo "   macOS: brew install redis"
    echo "   Ubuntu/Debian: sudo apt-get install redis-server"
    echo "   CentOS/RHEL: sudo yum install redis"
    exit 1
fi

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    echo "❌ Lua is not installed. Please install Lua first:"
    echo "   macOS: brew install lua"
    echo "   Ubuntu/Debian: sudo apt-get install lua5.3"
    echo "   CentOS/RHEL: sudo yum install lua"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first:"
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

echo "✅ Dependencies check passed"

# Start Redis server
echo "🔴 Starting Redis server..."
redis-server --daemonize yes
sleep 2

# Check if Redis is running
if ! redis-cli ping &> /dev/null; then
    echo "❌ Failed to start Redis server"
    exit 1
fi

echo "✅ Redis server started successfully"

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install
cd ..

echo "✅ Setup completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Start the frontend: cd frontend && npm run dev"
echo "2. Open http://localhost:3000 in your browser"
echo "3. Upload the sample file: test_data/sample_words.txt"
echo "4. Create a bloom filter and start searching!"
echo ""
echo "🔧 To stop Redis: redis-cli shutdown"
echo "🔧 To start Redis manually: redis-server" 