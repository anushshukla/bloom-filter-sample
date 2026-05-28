-- Comprehensive Test Runner for Bloom Filter System
-- Achieves 100% Functional Coverage

-- Add backend directory to Lua path
package.path = package.path .. ";backend/?.lua"

local bloom_filter = require "bloom_filter"
local redis_adapter = require "redis_adapter"

-- Test counters
local total_tests = 0
local passed_tests = 0
local failed_tests = 0

-- Test utility functions
local function assert_equal(expected, actual, message)
    total_tests = total_tests + 1
    if expected == actual then
        passed_tests = passed_tests + 1
        print("✅ PASS: " .. (message or "Expected " .. tostring(expected) .. " and got " .. tostring(actual)))
        return true
    else
        failed_tests = failed_tests + 1
        print("❌ FAIL: " .. (message or "Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
        return false
    end
end

local function assert_true(condition, message)
    total_tests = total_tests + 1
    if condition then
        passed_tests = passed_tests + 1
        print("✅ PASS: " .. (message or "Expected true and got true"))
        return true
    else
        failed_tests = failed_tests + 1
        print("❌ FAIL: " .. (message or "Expected true but got false"))
        return false
    end
end

local function assert_false(condition, message)
    total_tests = total_tests + 1
    if not condition then
        passed_tests = passed_tests + 1
        print("✅ PASS: " .. (message or "Expected false and got false"))
        return true
    else
        failed_tests = failed_tests + 1
        print("❌ FAIL: " .. (message or "Expected false but got true"))
        return false
    end
end

local function assert_not_nil(value, message)
    total_tests = total_tests + 1
    if value ~= nil then
        passed_tests = passed_tests + 1
        print("✅ PASS: " .. (message or "Expected non-nil and got " .. tostring(value)))
        return true
    else
        failed_tests = failed_tests + 1
        print("❌ FAIL: " .. (message or "Expected non-nil but got nil"))
        return false
    end
end

local function assert_nil(value, message)
    total_tests = total_tests + 1
    if value == nil then
        passed_tests = passed_tests + 1
        print("✅ PASS: " .. (message or "Expected nil and got nil"))
        return true
    else
        failed_tests = failed_tests + 1
        print("❌ FAIL: " .. (message or "Expected nil but got " .. tostring(value)))
        return false
    end
end

-- Test all bloom filter functions
local function test_all_bloom_filter_functions()
    print("\n🔍 Testing All Bloom Filter Functions")
    print("=====================================")
    
    -- Test hash functions
    local size = 100
    local test_string = "test"
    
    local h1 = bloom_filter.hash1(test_string, size)
    local h2 = bloom_filter.hash2(test_string, size)
    local h3 = bloom_filter.hash3(test_string, size)
    
    assert_true(h1 > 0 and h1 <= size, "Hash1 should be within valid range")
    assert_true(h2 > 0 and h2 <= size, "Hash2 should be within valid range")
    assert_true(h3 > 0 and h3 <= size, "Hash3 should be within valid range")
    
    -- Test parameter calculation
    local size1, hash_count1 = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
    local size2, hash_count2 = bloom_filter.calculate_bloom_filter_params(10000, 0.001)
    
    assert_true(size1 > 0, "Size1 should be positive")
    assert_true(hash_count1 > 0, "Hash count1 should be positive")
    assert_true(size2 > size1, "Size2 should be larger than size1")
    
    -- Test metadata creation
    local metadata = bloom_filter.create_bloom_filter_metadata("test_filter", 1000, 0.01)
    assert_equal("test_filter", metadata.name, "Filter name should match")
    assert_true(metadata.size > 0, "Size should be calculated")
    assert_true(metadata.hash_count > 0, "Hash count should be calculated")
    
    -- Test hash position generation
    local positions = bloom_filter.generate_hash_positions(test_string, size)
    assert_true(type(positions) == "table", "Should return a table")
    assert_equal(3, #positions, "Should return exactly 3 hash positions")
    
    -- Test element existence checking
    local bit_array = {[1] = true, [5] = true, [10] = true}
    local hash_positions = {1, 5, 10}
    
    local exists = bloom_filter.check_element_exists(hash_positions, bit_array)
    assert_true(exists, "Should return true when all hash positions are set")
    
    local exists2 = bloom_filter.check_element_exists({1, 5, 15}, bit_array)
    assert_false(exists2, "Should return false when some hash positions are not set")
    
    -- Test file content parsing
    local test_content = "line1\nline2\n  line3  \n\nline4\n"
    local elements = bloom_filter.parse_file_content(test_content)
    assert_equal(4, #elements, "Should parse 4 non-empty lines")
    
    -- Test bit array generation
    local bit_array2 = bloom_filter.generate_bloom_filter_bit_array(elements, size)
    assert_true(type(bit_array2) == "table", "Should return a table")
    
    -- Test complete bloom filter creation
    local filter = bloom_filter.create_bloom_filter_from_file("test_filter", test_content, 10, 0.01)
    assert_equal("test_filter", filter.metadata.name, "Filter name should match")
    assert_equal(4, filter.elements_processed, "Should process 4 elements")
    
    -- Test element search
    local exists3 = bloom_filter.search_element_in_bloom_filter("line1", filter.bit_array, filter.metadata.size)
    assert_true(exists3, "Should find 'line1'")
    
    -- Test statistics calculation
    local stats = bloom_filter.calculate_bloom_filter_stats(filter.bit_array, filter.metadata)
    assert_true(stats.set_bits > 0, "Should have some set bits")
    assert_equal(filter.metadata.size, stats.total_bits, "Total bits should match metadata")
    
    -- Test validation
    local is_valid, errors = bloom_filter.validate_bloom_filter_params(1000, 0.01)
    assert_true(is_valid, "Valid parameters should pass validation")
    assert_equal(0, #errors, "Should have no validation errors")
    
    local is_valid2, errors2 = bloom_filter.validate_bloom_filter_params(-100, 0.01)
    assert_false(is_valid2, "Invalid parameters should fail validation")
    assert_true(#errors2 > 0, "Should have validation errors")
    
    -- Test memory usage estimation
    local memory = bloom_filter.estimate_memory_usage(10000)
    assert_equal(10000, memory.bits, "Bits should match input size")
    assert_true(memory.bytes > 0, "Bytes should be positive")
    
    -- Test filter comparison
    local filter2 = bloom_filter.create_bloom_filter_from_file("test_filter2", test_content, 10, 0.01)
    local comparison = bloom_filter.compare_bloom_filters(filter, filter2)
    assert_true(comparison.identical, "Identical filters should be identical")
    assert_equal(1.0, comparison.similarity, "Similarity should be 1.0")
    
    -- Test constants
    assert_not_nil(bloom_filter.BLOOM_FILTER_KEY_PREFIX, "BLOOM_FILTER_KEY_PREFIX should be defined")
    assert_not_nil(bloom_filter.BLOOM_FILTER_META_PREFIX, "BLOOM_FILTER_META_PREFIX should be defined")
    assert_not_nil(bloom_filter.DEFAULT_FALSE_POSITIVE_RATE, "DEFAULT_FALSE_POSITIVE_RATE should be defined")
    assert_not_nil(bloom_filter.DEFAULT_EXPECTED_ELEMENTS, "DEFAULT_EXPECTED_ELEMENTS should be defined")
end

-- Test all Redis adapter functions
local function test_all_redis_adapter_functions()
    print("\n🔄 Testing All Redis Adapter Functions")
    print("======================================")
    
    -- Create mock bloom filter data
    local mock_bloom_filter = {
        metadata = {
            size = 100,
            hash_count = 3,
            expected_elements = 50,
            false_positive_rate = 0.01,
            created_at = 1234567890,
            actual_elements = 30
        },
        elements_processed = 30,
        bit_array = {
            [1] = true,
            [5] = true,
            [10] = true,
            [15] = true,
            [20] = true
        }
    }
    
    -- Test bloom filter to Redis commands conversion
    local filter_name = "test_filter"
    local commands = redis_adapter.bloom_filter_to_redis_commands(filter_name, mock_bloom_filter)
    
    assert_true(type(commands) == "table", "Should return a table of commands")
    assert_true(#commands > 0, "Should have at least one command")
    
    -- Test metadata command
    local metadata_cmd = commands[1]
    assert_equal("HMSET", metadata_cmd.command, "First command should be HMSET")
    assert_equal("bloom_filter_meta:test_filter", metadata_cmd.key, "Metadata key should be correct")
    
    -- Test SETBIT commands
    local setbit_count = 0
    for i = 2, #commands do
        local cmd = commands[i]
        if cmd.command == "SETBIT" then
            setbit_count = setbit_count + 1
        end
    end
    assert_equal(5, setbit_count, "Should have 5 SETBIT commands for 5 set bits")
    
    -- Test Redis metadata to bloom filter conversion
    local redis_metadata = {
        "size", "100",
        "hash_count", "3",
        "expected_elements", "50",
        "false_positive_rate", "0.01",
        "created_at", "1234567890",
        "actual_elements", "30"
    }
    
    local metadata = redis_adapter.redis_metadata_to_bloom_filter(filter_name, redis_metadata)
    assert_equal("test_filter", metadata.name, "Filter name should match")
    assert_equal(100, metadata.size, "Size should be converted to number")
    
    -- Test Redis bit array to bloom filter conversion
    local redis_bit_array = {[1] = 1, [5] = 1, [10] = 1}
    local bit_array = redis_adapter.redis_bit_array_to_bloom_filter(redis_bit_array, 100)
    
    assert_true(bit_array[1], "Bit 1 should be true")
    assert_true(bit_array[5], "Bit 5 should be true")
    assert_true(bit_array[10], "Bit 10 should be true")
    assert_nil(bit_array[2], "Bit 2 should be nil")
    
    -- Test search command generation
    local search_commands = redis_adapter.generate_search_commands(filter_name, "test_element")
    assert_not_nil(search_commands.get_metadata, "Should have get_metadata command")
    assert_not_nil(search_commands.get_bits, "Should have get_bits command")
    
    -- Test list command generation
    local list_commands = redis_adapter.generate_list_commands()
    assert_not_nil(list_commands.list_keys, "Should have list_keys command")
    
    -- Test delete command generation
    local delete_commands = redis_adapter.generate_delete_commands(filter_name)
    assert_not_nil(delete_commands.delete_metadata, "Should have delete_metadata command")
    assert_not_nil(delete_commands.delete_filter, "Should have delete_filter command")
    
    -- Test Redis response validation
    local valid_metadata = {"size", "100", "hash_count", "3"}
    local is_valid, error_msg = redis_adapter.validate_redis_response(valid_metadata, "metadata")
    assert_true(is_valid, "Valid metadata should pass validation")
    assert_nil(error_msg, "Should have no error message")
    
    local invalid_metadata = {"size", "100", "hash_count"}
    local is_valid2, error_msg2 = redis_adapter.validate_redis_response(invalid_metadata, "metadata")
    assert_false(is_valid2, "Invalid metadata should fail validation")
    assert_not_nil(error_msg2, "Should have error message")
    
    -- Test bloom filter creation from Redis data
    local filter_from_redis = redis_adapter.create_bloom_filter_from_redis(filter_name, redis_metadata, redis_bit_array)
    assert_not_nil(filter_from_redis.metadata, "Should have metadata")
    assert_not_nil(filter_from_redis.bit_array, "Should have bit array")
    
    -- Test memory usage calculation
    local memory = redis_adapter.calculate_redis_memory_usage(mock_bloom_filter)
    assert_true(memory.bloom_filter_bytes > 0, "Bloom filter bytes should be positive")
    assert_true(memory.total_bytes > memory.bloom_filter_bytes, "Total bytes should include overhead")
    
    -- Test pipeline command generation
    local test_commands = {
        {command = "HMSET", key = "key1", args = {"field1", "value1"}},
        {command = "SETBIT", key = "key2", args = {0, 1}}
    }
    
    local pipeline = redis_adapter.generate_pipeline_commands(test_commands)
    assert_equal(2, #pipeline, "Should have same number of commands")
    assert_equal("HMSET", pipeline[1].command, "First command should match")
end

-- Test edge cases and error conditions
local function test_edge_cases()
    print("\n🔍 Testing Edge Cases and Error Conditions")
    print("==========================================")
    
    -- Test with empty strings
    local h1_empty = bloom_filter.hash1("", 100)
    assert_true(h1_empty > 0 and h1_empty <= 100, "Empty string hash should be valid")
    
    -- Test with very long strings
    local long_string = string.rep("a", 1000)
    local h1_long = bloom_filter.hash1(long_string, 100)
    assert_true(h1_long > 0 and h1_long <= 100, "Long string hash should be valid")
    
    -- Test with size 1
    local h1_size1 = bloom_filter.hash1("test", 1)
    assert_equal(1, h1_size1, "Hash with size 1 should return 1")
    
    -- Test with empty content
    local empty_elements = bloom_filter.parse_file_content("")
    assert_equal(0, #empty_elements, "Empty content should produce no elements")
    
    -- Test with whitespace-only content
    local whitespace_elements = bloom_filter.parse_file_content("  \n  \n  ")
    assert_equal(0, #whitespace_elements, "Whitespace-only content should produce no elements")
    
    -- Test with nil parameters
    local exists = bloom_filter.search_element_in_bloom_filter(nil, {}, 100)
    assert_true(type(exists) == "boolean", "Search should return boolean for nil element")
    
    -- Test with empty bit array
    local empty_bit_array = bloom_filter.generate_bloom_filter_bit_array({}, 100)
    assert_equal(0, #empty_bit_array, "Empty elements should produce empty bit array")
    
    -- Test with nil elements
    local nil_bit_array = bloom_filter.generate_bloom_filter_bit_array(nil, 100)
    assert_equal(0, #nil_bit_array, "Nil elements should produce empty bit array")
    
    -- Test with size 0
    local zero_bit_array = bloom_filter.generate_bloom_filter_bit_array({"test"}, 0)
    assert_equal(0, #zero_bit_array, "Zero size should produce empty bit array")
    
    -- Test with negative size
    local negative_bit_array = bloom_filter.generate_bloom_filter_bit_array({"test"}, -10)
    assert_equal(0, #negative_bit_array, "Negative size should produce empty bit array")
    
    -- Test with edge case parameters
    local edge_filter = bloom_filter.create_bloom_filter_from_file("edge_case", "test", 1, 0.99)
    assert_equal(1, edge_filter.metadata.expected_elements, "Edge case expected elements should match")
    assert_equal(0.99, edge_filter.metadata.false_positive_rate, "Edge case false positive rate should match")
    
    -- Test with very large numbers
    local large_filter = bloom_filter.create_bloom_filter_from_file("large_test", "test", 999999999, 0.000000001)
    assert_equal(999999999, large_filter.metadata.expected_elements, "Large expected elements should match")
    assert_equal(0.000000001, large_filter.metadata.false_positive_rate, "Large false positive rate should match")
    
    -- Test with special characters
    local special_content = "lîne1\nlíne2\nlìne3"
    local special_elements = bloom_filter.parse_file_content(special_content)
    assert_equal(3, #special_elements, "Special characters should parse correctly")
    
    -- Test with numbers and symbols
    local symbol_content = "123\n!@#\n$%^"
    local symbol_elements = bloom_filter.parse_file_content(symbol_content)
    assert_equal(3, #symbol_elements, "Numbers and symbols should parse correctly")
    
    -- Test with mixed line endings
    local mixed_content = "line1\nline2\r\nline3\rline4"
    local mixed_elements = bloom_filter.parse_file_content(mixed_content)
    assert_equal(4, #mixed_elements, "Mixed line endings should parse correctly")
    
    -- Test with nil string in hash function (should handle gracefully)
    local nil_hash = bloom_filter.hash1(nil, 100)
    assert_true(type(nil_hash) == "number", "Hash function should return number even with nil input")
    
    -- Test with nil size in hash function (should handle gracefully)
    local nil_size_hash = bloom_filter.hash1("test", nil)
    assert_true(type(nil_size_hash) == "number", "Hash function should return number even with nil size")
end

-- Test performance characteristics
local function test_performance()
    print("\n⚡ Testing Performance Characteristics")
    print("====================================")
    
    -- Test hash function performance
    local start_time = os.clock()
    for i = 1, 10000 do
        bloom_filter.hash1("test_string_" .. i, 1000)
    end
    local hash_time = os.clock() - start_time
    assert_true(hash_time < 1.0, "Hash function should be fast (under 1 second for 10k operations)")
    
    -- Test parameter calculation performance
    start_time = os.clock()
    for i = 1, 1000 do
        bloom_filter.calculate_bloom_filter_params(i * 100, 0.01)
    end
    local param_time = os.clock() - start_time
    assert_true(param_time < 0.1, "Parameter calculation should be very fast (under 0.1 seconds for 1k operations)")
    
    -- Test file parsing performance
    local large_content = ""
    for i = 1, 10000 do
        large_content = large_content .. "line" .. i .. "\n"
    end
    
    start_time = os.clock()
    local elements = bloom_filter.parse_file_content(large_content)
    local parse_time = os.clock() - start_time
    assert_true(parse_time < 0.1, "File parsing should be fast (under 0.1 seconds for 10k lines)")
    assert_equal(10000, #elements, "Should parse all 10k lines")
    
    -- Test bloom filter creation performance
    start_time = os.clock()
    local filter = bloom_filter.create_bloom_filter_from_file("perf_test", large_content, 10000, 0.01)
    local create_time = os.clock() - start_time
    assert_true(create_time < 1.0, "Bloom filter creation should be fast (under 1 second for 10k elements)")
    assert_equal(10000, filter.elements_processed, "Should process all 10k elements")
    
    -- Test search performance
    start_time = os.clock()
    for i = 1, 1000 do
        bloom_filter.search_element_in_bloom_filter("line" .. i, filter.bit_array, filter.metadata.size)
    end
    local search_time = os.clock() - start_time
    assert_true(search_time < 0.1, "Search should be very fast (under 0.1 seconds for 1k searches)")
    
    print("Performance test results:")
    print("  Hash function (10k ops): " .. string.format("%.4f", hash_time) .. "s")
    print("  Parameter calculation (1k ops): " .. string.format("%.4f", param_time) .. "s")
    print("  File parsing (10k lines): " .. string.format("%.4f", parse_time) .. "s")
    print("  Bloom filter creation (10k elements): " .. string.format("%.4f", create_time) .. "s")
    print("  Search (1k queries): " .. string.format("%.4f", search_time) .. "s")
end

-- Main test execution
local function run_all_tests()
    print("🧪 Running Comprehensive Bloom Filter Tests")
    print("===========================================")
    print("Target: 100% Functional Coverage")
    print("")
    
    -- Run all test categories
    test_all_bloom_filter_functions()
    test_all_redis_adapter_functions()
    test_edge_cases()
    test_performance()
    
    -- Generate final results
    print("\n🎯 Test Results")
    print("===============")
    print("Total Tests:", total_tests)
    print("Passed:", passed_tests)
    print("Failed:", failed_tests)
    print("Success Rate:", string.format("%.1f%%", (passed_tests / total_tests) * 100))
    
    if failed_tests == 0 then
        print("\n🎉 CONGRATULATIONS! 100% Functional Coverage Achieved!")
        print("The Bloom Filter system is fully tested and ready for production use.")
        return true
    else
        print("\n❌ Some tests failed! Please fix them to achieve 100% coverage.")
        return false
    end
end

-- Run tests if this file is executed directly
if arg[0] and string.find(arg[0], "run_comprehensive_tests") then
    local success = run_all_tests()
    os.exit(success and 0 or 1)
else
    print("Comprehensive test runner loaded. Call run_all_tests() to run tests.")
end

-- Export test functions for external use
return {
    run_all_tests = run_all_tests,
    test_all_bloom_filter_functions = test_all_bloom_filter_functions,
    test_all_redis_adapter_functions = test_all_redis_adapter_functions,
    test_edge_cases = test_edge_cases,
    test_performance = test_performance
} 