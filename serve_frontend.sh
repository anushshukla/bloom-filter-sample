#!/bin/bash

# Simple HTTP server to serve the frontend with proper CORS support
echo "🌐 Starting HTTP server for frontend..."
echo "📍 Frontend will be available at: http://localhost:3000"
echo "🔗 Open: http://localhost:3000/frontend/index.html"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    echo "✅ Using Python 3 HTTP server"
    cd frontend && python3 -m http.server 3000
elif command -v python &> /dev/null; then
    echo "✅ Using Python HTTP server"
    cd frontend && python -m SimpleHTTPServer 3000
elif command -v node &> /dev/null; then
    echo "✅ Using Node.js HTTP server"
    cd frontend && npx http-server -p 3000 --cors
else
    echo "❌ No suitable HTTP server found"
    echo "Please install Python 3, Python 2, or Node.js"
    exit 1
fi
