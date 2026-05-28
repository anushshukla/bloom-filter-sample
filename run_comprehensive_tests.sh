#!/bin/bash

# Run Comprehensive Test Suite for Pure Bloom Filter Functions
# Ensures 100% test coverage and pure function compliance

echo "🧪 Running Comprehensive Test Suite for Pure Bloom Filter Functions"
echo "📝 Testing all functions for purity and 100% coverage"
echo ""

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    echo "❌ Lua is not installed. Please install Lua first."
    echo "   On macOS: brew install lua"
    echo "   On Ubuntu: sudo apt-get install lua5.3"
    exit 1
fi

# Check if backend/bloom_filter.lua exists
if [ ! -f "backend/bloom_filter.lua" ]; then
    echo "❌ backend/bloom_filter.lua not found. Please ensure the bloom filter module exists."
    exit 1
fi

# Check if test file exists
if [ ! -f "backend/tests/test_pure_functions_comprehensive.lua" ]; then
    echo "❌ Test file not found. Please ensure the comprehensive test suite exists."
    exit 1
fi

echo "✅ Dependencies checked successfully"
echo "🚀 Starting comprehensive test suite..."
echo ""

# Create tests directory if it doesn't exist
mkdir -p backend/tests

# Run the comprehensive test suite
cd "$(dirname "$0")"
lua backend/tests/test_pure_functions_comprehensive.lua

echo ""
echo "🎯 Test execution completed!"
echo "📊 Check the results above for coverage and purity verification"
