#!/bin/bash

# Test script for http://localhost:8080/api/bloom-filter/create
# Tests various scenarios including valid requests, edge cases, and error conditions

BASE_URL="http://localhost:8080/api/bloom-filter/create"
HEADERS="Content-Type: application/json"

echo "🧪 Testing Bloom Filter Create Endpoint"
echo "======================================"
echo "Base URL: $BASE_URL"
echo ""

# Test 1: Valid request with minimal data
echo "✅ Test 1: Valid request with minimal data"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_minimal",
    "file_content": "apple\nbanana",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 2: Valid request with larger dataset
echo "✅ Test 2: Valid request with larger dataset"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_large_dataset",
    "file_content": "apple\nbanana\ncherry\ndate\nelderberry\nfig\ngrape\nhoneydew\nkiwi\nlemon",
    "expected_elements": 1000,
    "false_positive_rate": 0.001
  }' | jq '.'
echo ""

# Test 3: Test with different false positive rates
echo "✅ Test 3: Test with different false positive rates"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_low_fpr",
    "file_content": "test1\ntest2\ntest3",
    "expected_elements": 100,
    "false_positive_rate": 0.001
  }' | jq '.'
echo ""

# Test 4: Test with high expected elements
echo "✅ Test 4: Test with high expected elements"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_high_elements",
    "file_content": "item1\nitem2\nitem3",
    "expected_elements": 100000,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 5: Test with single element
echo "✅ Test 5: Test with single element"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_single_element",
    "file_content": "single_item",
    "expected_elements": 10,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 6: Test with empty file content (should fail)
echo "❌ Test 6: Test with empty file content (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_empty_content",
    "file_content": "",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 7: Test with missing file_content (should fail)
echo "❌ Test 7: Test with missing file_content (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_missing_content",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 8: Test with invalid JSON (should fail)
echo "❌ Test 8: Test with invalid JSON (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_invalid_json",
    "file_content": "test",
    "expected_elements": "invalid_number",
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 9: Test with very high false positive rate (should fail)
echo "❌ Test 9: Test with very high false positive rate (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_high_fpr",
    "file_content": "test",
    "expected_elements": 100,
    "false_positive_rate": 0.5
  }' | jq '.'
echo ""

# Test 10: Test with very low expected elements (should fail)
echo "❌ Test 10: Test with very low expected elements (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_low_elements",
    "file_content": "test",
    "expected_elements": 1,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 11: Test with special characters in content
echo "✅ Test 11: Test with special characters in content"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_special_chars",
    "file_content": "item_with_underscore\nitem-with-dash\nitem with spaces\nitem123",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 12: Test with very long filter name
echo "✅ Test 12: Test with very long filter name"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "very_long_filter_name_that_exceeds_normal_length_limits_and_tests_edge_cases",
    "file_content": "test",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 13: Test with binary content (should work)
echo "✅ Test 13: Test with binary-like content"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_binary_like",
    "file_content": "0x123456\n0xabcdef\n0xdeadbeef",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 14: Test with missing filter_name (should fail)
echo "❌ Test 14: Test with missing filter_name (should fail)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "file_content": "test",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 15: Test with missing expected_elements (should use default)
echo "✅ Test 15: Test with missing expected_elements (should use default)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_default_elements",
    "file_content": "test1\ntest2\ntest3",
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 16: Test with missing false_positive_rate (should use default)
echo "✅ Test 16: Test with missing false_positive_rate (should use default)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_default_fpr",
    "file_content": "test1\ntest2\ntest3",
    "expected_elements": 100
  }' | jq '.'
echo ""

# Test 17: Test with all defaults (should work)
echo "✅ Test 17: Test with all defaults (should work)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_all_defaults",
    "file_content": "test"
  }' | jq '.'
echo ""

# Test 18: Test with very large content
echo "✅ Test 18: Test with very large content"
LARGE_CONTENT=$(for i in {1..100}; do echo "item_$i"; done | tr '\n' '\n')
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d "{
    \"filter_name\": \"test_large_content\",
    \"file_content\": \"$LARGE_CONTENT\",
    \"expected_elements\": 1000,
    \"false_positive_rate\": 0.01
  }" | jq '.'
echo ""

# Test 19: Test with duplicate filter name (should work, creates new filter)
echo "✅ Test 19: Test with duplicate filter name (should work, creates new filter)"
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_duplicate",
    "file_content": "first_content",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d '{
    "filter_name": "test_duplicate",
    "file_content": "second_content",
    "expected_elements": 100,
    "false_positive_rate": 0.01
  }' | jq '.'
echo ""

# Test 20: Performance test with many elements
echo "✅ Test 20: Performance test with many elements"
PERF_CONTENT=$(for i in {1..1000}; do echo "perf_item_$i"; done | tr '\n' '\n')
curl -s -X POST "$BASE_URL" \
  -H "$HEADERS" \
  -d "{
    \"filter_name\": \"test_performance\",
    \"file_content\": \"$PERF_CONTENT\",
    \"expected_elements\": 10000,
    \"false_positive_rate\": 0.001
  }" | jq '.'
echo ""

echo "🎯 All tests completed!"
echo "Check the responses above for success/failure patterns."
echo ""
echo "Expected Results:"
echo "- Tests 1-5, 11-13, 15-20: Should return success with filter data"
echo "- Tests 6-10, 14: Should return error messages"
echo "- Test 19: Should create two filters with the same name"
