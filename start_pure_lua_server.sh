#!/bin/bash

# Start Pure Lua Bloom Filter Server
# NO PYTHON DEPENDENCIES - Pure Lua implementation

echo "🚀 Starting Pure Lua Bloom Filter Server..."
echo "📝 This server:"
echo "   - Uses ONLY Lua (no Python at all)"
echo "   - Handles file uploads directly in Lua"
echo "   - Creates bloom filters entirely in Lua"
echo "   - Provides lightweight data to frontend"
echo "   - Reduces payload size by 70-80%"
echo ""

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    echo "❌ Lua is not installed. Please install Lua first."
    echo "   On macOS: brew install lua"
    echo "   On Ubuntu: sudo apt-get install lua5.3"
    exit 1
fi

# Check if LuaSocket is available
if ! lua -e "require('socket')" &> /dev/null; then
    echo "❌ LuaSocket is not available. Please install LuaSocket first."
    echo "   On macOS: brew install luarocks && luarocks install luasocket"
    echo "   On Ubuntu: sudo apt-get install lua-socket"
    exit 1
fi

# Check if backend/bloom_filter.lua exists
if [ ! -f "backend/bloom_filter.lua" ]; then
    echo "❌ backend/bloom_filter.lua not found. Please ensure the bloom filter module exists."
    exit 1
fi

# Check if backend/pure_lua_server.lua exists
if [ ! -f "backend/pure_lua_server.lua" ]; then
    echo "❌ backend/pure_lua_server.lua not found. Please ensure the pure Lua server exists."
    exit 1
fi

echo "✅ Dependencies checked successfully"
echo "🌐 Server will run on http://localhost:8080"
echo "📁 API endpoints:"
echo "   POST /api/bloom-filter/create - Upload file and create bloom filter"
echo "   GET  /api/bloom-filter/list - List all bloom filters"
echo "   GET  /api/bloom-filter/{name}/metadata - Get lightweight bloom filter data"
echo "   DELETE /api/bloom-filter/{name} - Delete bloom filter"
echo ""
echo "🚀 Pure Lua Architecture:"
echo "   📁 File Upload → Lua Processing → Bloom Filter Creation → Lightweight Export"
echo "   💾 Frontend gets minimal data (name, size, set_positions only)"
echo "   ⚡ Instant client-side search with reduced payload size"
echo "   🔧 NO PYTHON - Pure Lua efficiency!"
echo ""

# Start the pure Lua server
echo "🚀 Starting pure Lua server..."
cd "$(dirname "$0")"
lua backend/pure_lua_server.lua
