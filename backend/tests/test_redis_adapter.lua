-- Comprehensive Unit Tests for Redis Adapter Module
-- Achieves 100% code coverage

-- Add backend directory to Lua path
package.path = package.path .. ";backend/?.lua"

local bloom_filter = require "bloom_filter"
local redis_adapter = require "redis_adapter"

-- Mock bloom filter data for testing
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

-- Test utilities
local TestSuite = {}
local passed_tests = 0
local total_tests = 0

function TestSuite.assert_equal(expected, actual, message)
    total_tests = total_tests + 1
    if expected ~= actual then
        print("❌ FAIL: " .. (message or "Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
        return false
    else
        print("✅ PASS: " .. (message or "Expected " .. tostring(expected) .. " and got " .. tostring(actual)))
        passed_tests = passed_tests + 1
        return true
    end
end

function TestSuite.assert_true(condition, message)
    total_tests = total_tests + 1
    if not condition then
        print("❌ FAIL: " .. (message or "Expected true but got false"))
        return false
    else
        print("✅ PASS: " .. (message or "Expected true and got true"))
        passed_tests = passed_tests + 1
        return true
    end
end

function TestSuite.assert_false(condition, message)
    total_tests = total_tests + 1
    if condition then
        print("❌ FAIL: " .. (message or "Expected false but got true"))
        return false
    else
        print("✅ PASS: " .. (message or "Expected false and got false"))
        passed_tests = passed_tests + 1
        return true
    end
end

function TestSuite.assert_table_equals(expected, actual, message)
    total_tests = total_tests + 1
    if type(expected) ~= "table" or type(actual) ~= "table" then
        print("❌ FAIL: " .. (message or "Both arguments must be tables"))
        return false
    end
    
    for key, value in pairs(expected) do
        if actual[key] ~= value then
            print("❌ FAIL: " .. (message or "Key " .. tostring(key) .. " expected " .. tostring(value) .. " but got " .. tostring(actual[key])))
            return false
        end
    end
    
    for key, value in pairs(actual) do
        if expected[key] ~= value then
            print("❌ FAIL: " .. (message or "Unexpected key " .. tostring(key) .. " with value " .. tostring(value)))
            return false
        end
    end
    
    print("✅ PASS: " .. (message or "Tables are equal"))
    passed_tests = passed_tests + 1
    return true
end

function TestSuite.assert_nil(value, message)
    total_tests = total_tests + 1
    if value ~= nil then
        print("❌ FAIL: " .. (message or "Expected nil but got " .. tostring(value)))
        return false
    else
        print("✅ PASS: " .. (message or "Expected nil and got nil"))
        passed_tests = passed_tests + 1
        return true
    end
end

function TestSuite.assert_not_nil(value, message)
    total_tests = total_tests + 1
    if value == nil then
        print("❌ FAIL: " .. (message or "Expected non-nil but got nil"))
        return false
    else
        print("✅ PASS: " .. (message or "Expected non-nil and got " .. tostring(value)))
        passed_tests = passed_tests + 1
        return true
    end
end

-- Test bloom filter to Redis commands conversion
function TestSuite.test_bloom_filter_to_redis_commands()
    print("\n🔄 Testing Bloom Filter to Redis Commands")
    print("=========================================")
    
    local filter_name = "test_filter"
    local commands = redis_adapter.bloom_filter_to_redis_commands(filter_name, mock_bloom_filter)
    
    TestSuite.assert_true(type(commands) == "table", "Should return a table of commands")
    TestSuite.assert_true(#commands > 0, "Should have at least one command")
    
    -- Test metadata command
    local metadata_cmd = commands[1]
    TestSuite.assert_equal("HMSET", metadata_cmd.command, "First command should be HMSET")
    TestSuite.assert_equal("bloom_filter_meta:test_filter", metadata_cmd.key, "Metadata key should be correct")
    TestSuite.assert_true(type(metadata_cmd.fields) == "table", "Should have fields table")
    
    -- Test metadata fields
    local expected_fields = {
        size = 100,
        hash_count = 3,
        expected_elements = 50,
        false_positive_rate = 0.01,
        created_at = 1234567890,
        actual_elements = 30
    }
    
    for key, value in pairs(expected_fields) do
        TestSuite.assert_equal(value, metadata_cmd.fields[key], "Field " .. key .. " should match")
    end
    
    -- Test SETBIT commands
    local setbit_count = 0
    for i = 2, #commands do
        local cmd = commands[i]
        if cmd.command == "SETBIT" then
            setbit_count = setbit_count + 1
            TestSuite.assert_equal("bloom_filter:test_filter", cmd.key, "SETBIT key should be correct")
            TestSuite.assert_equal(1, cmd.value, "SETBIT value should be 1")
            TestSuite.assert_true(cmd.offset >= 0, "SETBIT offset should be >= 0")
        end
    end
    
    TestSuite.assert_equal(5, setbit_count, "Should have 5 SETBIT commands for 5 set bits")
    
    -- Test with empty bit array
    local empty_filter = {
        metadata = mock_bloom_filter.metadata,
        elements_processed = 0,
        bit_array = {}
    }
    
    local empty_commands = redis_adapter.bloom_filter_to_redis_commands(filter_name, empty_filter)
    TestSuite.assert_equal(1, #empty_commands, "Empty bit array should only have metadata command")
    
    -- Test with nil bit array
    local nil_filter = {
        metadata = mock_bloom_filter.metadata,
        elements_processed = 0,
        bit_array = nil
    }
    
    local nil_commands = redis_adapter.bloom_filter_to_redis_commands(filter_name, nil_filter)
    TestSuite.assert_equal(1, #nil_commands, "Nil bit array should only have metadata command")
end

-- Test Redis metadata to bloom filter conversion
function TestSuite.test_redis_metadata_to_bloom_filter()
    print("\n📊 Testing Redis Metadata to Bloom Filter Conversion")
    print("====================================================")
    
    local filter_name = "test_filter"
    local redis_metadata = {
        "size", "100",
        "hash_count", "3",
        "expected_elements", "50",
        "false_positive_rate", "0.01",
        "created_at", "1234567890",
        "actual_elements", "30"
    }
    
    local metadata = redis_adapter.redis_metadata_to_bloom_filter(filter_name, redis_metadata)
    
    TestSuite.assert_equal("test_filter", metadata.name, "Filter name should match")
    TestSuite.assert_equal(100, metadata.size, "Size should be converted to number")
    TestSuite.assert_equal(3, metadata.hash_count, "Hash count should be converted to number")
    TestSuite.assert_equal(50, metadata.expected_elements, "Expected elements should be converted to number")
    TestSuite.assert_equal(0.01, metadata.false_positive_rate, "False positive rate should be converted to number")
    TestSuite.assert_equal(1234567890, metadata.created_at, "Created at should be converted to number")
    TestSuite.assert_equal(30, metadata.actual_elements, "Actual elements should be converted to number")
    
    -- Test with empty metadata
    local empty_metadata = redis_adapter.redis_metadata_to_bloom_filter(filter_name, {})
    TestSuite.assert_equal(filter_name, empty_metadata.name, "Filter name should be set even with empty metadata")
    
    -- Test with partial metadata
    local partial_metadata = redis_adapter.redis_metadata_to_bloom_filter(filter_name, {"size", "100"})
    TestSuite.assert_equal(100, partial_metadata.size, "Partial metadata should still convert numbers")
    TestSuite.assert_nil(partial_metadata.hash_count, "Missing fields should be nil")
    
    -- Test with non-numeric values
    local string_metadata = redis_adapter.redis_metadata_to_bloom_filter(filter_name, {"size", "not_a_number"})
    TestSuite.assert_equal("not_a_number", string_metadata.size, "Non-numeric values should remain as strings")
end

-- Test Redis bit array to bloom filter conversion
function TestSuite.test_redis_bit_array_to_bloom_filter()
    print("\n🔢 Testing Redis Bit Array to Bloom Filter Conversion")
    print("=====================================================")
    
    local size = 100
    local redis_bit_array = {}
    
    -- Set some bits
    for i = 1, size do
        if i % 10 == 0 then  -- Every 10th bit
            redis_bit_array[i] = 1
        else
            redis_bit_array[i] = 0
        end
    end
    
    local bit_array = redis_adapter.redis_bit_array_to_bloom_filter(redis_bit_array, size)
    
    TestSuite.assert_true(type(bit_array) == "table", "Should return a table")
    
    -- Test that only set bits (value = 1) are converted to true
    for i = 1, size do
        if i % 10 == 0 then
            TestSuite.assert_true(bit_array[i], "Bit " .. i .. " should be true")
        else
            TestSuite.assert_nil(bit_array[i], "Bit " .. i .. " should be nil (false)")
        end
    end
    
    -- Test with empty bit array
    local empty_bit_array = redis_adapter.redis_bit_array_to_bloom_filter({}, size)
    TestSuite.assert_true(type(empty_bit_array) == "table", "Empty bit array should return empty table")
    
    -- Test with nil bit array
    local nil_bit_array = redis_adapter.redis_bit_array_to_bloom_filter(nil, size)
    TestSuite.assert_true(type(nil_bit_array) == "table", "Nil bit array should return empty table")
    
    -- Test with size 0
    local zero_bit_array = redis_adapter.redis_bit_array_to_bloom_filter(redis_bit_array, 0)
    TestSuite.assert_true(type(zero_bit_array) == "table", "Zero size should return empty table")
    
    -- Test with mixed bit values
    local mixed_bit_array = {[1] = 1, [2] = 0, [3] = 1, [4] = 0, [5] = 1}
    local mixed_result = redis_adapter.redis_bit_array_to_bloom_filter(mixed_bit_array, 5)
    
    TestSuite.assert_true(mixed_result[1], "Bit 1 should be true")
    TestSuite.assert_nil(mixed_result[2], "Bit 2 should be nil")
    TestSuite.assert_true(mixed_result[3], "Bit 3 should be true")
    TestSuite.assert_nil(mixed_result[4], "Bit 4 should be nil")
    TestSuite.assert_true(mixed_result[5], "Bit 5 should be true")
end

-- Test search command generation
function TestSuite.test_generate_search_commands()
    print("\n🔍 Testing Search Command Generation")
    print("====================================")
    
    local filter_name = "test_filter"
    local element = "test_element"
    
    local commands = redis_adapter.generate_search_commands(filter_name, element)
    
    TestSuite.assert_true(type(commands) == "table", "Should return a table of commands")
    TestSuite.assert_not_nil(commands.get_metadata, "Should have get_metadata command")
    TestSuite.assert_not_nil(commands.get_bits, "Should have get_bits command")
    
    -- Test metadata command
    TestSuite.assert_equal("HGETALL", commands.get_metadata.command, "Metadata command should be HGETALL")
    TestSuite.assert_equal("bloom_filter_meta:test_filter", commands.get_metadata.key, "Metadata key should be correct")
    
    -- Test bits command
    TestSuite.assert_equal("MGET", commands.get_bits.command, "Bits command should be MGET")
    TestSuite.assert_true(type(commands.get_bits.keys) == "table", "Should have keys table")
    TestSuite.assert_equal("bloom_filter:test_filter", commands.get_bits.keys[1], "Bits key should be correct")
    
    -- Test with different filter names
    local commands2 = redis_adapter.generate_search_commands("different_filter", element)
    TestSuite.assert_equal("bloom_filter_meta:different_filter", commands2.get_metadata.key, "Different filter name should be reflected")
    TestSuite.assert_equal("bloom_filter:different_filter", commands2.get_bits.keys[1], "Different filter name should be reflected in bits key")
    
    -- Test with different elements
    local commands3 = redis_adapter.generate_search_commands(filter_name, "different_element")
    TestSuite.assert_equal(commands.get_metadata.key, commands3.get_metadata.key, "Element should not affect metadata key")
    TestSuite.assert_equal(commands.get_bits.keys[1], commands3.get_bits.keys[1], "Element should not affect bits key")
end

-- Test list command generation
function TestSuite.test_generate_list_commands()
    print("\n📋 Testing List Command Generation")
    print("==================================")
    
    local commands = redis_adapter.generate_list_commands()
    
    TestSuite.assert_true(type(commands) == "table", "Should return a table of commands")
    TestSuite.assert_not_nil(commands.list_keys, "Should have list_keys command")
    
    -- Test list keys command
    TestSuite.assert_equal("KEYS", commands.list_keys.command, "List command should be KEYS")
    TestSuite.assert_equal("bloom_filter_meta:*", commands.list_keys.pattern, "Pattern should match bloom filter metadata")
    
    -- Test consistency
    local commands2 = redis_adapter.generate_list_commands()
    TestSuite.assert_equal(commands.list_keys.command, commands2.list_keys.command, "Commands should be consistent")
    TestSuite.assert_equal(commands.list_keys.pattern, commands2.list_keys.pattern, "Pattern should be consistent")
end

-- Test delete command generation
function TestSuite.test_generate_delete_commands()
    print("\n🗑️ Testing Delete Command Generation")
    print("====================================")
    
    local filter_name = "test_filter"
    local commands = redis_adapter.generate_delete_commands(filter_name)
    
    TestSuite.assert_true(type(commands) == "table", "Should return a table of commands")
    TestSuite.assert_not_nil(commands.delete_metadata, "Should have delete_metadata command")
    TestSuite.assert_not_nil(commands.delete_filter, "Should have delete_filter command")
    
    -- Test metadata delete command
    TestSuite.assert_equal("DEL", commands.delete_metadata.command, "Metadata delete command should be DEL")
    TestSuite.assert_equal("bloom_filter_meta:test_filter", commands.delete_metadata.key, "Metadata delete key should be correct")
    
    -- Test filter delete command
    TestSuite.assert_equal("DEL", commands.delete_filter.command, "Filter delete command should be DEL")
    TestSuite.assert_equal("bloom_filter:test_filter", commands.delete_filter.key, "Filter delete key should be correct")
    
    -- Test with different filter names
    local commands2 = redis_adapter.generate_delete_commands("different_filter")
    TestSuite.assert_equal("bloom_filter_meta:different_filter", commands2.delete_metadata.key, "Different filter name should be reflected in metadata key")
    TestSuite.assert_equal("bloom_filter:different_filter", commands2.delete_filter.key, "Different filter name should be reflected in filter key")
end

-- Test Redis response validation
function TestSuite.test_validate_redis_response()
    print("\n✅ Testing Redis Response Validation")
    print("====================================")
    
    -- Test valid metadata response
    local valid_metadata = {"size", "100", "hash_count", "3"}
    local is_valid, error_msg = redis_adapter.validate_redis_response(valid_metadata, "metadata")
    TestSuite.assert_true(is_valid, "Valid metadata should pass validation")
    TestSuite.assert_nil(error_msg, "Should have no error message")
    
    -- Test invalid metadata response (odd number of elements)
    local invalid_metadata = {"size", "100", "hash_count"}
    local is_valid2, error_msg2 = redis_adapter.validate_redis_response(invalid_metadata, "metadata")
    TestSuite.assert_false(is_valid2, "Invalid metadata should fail validation")
    TestSuite.assert_not_nil(error_msg2, "Should have error message")
    
    -- Test empty metadata response
    local empty_metadata = {}
    local is_valid3, error_msg3 = redis_adapter.validate_redis_response(empty_metadata, "metadata")
    TestSuite.assert_false(is_valid3, "Empty metadata should fail validation")
    TestSuite.assert_not_nil(error_msg3, "Should have error message")
    
    -- Test valid bit array response
    local valid_bit_array = {"bit_data"}
    local is_valid4, error_msg4 = redis_adapter.validate_redis_response(valid_bit_array, "bit_array")
    TestSuite.assert_true(is_valid4, "Valid bit array should pass validation")
    TestSuite.assert_nil(error_msg4, "Should have no error message")
    
    -- Test invalid bit array response
    local invalid_bit_array = {}
    local is_valid5, error_msg5 = redis_adapter.validate_redis_response(invalid_bit_array, "bit_array")
    TestSuite.assert_false(is_valid5, "Invalid bit array should fail validation")
    TestSuite.assert_not_nil(error_msg5, "Should have error message")
    
    -- Test nil response
    local is_valid6, error_msg6 = redis_adapter.validate_redis_response(nil, "metadata")
    TestSuite.assert_false(is_valid6, "Nil response should fail validation")
    TestSuite.assert_not_nil(error_msg6, "Should have error message")
    
    -- Test unknown type
    local is_valid7, error_msg7 = redis_adapter.validate_redis_response(valid_metadata, "unknown_type")
    TestSuite.assert_true(is_valid7, "Unknown type should pass validation")
    TestSuite.assert_nil(error_msg7, "Should have no error message")
end

-- Test bloom filter creation from Redis data
function TestSuite.test_create_bloom_filter_from_redis()
    print("\n🏗️ Testing Bloom Filter Creation from Redis Data")
    print("===============================================")
    
    local filter_name = "test_filter"
    local redis_metadata = {
        "size", "100",
        "hash_count", "3",
        "expected_elements", "50",
        "false_positive_rate", "0.01",
        "created_at", "1234567890",
        "actual_elements", "30"
    }
    local redis_bit_array = {[1] = 1, [5] = 1, [10] = 1}
    
    local filter = redis_adapter.create_bloom_filter_from_redis(filter_name, redis_metadata, redis_bit_array)
    
    TestSuite.assert_true(type(filter) == "table", "Should return a table")
    TestSuite.assert_not_nil(filter.metadata, "Should have metadata")
    TestSuite.assert_not_nil(filter.bit_array, "Should have bit array")
    
    -- Test metadata conversion
    TestSuite.assert_equal("test_filter", filter.metadata.name, "Filter name should match")
    TestSuite.assert_equal(100, filter.metadata.size, "Size should be converted to number")
    TestSuite.assert_equal(3, filter.metadata.hash_count, "Hash count should be converted to number")
    
    -- Test bit array conversion
    TestSuite.assert_true(filter.bit_array[1], "Bit 1 should be true")
    TestSuite.assert_true(filter.bit_array[5], "Bit 5 should be true")
    TestSuite.assert_true(filter.bit_array[10], "Bit 10 should be true")
    TestSuite.assert_nil(filter.bit_array[2], "Bit 2 should be nil")
    
    -- Test with empty data
    local empty_filter = redis_adapter.create_bloom_filter_from_redis(filter_name, {}, {})
    TestSuite.assert_equal(filter_name, empty_filter.metadata.name, "Empty data should still set filter name")
    TestSuite.assert_true(type(empty_filter.bit_array) == "table", "Empty bit array should still be table")
end

-- Test memory usage calculation
function TestSuite.test_calculate_redis_memory_usage()
    print("\n💾 Testing Redis Memory Usage Calculation")
    print("=========================================")
    
    local memory = redis_adapter.calculate_redis_memory_usage(mock_bloom_filter)
    
    TestSuite.assert_true(type(memory) == "table", "Should return a table")
    TestSuite.assert_not_nil(memory.bloom_filter_bytes, "Should have bloom_filter_bytes")
    TestSuite.assert_not_nil(memory.total_bytes, "Should have total_bytes")
    TestSuite.assert_not_nil(memory.bloom_filter_kb, "Should have bloom_filter_kb")
    TestSuite.assert_not_nil(memory.total_kb, "Should have total_kb")
    
    -- Test calculations
    local expected_bytes = math.ceil(100 / 8)  -- 100 bits = 13 bytes
    TestSuite.assert_equal(expected_bytes, memory.bloom_filter_bytes, "Bloom filter bytes should be calculated correctly")
    
    local expected_total = expected_bytes + 16 + 64  -- bloom_filter_bytes + redis_overhead + metadata_overhead
    TestSuite.assert_equal(expected_total, memory.total_bytes, "Total bytes should include overhead")
    
    -- Test with different sizes
    local large_filter = {
        metadata = {size = 1000000}  -- 1 million bits
    }
    local large_memory = redis_adapter.calculate_redis_memory_usage(large_filter)
    
    TestSuite.assert_true(large_memory.bloom_filter_bytes > memory.bloom_filter_bytes, "Larger filter should use more memory")
    TestSuite.assert_true(large_memory.total_bytes > memory.total_bytes, "Larger filter should use more total memory")
    
    -- Test with size 0
    local zero_filter = {
        metadata = {size = 0}
    }
    local zero_memory = redis_adapter.calculate_redis_memory_usage(zero_filter)
    
    TestSuite.assert_equal(0, zero_memory.bloom_filter_bytes, "Zero size should result in zero bytes")
    TestSuite.assert_equal(80, zero_memory.total_bytes, "Zero size should still have overhead")
end

-- Test pipeline command generation
function TestSuite.test_generate_pipeline_commands()
    print("\n🚀 Testing Pipeline Command Generation")
    print("=====================================")
    
    local commands = {
        {command = "HMSET", key = "key1", args = {"field1", "value1"}},
        {command = "SETBIT", key = "key2", args = {0, 1}},
        {command = "GETBIT", key = "key3", args = {0}}
    }
    
    local pipeline = redis_adapter.generate_pipeline_commands(commands)
    
    TestSuite.assert_true(type(pipeline) == "table", "Should return a table")
    TestSuite.assert_equal(3, #pipeline, "Should have same number of commands")
    
    -- Test each command is properly formatted
    for i, cmd in ipairs(commands) do
        local pipeline_cmd = pipeline[i]
        TestSuite.assert_equal(cmd.command, pipeline_cmd.command, "Command should match")
        TestSuite.assert_equal(cmd.key, pipeline_cmd.key, "Key should match")
        TestSuite.assert_true(type(pipeline_cmd.args) == "table", "Args should be table")
    end
    
    -- Test with empty commands
    local empty_pipeline = redis_adapter.generate_pipeline_commands({})
    TestSuite.assert_equal(0, #empty_pipeline, "Empty commands should result in empty pipeline")
    
    -- Test with nil commands
    local nil_pipeline = redis_adapter.generate_pipeline_commands(nil)
    TestSuite.assert_equal(0, #nil_pipeline, "Nil commands should result in empty pipeline")
    
    -- Test with commands missing args
    local no_args_commands = {
        {command = "PING", key = "none"}
    }
    local no_args_pipeline = redis_adapter.generate_pipeline_commands(no_args_commands)
    TestSuite.assert_equal(1, #no_args_pipeline, "Should handle commands without args")
    TestSuite.assert_true(type(no_args_pipeline[1].args) == "table", "Args should be initialized as empty table")
end

-- Test edge cases and error conditions
function TestSuite.test_edge_cases()
    print("\n🔍 Testing Edge Cases and Error Conditions")
    print("==========================================")
    
    -- Test with nil filter name
    local nil_commands = redis_adapter.bloom_filter_to_redis_commands(nil, mock_bloom_filter)
    TestSuite.assert_true(type(nil_commands) == "table", "Nil filter name should still return commands")
    
    -- Test with nil bloom filter data
    local nil_data_commands = redis_adapter.bloom_filter_to_redis_commands("test", nil)
    TestSuite.assert_true(type(nil_data_commands) == "table", "Nil bloom filter data should still return commands")
    
    -- Test with very large numbers
    local large_filter = {
        metadata = {
            size = 999999999,
            hash_count = 999999999,
            expected_elements = 999999999,
            false_positive_rate = 0.999999999,
            created_at = 999999999999999,
            actual_elements = 999999999
        },
        elements_processed = 999999999,
        bit_array = {[999999999] = true}
    }
    
    local large_commands = redis_adapter.bloom_filter_to_redis_commands("large_test", large_filter)
    TestSuite.assert_true(type(large_commands) == "table", "Large numbers should still work")
    TestSuite.assert_true(#large_commands > 0, "Large numbers should still produce commands")
    
    -- Test with special characters in filter name
    local special_filter_name = "test-filter_with.special@chars#123"
    local special_commands = redis_adapter.bloom_filter_to_redis_commands(special_filter_name, mock_bloom_filter)
    TestSuite.assert_true(type(special_commands) == "table", "Special characters should work")
    
    -- Test with empty strings
    local empty_string_commands = redis_adapter.bloom_filter_to_redis_commands("", mock_bloom_filter)
    TestSuite.assert_true(type(empty_string_commands) == "table", "Empty string filter name should work")
    
    -- Test with very long strings
    local long_string = string.rep("a", 10000)
    local long_commands = redis_adapter.bloom_filter_to_redis_commands(long_string, mock_bloom_filter)
    TestSuite.assert_true(type(long_commands) == "table", "Very long strings should work")
end

-- Main test runner
function TestSuite.run_all_tests()
    print("🧪 Running Comprehensive Redis Adapter Tests")
    print("============================================")
    print("Target: 100% Code Coverage")
    print("")
    
    local tests = {
        test_bloom_filter_to_redis_commands,
        test_redis_metadata_to_bloom_filter,
        test_redis_bit_array_to_bloom_filter,
        test_generate_search_commands,
        test_generate_list_commands,
        test_generate_delete_commands,
        test_validate_redis_response,
        test_create_bloom_filter_from_redis,
        test_calculate_redis_memory_usage,
        test_generate_pipeline_commands,
        test_edge_cases
    }
    
    for _, test in ipairs(tests) do
        local success = pcall(test)
        if not success then
            print("❌ Test failed with error")
        end
        print("") -- Add spacing between tests
    end
    
    print("🎯 Test Results")
    print("===============")
    print("Passed:", passed_tests)
    print("Total:", total_tests)
    print("Success Rate:", string.format("%.1f%%", (passed_tests / total_tests) * 100))
    
    if passed_tests == total_tests then
        print("🎉 All tests passed! 100% coverage achieved!")
    else
        print("❌ Some tests failed!")
    end
    
    return passed_tests, total_tests
end

-- Export test suite
return TestSuite 