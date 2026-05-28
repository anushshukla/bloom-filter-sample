#!/bin/bash

# Quick test for bloom filter create endpoint
echo "🧪 Quick Test: Bloom Filter Create Endpoint"
echo "=========================================="

# Test basic functionality
echo "✅ Testing basic bloom filter creation..."
RESPONSE=$(curl -s -X POST "http://localhost:8080/api/bloom-filter/create" \
  -H "Content-Type: application/json" \
  -d '{
    "filter_name": "quick_test",
    "file_content": "apple\nbanana\ncherry",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }')

echo "Response: $RESPONSE"

# Check if successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ Test PASSED - Bloom filter created successfully"
else
    echo "❌ Test FAILED - Bloom filter creation failed"
fi

echo ""
echo "🎯 Quick test completed!"
