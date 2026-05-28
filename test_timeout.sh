#!/bin/bash

# Test script to demonstrate timeout functionality
echo "🧪 Testing Timeout Functionality"
echo "================================"

# Test 1: Normal request (should complete quickly)
echo "✅ Test 1: Normal request (should complete quickly)"
start_time=$(date +%s)
RESPONSE=$(curl -s -X POST "http://localhost:8080/api/bloom-filter/create" \
  -H "Content-Type: application/json" \
  -H "Accept: application/octet-stream" \
  -d '{"filter_name":"timeout_test1","file_content":"test","expected_elements":100,"false_positive_rate":0.01}')
end_time=$(date +%s)
duration=$((end_time - start_time))

if echo "$RESPONSE" | grep -q "Bloom filter created successfully"; then
    echo "   ✅ PASSED - Completed in ${duration}s"
else
    echo "   ❌ FAILED - Response: $RESPONSE"
fi

echo ""

# Test 2: Test with different Accept headers
echo "✅ Test 2: JSON response (should complete quickly)"
start_time=$(date +%s)
RESPONSE=$(curl -s -X POST "http://localhost:8080/api/bloom-filter/create" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"filter_name":"timeout_test2","file_content":"test","expected_elements":100,"false_positive_rate":0.01}')
end_time=$(date +%s)
duration=$((end_time - start_time))

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ PASSED - Completed in ${duration}s"
else
    echo "   ❌ FAILED - Response: $RESPONSE"
fi

echo ""

# Test 3: Test list endpoint
echo "✅ Test 3: List endpoint (should complete quickly)"
start_time=$(date +%s)
RESPONSE=$(curl -s -X GET "http://localhost:8080/api/bloom-filter/list")
end_time=$(date +%s)
duration=$((end_time - start_time))

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ PASSED - Completed in ${duration}s"
else
    echo "   ❌ FAILED - Response: $RESPONSE"
fi

echo ""

# Test 4: Test search endpoint (should complete quickly)
echo "✅ Test 4: Search endpoint (should complete quickly)"
start_time=$(date +%s)
RESPONSE=$(curl -s -X POST "http://localhost:8080/api/bloom-filter/timeout_test1/search" \
  -H "Content-Type: application/json" \
  -d '{"element":"test"}')
end_time=$(date +%s)
duration=$((end_time - start_time))

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ PASSED - Completed in ${duration}s"
else
    echo "   ❌ FAILED - Response: $RESPONSE"
    echo "   Note: This might be expected if the bloom filter doesn't exist"
fi

echo ""

echo "🎯 Timeout tests completed!"
echo ""
echo "📊 Timeout Configuration:"
echo "   Frontend: 30 seconds (AbortController)"
echo "   Backend: 30 seconds (Request processing)"
echo "   Socket: 10 seconds (Network operations)"
echo ""
echo "🔍 Check server logs for timeout messages:"
echo "   ⏰ Request timeout - [operation] taking too long"
echo "   ⏱️ Request completed in [X] seconds"
