# Bloom Filter Create Endpoint Tests

This directory contains comprehensive test cases for the `/api/bloom-filter/create` endpoint.

## 🧪 Test Scripts

### 1. `quick_test.sh` - Basic Functionality Test
Quick test to verify the endpoint is working:
```bash
./quick_test.sh
```

### 2. `test_create_endpoint.sh` - Comprehensive Bash Tests
Full test suite covering 20 different test scenarios:
```bash
./test_create_endpoint.sh
```

### 3. `test_create_endpoint.py` - Python Test Suite
Comprehensive Python-based test suite (requires `requests` module):
```bash
pip install requests
python3 test_create_endpoint.py
```

## 📋 Test Coverage

### Valid Request Tests (Should Pass)
- ✅ Basic bloom filter creation
- ✅ Large datasets
- ✅ Different false positive rates
- ✅ High expected elements
- ✅ Single element
- ✅ Special characters in content
- ✅ Long filter names
- ✅ Binary-like content
- ✅ Missing optional fields (uses defaults)
- ✅ Large content (100+ items)
- ✅ Performance tests (1000+ items)
- ✅ Duplicate filter names

### Error Handling Tests (Should Fail)
- ❌ Empty file content
- ❌ Missing required fields
- ❌ Invalid data types
- ❌ Out-of-range values

## 🚀 Running Tests

1. **Ensure the server is running:**
   ```bash
   lua backend/pure_lua_server.lua
   ```

2. **Run quick test:**
   ```bash
   ./quick_test.sh
   ```

3. **Run comprehensive tests:**
   ```bash
   ./test_create_endpoint.sh
   ```

## 📊 Expected Results

- **Success Rate:** Should be 100% for valid requests
- **Response Time:** Most requests should complete in <1 second
- **Error Handling:** Invalid requests should return proper error messages
- **Data Validation:** Required fields should be properly validated

## 🔍 Debugging

If tests fail:
1. Check server logs for detailed debugging output
2. Verify Redis is running and accessible
3. Check server response format and CORS headers
4. Ensure all required modules are loaded

## 📝 Test Data

The tests use various sample data:
- **Minimal:** `apple\nbanana`
- **Large:** 10+ fruit names
- **Performance:** 1000+ generated items
- **Special:** Underscores, dashes, spaces, numbers

## 🎯 Success Criteria

A successful test run should show:
- All valid requests return `{"success": true}`
- All invalid requests return `{"success": false, "error": "..."}`
- Response times under 1 second for most requests
- Proper bloom filter data structure returned
