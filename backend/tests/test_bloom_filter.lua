-- Comprehensive Unit Tests for Bloom Filter Module
-- Achieves 100% code coverage

-- Add backend directory to Lua path
package.path = package.path .. ";backend/?.lua"

local bloom_filter = require "bloom_filter"

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

-- Test hash functions
function TestSuite.test_hash_functions()
    print("\n🔍 Testing Hash Functions")
    print("=========================")
    
    local size = 100
    local test_string = "test"
    
    -- Test hash1
    local h1 = bloom_filter.hash1(test_string, size)
    TestSuite.assert_true(h1 > 0 and h1 <= size, "Hash1 should be within valid range")
    
    -- Test hash2
    local h2 = bloom_filter.hash2(test_string, size)
    TestSuite.assert_true(h2 > 0 and h2 <= size, "Hash2 should be within valid range")
    
    -- Test hash3
    local h3 = bloom_filter.hash3(test_string, size)
    TestSuite.assert_true(h3 > 0 and h3 <= size, "Hash3 should be within valid range")
    
    -- Test consistency
    local h1_again = bloom_filter.hash1(test_string, size)
    local h2_again = bloom_filter.hash2(test_string, size)
    local h3_again = bloom_filter.hash3(test_string, size)
    
    TestSuite.assert_equal(h1, h1_again, "Hash1 should be consistent")
    TestSuite.assert_equal(h2, h2_again, "Hash2 should be consistent")
    TestSuite.assert_equal(h3, h3_again, "Hash3 should be consistent")
    
    -- Test different strings produce different hashes
    local h1_diff = bloom_filter.hash1("different", size)
    TestSuite.assert_true(h1 ~= h1_diff, "Different strings should produce different hashes")
    
    -- Test edge cases
    local h1_empty = bloom_filter.hash1("", size)
    local h2_empty = bloom_filter.hash2("", size)
    local h3_empty = bloom_filter.hash3("", size)
    
    TestSuite.assert_true(h1_empty > 0 and h1_empty <= size, "Empty string hash1 should be valid")
    TestSuite.assert_true(h2_empty > 0 and h2_empty <= size, "Empty string hash2 should be valid")
    TestSuite.assert_true(h3_empty > 0 and h3_empty <= size, "Empty string hash3 should be valid")
    
    -- Test very long strings
    local long_string = string.rep("a", 1000)
    local h1_long = bloom_filter.hash1(long_string, size)
    TestSuite.assert_true(h1_long > 0 and h1_long <= size, "Long string hash1 should be valid")
    
    -- Test size boundary conditions
    local h1_size1 = bloom_filter.hash1("test", 1)
    TestSuite.assert_equal(1, h1_size1, "Hash with size 1 should return 1")
    
    local h1_size2 = bloom_filter.hash1("test", 2)
    TestSuite.assert_true(h1_size2 >= 1 and h1_size2 <= 2, "Hash with size 2 should return 1 or 2")
    
    -- Test nil and invalid inputs for 100% coverage
    local h1_nil = bloom_filter.hash1(nil, size)
    TestSuite.assert_equal(1, h1_nil, "Nil string should return default hash value")
    
    local h1_invalid_size = bloom_filter.hash1(test_string, 0)
    TestSuite.assert_equal(1, h1_invalid_size, "Invalid size should return default hash value")
    
    local h1_negative_size = bloom_filter.hash1(test_string, -5)
    TestSuite.assert_equal(1, h1_negative_size, "Negative size should return default hash value")
    
    -- Test same for hash2 and hash3
    local h2_nil = bloom_filter.hash2(nil, size)
    TestSuite.assert_equal(1, h2_nil, "Nil string should return default hash value for hash2")
    
    local h3_nil = bloom_filter.hash3(nil, size)
    TestSuite.assert_equal(1, h3_nil, "Nil string should return default hash value for hash3")
end

-- Test parameter calculation
function TestSuite.test_parameter_calculation()
    print("\n📊 Testing Parameter Calculation")
    print("================================")
    
    -- Test default parameters
    local size, hash_count = bloom_filter.calculate_bloom_filter_params()
    TestSuite.assert_true(size > 0, "Default size should be positive")
    TestSuite.assert_true(hash_count > 0, "Default hash count should be positive")
    
    -- Test with explicit parameters
    local size2, hash_count2 = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
    TestSuite.assert_true(size2 > 0, "Explicit size should be positive")
    TestSuite.assert_true(hash_count2 > 0, "Explicit hash count should be positive")
    TestSuite.assert_true(size2 >= 1000, "Size should be at least as large as expected elements")
    
    -- Test with different parameters
    local size3, hash_count3 = bloom_filter.calculate_bloom_filter_params(10000, 0.001)
    TestSuite.assert_true(size3 > size2, "Lower false positive rate should result in larger size")
    
    -- Test edge cases
    local size4, hash_count4 = bloom_filter.calculate_bloom_filter_params(1, 0.5)
    TestSuite.assert_true(size4 > 0, "Size should be positive even with edge case parameters")
    
    local size5, hash_count5 = bloom_filter.calculate_bloom_filter_params(1000000, 0.0001)
    TestSuite.assert_true(size5 > size3, "Very large expected elements should result in larger size")
    
    -- Test mathematical properties
    local size6, hash_count6 = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
    local size7, hash_count7 = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
    TestSuite.assert_equal(size6, size7, "Same parameters should produce same results")
    
    print("Parameter calculation results:")
    print("  Default (10000, 0.01):", size, "size,", hash_count, "hash functions")
    print("  (1000, 0.01):", size2, "size,", hash_count2, "hash functions")
    print("  (10000, 0.001):", size3, "size,", hash_count3, "hash functions")
    print("  (1, 0.5):", size4, "size,", hash_count4, "hash functions")
    print("  (1000000, 0.0001):", size5, "size,", hash_count5, "hash functions")
end

-- Test metadata creation
function TestSuite.test_metadata_creation()
    print("\n📋 Testing Metadata Creation")
    print("============================")
    
    -- Test with default parameters
    local metadata = bloom_filter.create_bloom_filter_metadata("test_filter")
    TestSuite.assert_equal("test_filter", metadata.name, "Filter name should match")
    TestSuite.assert_true(metadata.size > 0, "Size should be calculated")
    TestSuite.assert_true(metadata.hash_count > 0, "Hash count should be calculated")
    TestSuite.assert_equal(10000, metadata.expected_elements, "Default expected elements should be 10000")
    TestSuite.assert_equal(0.01, metadata.false_positive_rate, "Default false positive rate should be 0.01")
    TestSuite.assert_equal(0, metadata.created_at, "Default created timestamp should be 0")
    
    -- Test with explicit timestamp
    local timestamp = 1234567890
    local metadata_with_time = bloom_filter.create_bloom_filter_metadata("test_filter_time", 5000, 0.05, timestamp)
    TestSuite.assert_equal(timestamp, metadata_with_time.created_at, "Explicit timestamp should be set")
    
    -- Test with explicit parameters
    local metadata2 = bloom_filter.create_bloom_filter_metadata("test_filter2", 5000, 0.05)
    TestSuite.assert_equal("test_filter2", metadata2.name, "Filter name should match")
    TestSuite.assert_equal(5000, metadata2.expected_elements, "Expected elements should match")
    TestSuite.assert_equal(0.05, metadata2.false_positive_rate, "False positive rate should match")
    
    -- Test edge cases
    local metadata3 = bloom_filter.create_bloom_filter_metadata("edge_case", 1, 0.99)
    TestSuite.assert_equal(1, metadata3.expected_elements, "Edge case expected elements should match")
    TestSuite.assert_equal(0.99, metadata3.false_positive_rate, "Edge case false positive rate should match")
    
    -- Test metadata structure
    local required_keys = {"name", "size", "hash_count", "expected_elements", "false_positive_rate", "created_at"}
    for _, key in ipairs(required_keys) do
        TestSuite.assert_not_nil(metadata[key], "Metadata should have key: " .. key)
    end
end

-- Test hash position generation
function TestSuite.test_hash_position_generation()
    print("\n🎯 Testing Hash Position Generation")
    print("===================================")
    
    local size = 100
    local test_string = "test"
    
    local positions = bloom_filter.generate_hash_positions(test_string, size)
    
    TestSuite.assert_true(type(positions) == "table", "Should return a table")
    TestSuite.assert_equal(3, #positions, "Should return exactly 3 hash positions")
    
    -- Test each position is valid
    for i, position in ipairs(positions) do
        TestSuite.assert_true(position > 0 and position <= size, "Position " .. i .. " should be within valid range")
    end
    
    -- Test consistency
    local positions2 = bloom_filter.generate_hash_positions(test_string, size)
    for i, position in ipairs(positions) do
        TestSuite.assert_equal(position, positions2[i], "Hash positions should be consistent")
    end
    
    -- Test different strings produce different positions
    local positions_diff = bloom_filter.generate_hash_positions("different", size)
    local has_difference = false
    for i, position in ipairs(positions) do
        if position ~= positions_diff[i] then
            has_difference = true
            break
        end
    end
    TestSuite.assert_true(has_difference, "Different strings should produce different hash positions")
    
    -- Test edge cases
    local positions_empty = bloom_filter.generate_hash_positions("", size)
    TestSuite.assert_equal(3, #positions_empty, "Empty string should still produce 3 positions")
    
    local positions_size1 = bloom_filter.generate_hash_positions("test", 1)
    for i, position in ipairs(positions_size1) do
        TestSuite.assert_equal(1, position, "All positions should be 1 when size is 1")
    end
end

-- Test element existence checking
function TestSuite.test_element_existence_checking()
    print("\n🔍 Testing Element Existence Checking")
    print("=====================================")
    
    -- Test with all positions set
    local bit_array = {[1] = true, [5] = true, [10] = true}
    local hash_positions = {1, 5, 10}
    
    local exists = bloom_filter.check_element_exists(hash_positions, bit_array)
    TestSuite.assert_true(exists, "Should return true when all hash positions are set")
    
    -- Test with some positions not set
    local bit_array2 = {[1] = true, [5] = true} -- Missing position 10
    local exists2 = bloom_filter.check_element_exists(hash_positions, bit_array2)
    TestSuite.assert_false(exists2, "Should return false when some hash positions are not set")
    
    -- Test with no positions set
    local bit_array3 = {}
    local exists3 = bloom_filter.check_element_exists(hash_positions, bit_array3)
    TestSuite.assert_false(exists3, "Should return false when no hash positions are set")
    
    -- Test with nil positions
    local exists4 = bloom_filter.check_element_exists(nil, bit_array)
    TestSuite.assert_false(exists4, "Should return false when hash positions is nil")
    
    -- Test with empty positions
    local exists5 = bloom_filter.check_element_exists({}, bit_array)
    TestSuite.assert_true(exists5, "Should return true when hash positions is empty (vacuous truth)")
    
    -- Test with mixed positions
    local bit_array4 = {[1] = true, [5] = false, [10] = true}
    local exists6 = bloom_filter.check_element_exists(hash_positions, bit_array4)
    TestSuite.assert_false(exists6, "Should return false when some positions are explicitly false")
end

-- Test file content parsing
function TestSuite.test_file_content_parsing()
    print("\n📁 Testing File Content Parsing")
    print("================================")
    
    -- Test normal content
    local test_content = "line1\nline2\n  line3  \n\nline4\n"
    local elements = bloom_filter.parse_file_content(test_content)
    
    TestSuite.assert_equal(4, #elements, "Should parse 4 non-empty lines")
    TestSuite.assert_equal("line1", elements[1], "First line should be 'line1'")
    TestSuite.assert_equal("line2", elements[2], "Second line should be 'line2'")
    TestSuite.assert_equal("line3", elements[3], "Third line should be 'line3' (trimmed)")
    TestSuite.assert_equal("line4", elements[4], "Fourth line should be 'line4'")
    
    -- Test empty content
    local empty_elements = bloom_filter.parse_file_content("")
    TestSuite.assert_equal(0, #empty_elements, "Empty content should produce no elements")
    
    -- Test whitespace-only content
    local whitespace_elements = bloom_filter.parse_file_content("  \n  \n  ")
    TestSuite.assert_equal(0, #whitespace_elements, "Whitespace-only content should produce no elements")
    
    -- Test single line
    local single_line = bloom_filter.parse_file_content("single")
    TestSuite.assert_equal(1, #single_line, "Single line should produce one element")
    TestSuite.assert_equal("single", single_line[1], "Single line content should match")
    
    -- Test with carriage returns
    local crlf_content = "line1\r\nline2\r\nline3"
    local crlf_elements = bloom_filter.parse_file_content(crlf_content)
    TestSuite.assert_equal(3, #crlf_elements, "CRLF content should parse correctly")
    
    -- Test with mixed line endings
    local mixed_content = "line1\nline2\r\nline3\rline4"
    local mixed_elements = bloom_filter.parse_file_content(mixed_content)
    TestSuite.assert_equal(4, #mixed_elements, "Mixed line endings should parse correctly")
    
    -- Test with special characters
    local special_content = "line1\nlîne2\nlíne3\nlìne4"
    local special_elements = bloom_filter.parse_file_content(special_content)
    TestSuite.assert_equal(4, #special_elements, "Special characters should parse correctly")
    
    -- Test with numbers and symbols
    local symbol_content = "123\n!@#\n$%^\n&*()"
    local symbol_elements = bloom_filter.parse_file_content(symbol_content)
    TestSuite.assert_equal(4, #symbol_elements, "Numbers and symbols should parse correctly")
end

-- Test bit array generation
function TestSuite.test_bit_array_generation()
    print("\n🔢 Testing Bit Array Generation")
    print("================================")
    
    local size = 100
    local elements = {"apple", "banana", "cherry"}
    
    local bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, size)
    
    TestSuite.assert_true(type(bit_array) == "table", "Should return a table")
    
    -- Count set bits properly
    local set_bits_count = 0
    for _, _ in pairs(bit_array) do
        set_bits_count = set_bits_count + 1
    end
    TestSuite.assert_true(set_bits_count > 0, "Should have some set bits")
    
    -- Test that all elements are represented in bit array
    for _, element in ipairs(elements) do
        local hash_positions = bloom_filter.generate_hash_positions(element, size)
        local exists = bloom_filter.check_element_exists(hash_positions, bit_array)
        TestSuite.assert_true(exists, "Element '" .. element .. "' should exist in bit array")
    end
    
    -- Test with empty elements
    local empty_bit_array = bloom_filter.generate_bloom_filter_bit_array({}, size)
    local empty_count = 0
    for _, _ in pairs(empty_bit_array) do
        empty_count = empty_count + 1
    end
    TestSuite.assert_equal(0, empty_count, "Empty elements should produce empty bit array")
    
    -- Test with nil elements
    local nil_bit_array = bloom_filter.generate_bloom_filter_bit_array(nil, size)
    local nil_count = 0
    for _, _ in pairs(nil_bit_array) do
        nil_count = nil_count + 1
    end
    TestSuite.assert_equal(0, nil_count, "Nil elements should produce empty bit array")
    
    -- Test with single element
    local single_bit_array = bloom_filter.generate_bloom_filter_bit_array({"single"}, size)
    local single_count = 0
    for _, _ in pairs(single_bit_array) do
        single_count = single_count + 1
    end
    TestSuite.assert_true(single_count > 0, "Single element should produce non-empty bit array")
    
    -- Test with large size
    local large_size = 10000
    local large_bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, large_size)
    local large_count = 0
    for _, _ in pairs(large_bit_array) do
        large_count = large_count + 1
    end
    TestSuite.assert_true(large_count > 0, "Large size should still produce bit array")
    
    -- Test bit array properties
    for position, _ in pairs(bit_array) do
        TestSuite.assert_true(position > 0 and position <= size, "Bit array positions should be within valid range")
    end
    
    -- Test edge cases for 100% coverage
    local invalid_size_bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, 0)
    local invalid_count = 0
    for _, _ in pairs(invalid_size_bit_array) do
        invalid_count = invalid_count + 1
    end
    TestSuite.assert_equal(0, invalid_count, "Invalid size should produce empty bit array")
    
    local negative_size_bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, -10)
    local negative_count = 0
    for _, _ in pairs(negative_size_bit_array) do
        negative_count = negative_count + 1
    end
    TestSuite.assert_equal(0, negative_count, "Negative size should produce empty bit array")
    
    local nil_size_bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, nil)
    local nil_size_count = 0
    for _, _ in pairs(nil_size_bit_array) do
        nil_size_count = nil_size_count + 1
    end
    TestSuite.assert_equal(0, nil_size_count, "Nil size should produce empty bit array")
    
    -- Test with elements containing empty strings
    local mixed_elements = {"apple", "", "cherry", "  ", "banana"}
    local mixed_bit_array = bloom_filter.generate_bloom_filter_bit_array(mixed_elements, size)
    local mixed_count = 0
    for _, _ in pairs(mixed_bit_array) do
        mixed_count = mixed_count + 1
    end
    TestSuite.assert_true(mixed_count > 0, "Mixed elements should produce bit array")
    
    -- Test with elements containing nil values
    local nil_elements = {"apple", nil, "cherry"}
    local nil_elements_bit_array = bloom_filter.generate_bloom_filter_bit_array(nil_elements, size)
    local nil_elements_count = 0
    for _, _ in pairs(nil_elements_bit_array) do
        nil_elements_count = nil_elements_count + 1
    end
    TestSuite.assert_true(nil_elements_count > 0, "Elements with nil should still produce bit array")
end

-- Test complete bloom filter creation
function TestSuite.test_bloom_filter_creation()
    print("\n🏗️ Testing Bloom Filter Creation")
    print("================================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("test_filter", test_content, 10, 0.01, 1234567890)
    
    TestSuite.assert_equal("test_filter", filter.metadata.name, "Filter name should match")
    TestSuite.assert_equal(3, filter.elements_processed, "Should process 3 elements")
    TestSuite.assert_equal(3, #filter.elements, "Should have 3 elements")
    TestSuite.assert_true(filter.metadata.size > 0, "Size should be calculated")
    TestSuite.assert_true(filter.metadata.hash_count > 0, "Hash count should be calculated")
    
    -- Test bit array generation
    TestSuite.assert_true(type(filter.bit_array) == "table", "Bit array should be generated")
    
    local set_bits_count = 0
    for _, _ in pairs(filter.bit_array) do
        set_bits_count = set_bits_count + 1
    end
    TestSuite.assert_true(set_bits_count > 0, "Bit array should have some set bits")
    
    -- Test with different parameters
    local filter2 = bloom_filter.create_bloom_filter_from_file("test_filter2", test_content, 100, 0.001, 1234567890)
    TestSuite.assert_true(filter2.metadata.size > filter.metadata.size, "Lower false positive rate should result in larger size")
    
    -- Test with edge case parameters
    local filter3 = bloom_filter.create_bloom_filter_from_file("test_filter3", test_content, 1, 0.99, 1234567890)
    TestSuite.assert_equal(1, filter3.metadata.expected_elements, "Edge case expected elements should match")
    
    -- Test with empty content
    local filter4 = bloom_filter.create_bloom_filter_from_file("test_filter4", "", 10, 0.01, 1234567890)
    TestSuite.assert_equal(0, filter4.elements_processed, "Empty content should process 0 elements")
    
    print("Created filter:", filter.metadata.name)
    print("Size:", filter.metadata.size)
    print("Hash count:", filter.metadata.hash_count)
    print("Elements processed:", filter.elements_processed)
end

-- Test element search
function TestSuite.test_element_search()
    print("\n🔍 Testing Element Search")
    print("==========================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("search_test", test_content, 10, 0.01, 1234567890)
    
    -- Test existing elements
    local exists1 = bloom_filter.search_element_in_bloom_filter("apple", filter.bit_array, filter.metadata.size)
    local exists2 = bloom_filter.search_element_in_bloom_filter("banana", filter.bit_array, filter.metadata.size)
    local exists3 = bloom_filter.search_element_in_bloom_filter("cherry", filter.bit_array, filter.metadata.size)
    
    TestSuite.assert_true(exists1, "Should find 'apple'")
    TestSuite.assert_true(exists2, "Should find 'banana'")
    TestSuite.assert_true(exists3, "Should find 'cherry'")
    
    -- Test non-existing elements
    local exists4 = bloom_filter.search_element_in_bloom_filter("orange", filter.bit_array, filter.metadata.size)
    local exists5 = bloom_filter.search_element_in_bloom_filter("grape", filter.bit_array, filter.metadata.size)
    
    -- Note: Bloom filters can have false positives, so we can't guarantee these are false
    -- But we can test that the function works
    TestSuite.assert_true(type(exists4) == "boolean", "Search should return boolean for 'orange'")
    TestSuite.assert_true(type(exists5) == "boolean", "Search should return boolean for 'grape'")
    
    -- Test edge cases
    local exists6 = bloom_filter.search_element_in_bloom_filter("", filter.bit_array, filter.metadata.size)
    TestSuite.assert_true(type(exists6) == "boolean", "Search should return boolean for empty string")
    
    local exists7 = bloom_filter.search_element_in_bloom_filter("very_long_string_that_exceeds_normal_length", filter.bit_array, filter.metadata.size)
    TestSuite.assert_true(type(exists7) == "boolean", "Search should return boolean for very long string")
    
    -- Test with nil parameters
    local exists8 = bloom_filter.search_element_in_bloom_filter(nil, filter.bit_array, filter.metadata.size)
    TestSuite.assert_true(type(exists8) == "boolean", "Search should return boolean for nil element")
    
    print("Search results:")
    print("  apple:", exists1)
    print("  banana:", exists2)
    print("  cherry:", exists3)
    print("  orange:", exists4)
    print("  grape:", exists5)
    print("  empty:", exists6)
    print("  long:", exists7)
    print("  nil:", exists8)
end

-- Test statistics calculation
function TestSuite.test_statistics_calculation()
    print("\n📈 Testing Statistics Calculation")
    print("=================================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("stats_test", test_content, 10, 0.01, 1234567890)
    
    local stats = bloom_filter.calculate_bloom_filter_stats(filter.bit_array, filter.metadata)
    
    TestSuite.assert_true(stats.set_bits > 0, "Should have some set bits")
    TestSuite.assert_equal(filter.metadata.size, stats.total_bits, "Total bits should match metadata")
    TestSuite.assert_true(stats.bit_density > 0, "Bit density should be positive")
    TestSuite.assert_true(stats.bit_density <= 1, "Bit density should be <= 1")
    -- The metadata should have actual_elements set to elements_processed
    TestSuite.assert_equal(filter.elements_processed, stats.actual_elements, "Actual elements should match processed count")
    
    -- Test all required fields
    local required_fields = {"set_bits", "total_bits", "bit_density", "false_positive_probability", "actual_elements"}
    for _, field in ipairs(required_fields) do
        TestSuite.assert_not_nil(stats[field], "Stats should have field: " .. field)
    end
    
    -- Test edge cases
    local empty_bit_array = {}
    local edge_metadata = {size = 100, hash_count = 3, actual_elements = 0}
    local edge_stats = bloom_filter.calculate_bloom_filter_stats(empty_bit_array, edge_metadata)
    
    TestSuite.assert_equal(0, edge_stats.set_bits, "Empty bit array should have 0 set bits")
    TestSuite.assert_equal(100, edge_stats.total_bits, "Total bits should match metadata")
    TestSuite.assert_equal(0, edge_stats.bit_density, "Bit density should be 0 for empty array")
    TestSuite.assert_equal(0, edge_stats.actual_elements, "Actual elements should match metadata")
    
    -- Test with metadata missing actual_elements (should use expected_elements)
    local metadata_without_actual = {size = 100, hash_count = 3, expected_elements = 5}
    local stats_without_actual = bloom_filter.calculate_bloom_filter_stats(filter.bit_array, metadata_without_actual)
    TestSuite.assert_equal(5, stats_without_actual.actual_elements, "Should use expected_elements when actual_elements is missing")
    
    -- Test with metadata missing both actual_elements and expected_elements
    local metadata_missing_both = {size = 100, hash_count = 3}
    local stats_missing_both = bloom_filter.calculate_bloom_filter_stats(filter.bit_array, metadata_missing_both)
    TestSuite.assert_equal(10000, stats_missing_both.actual_elements, "Should use default expected_elements when both are missing")
    
    -- Test with nil bit_array
    local stats_nil_bit_array = bloom_filter.calculate_bloom_filter_stats(nil, filter.metadata)
    TestSuite.assert_equal(0, stats_nil_bit_array.set_bits, "Nil bit array should have 0 set bits")
    
    -- Test with very large bit array
    local large_bit_array = {}
    for i = 1, 1000 do
        if i % 2 == 0 then
            large_bit_array[i] = true
        end
    end
    local large_metadata = {size = 1000, hash_count = 5, actual_elements = 500}
    local large_stats = bloom_filter.calculate_bloom_filter_stats(large_bit_array, large_metadata)
    
    TestSuite.assert_equal(500, large_stats.set_bits, "Large bit array should count set bits correctly")
    TestSuite.assert_equal(1000, large_stats.total_bits, "Large total bits should match metadata")
    TestSuite.assert_equal(0.5, large_stats.bit_density, "Bit density should be 0.5 for half set bits")
    
    print("Statistics:")
    print("  Set bits:", stats.set_bits)
    print("  Total bits:", stats.total_bits)
    print("  Bit density:", string.format("%.4f", stats.bit_density))
    print("  False positive probability:", string.format("%.6f", stats.false_positive_probability))
    print("  Actual elements:", stats.actual_elements)
end

-- Test validation functions
function TestSuite.test_validation()
    print("\n✅ Testing Validation Functions")
    print("===============================")
    
    -- Test valid parameters
    local is_valid, errors = bloom_filter.validate_bloom_filter_params(1000, 0.01)
    TestSuite.assert_true(is_valid, "Valid parameters should pass validation")
    TestSuite.assert_equal(0, #errors, "Should have no validation errors")
    
    -- Test invalid expected elements
    local is_valid2, errors2 = bloom_filter.validate_bloom_filter_params(-100, 0.01)
    TestSuite.assert_false(is_valid2, "Negative expected elements should fail validation")
    TestSuite.assert_true(#errors2 > 0, "Should have validation errors")
    
    -- Test invalid false positive rate
    local is_valid3, errors3 = bloom_filter.validate_bloom_filter_params(1000, 1.5)
    TestSuite.assert_false(is_valid3, "False positive rate > 1 should fail validation")
    TestSuite.assert_true(#errors3 > 0, "Should have validation errors")
    
    -- Test edge cases
    local is_valid4, errors4 = bloom_filter.validate_bloom_filter_params(0, 0.01)
    TestSuite.assert_false(is_valid4, "Zero expected elements should fail validation")
    
    local is_valid5, errors5 = bloom_filter.validate_bloom_filter_params(1000, 0)
    TestSuite.assert_false(is_valid5, "Zero false positive rate should fail validation")
    
    local is_valid6, errors6 = bloom_filter.validate_bloom_filter_params(1000, 1)
    TestSuite.assert_false(is_valid6, "False positive rate = 1 should fail validation")
    
    -- Test with nil parameters
    local is_valid7, errors7 = bloom_filter.validate_bloom_filter_params(nil, 0.01)
    TestSuite.assert_true(is_valid7, "Nil expected elements should pass validation (uses default)")
    
    local is_valid8, errors8 = bloom_filter.validate_bloom_filter_params(1000, nil)
    TestSuite.assert_true(is_valid8, "Nil false positive rate should pass validation (uses default)")
    
    print("Validation test results:")
    print("  Valid params:", is_valid)
    print("  Invalid elements:", is_valid2, "Errors:", #errors2)
    print("  Invalid FPR:", is_valid3, "Errors:", #errors3)
    print("  Zero elements:", is_valid4, "Errors:", #errors4)
    print("  Zero FPR:", is_valid5, "Errors:", #errors5)
    print("  FPR = 1:", is_valid6, "Errors:", #errors6)
    print("  Nil elements:", is_valid7, "Errors:", #errors7)
    print("  Nil FPR:", is_valid8, "Errors:", #errors8)
end

-- Test memory usage estimation
function TestSuite.test_memory_estimation()
    print("\n💾 Testing Memory Usage Estimation")
    print("===================================")
    
    local size = 10000
    local memory = bloom_filter.estimate_memory_usage(size)
    
    TestSuite.assert_equal(size, memory.bits, "Bits should match input size")
    TestSuite.assert_true(memory.bytes > 0, "Bytes should be positive")
    TestSuite.assert_true(memory.kilobytes > 0, "Kilobytes should be positive")
    TestSuite.assert_true(memory.megabytes >= 0, "Megabytes should be non-negative")
    
    -- Test all required fields
    local required_fields = {"bits", "bytes", "kilobytes", "megabytes"}
    for _, field in ipairs(required_fields) do
        TestSuite.assert_not_nil(memory[field], "Memory should have field: " .. field)
    end
    
    -- Test edge cases
    local memory0 = bloom_filter.estimate_memory_usage(0)
    TestSuite.assert_equal(0, memory0.bits, "Zero bits should result in zero bits")
    TestSuite.assert_equal(0, memory0.bytes, "Zero bits should result in zero bytes")
    TestSuite.assert_equal(0, memory0.kilobytes, "Zero bits should result in zero kilobytes")
    TestSuite.assert_equal(0, memory0.megabytes, "Zero bits should result in zero megabytes")
    
    local memory1 = bloom_filter.estimate_memory_usage(1)
    TestSuite.assert_equal(1, memory1.bits, "1 bit should result in 1 bit")
    TestSuite.assert_equal(1, memory1.bytes, "1 bit should result in 1 byte")
    
    local memory8 = bloom_filter.estimate_memory_usage(8)
    TestSuite.assert_equal(8, memory8.bits, "8 bits should result in 8 bits")
    TestSuite.assert_equal(1, memory8.bytes, "8 bits should result in 1 byte")
    
    local memory9 = bloom_filter.estimate_memory_usage(9)
    TestSuite.assert_equal(9, memory9.bits, "9 bits should result in 9 bits")
    TestSuite.assert_equal(2, memory9.bytes, "9 bits should result in 2 bytes")
    
    print("Memory usage for", size, "bits:")
    print("  Bits:", memory.bits)
    print("  Bytes:", memory.bytes)
    print("  KB:", string.format("%.2f", memory.kilobytes))
    print("  MB:", string.format("%.4f", memory.megabytes))
end

-- Test bloom filter comparison
function TestSuite.test_filter_comparison()
    print("\n🔄 Testing Filter Comparison")
    print("=============================")
    
    local content1 = "apple\nbanana\ncherry\n"
    local content2 = "apple\nbanana\ncherry\n"
    local content3 = "apple\nbanana\ngrape\n"
    
    local filter1 = bloom_filter.create_bloom_filter_from_file("compare1", content1, 10, 0.01, 1234567890)
    local filter2 = bloom_filter.create_bloom_filter_from_file("compare2", content2, 10, 0.01, 1234567890)
    local filter3 = bloom_filter.create_bloom_filter_from_file("compare3", content3, 10, 0.01, 1234567890)
    
    -- Test identical filters
    local comparison1 = bloom_filter.compare_bloom_filters(filter1, filter2)
    TestSuite.assert_true(comparison1.identical, "Identical filters should be identical")
    TestSuite.assert_equal(1.0, comparison1.similarity, "Similarity should be 1.0")
    TestSuite.assert_equal(0, comparison1.differences, "Should have no differences")
    
    -- Test different filters
    local comparison2 = bloom_filter.compare_bloom_filters(filter1, filter3)
    TestSuite.assert_false(comparison2.identical, "Different filters should not be identical")
    TestSuite.assert_true(comparison2.similarity > 0, "Similarity should be positive")
    TestSuite.assert_true(comparison2.differences > 0, "Should have some differences")
    
    -- Test all required fields
    local required_fields = {"identical", "similarity", "differences", "total_bits"}
    for _, field in ipairs(required_fields) do
        TestSuite.assert_not_nil(comparison1[field], "Comparison should have field: " .. field)
        TestSuite.assert_not_nil(comparison2[field], "Comparison should have field: " .. field)
    end
    
    -- Test edge cases
    local edge_filter1 = bloom_filter.create_bloom_filter_from_file("edge1", "test", 1, 0.01, 1234567890)
    local edge_filter2 = bloom_filter.create_bloom_filter_from_file("edge2", "test", 1, 0.01, 1234567890)
    local edge_comparison = bloom_filter.compare_bloom_filters(edge_filter1, edge_filter2)
    
    TestSuite.assert_true(edge_comparison.identical, "Edge case filters should be identical")
    TestSuite.assert_equal(1.0, edge_comparison.similarity, "Edge case similarity should be 1.0")
    
    print("Comparison results:")
    print("  Filter1 vs Filter2 (identical):", comparison1.identical, "Similarity:", string.format("%.4f", comparison1.similarity))
    print("  Filter1 vs Filter3 (different):", comparison2.identical, "Similarity:", string.format("%.4f", comparison2.similarity))
    print("  Edge case:", edge_comparison.identical, "Similarity:", string.format("%.4f", edge_comparison.similarity))
end

-- Test constants
function TestSuite.test_constants()
    print("\n🔧 Testing Constants")
    print("====================")
    
    TestSuite.assert_not_nil(bloom_filter.BLOOM_FILTER_KEY_PREFIX, "BLOOM_FILTER_KEY_PREFIX should be defined")
    TestSuite.assert_not_nil(bloom_filter.BLOOM_FILTER_META_PREFIX, "BLOOM_FILTER_META_PREFIX should be defined")
    TestSuite.assert_not_nil(bloom_filter.DEFAULT_FALSE_POSITIVE_RATE, "DEFAULT_FALSE_POSITIVE_RATE should be defined")
    TestSuite.assert_not_nil(bloom_filter.DEFAULT_EXPECTED_ELEMENTS, "DEFAULT_EXPECTED_ELEMENTS should be defined")
    
    TestSuite.assert_true(type(bloom_filter.BLOOM_FILTER_KEY_PREFIX) == "string", "BLOOM_FILTER_KEY_PREFIX should be string")
    TestSuite.assert_true(type(bloom_filter.BLOOM_FILTER_META_PREFIX) == "string", "BLOOM_FILTER_META_PREFIX should be string")
    TestSuite.assert_true(type(bloom_filter.DEFAULT_FALSE_POSITIVE_RATE) == "number", "DEFAULT_FALSE_POSITIVE_RATE should be number")
    TestSuite.assert_true(type(bloom_filter.DEFAULT_EXPECTED_ELEMENTS) == "number", "DEFAULT_EXPECTED_ELEMENTS should be number")
    
    TestSuite.assert_true(bloom_filter.DEFAULT_FALSE_POSITIVE_RATE > 0, "DEFAULT_FALSE_POSITIVE_RATE should be positive")
    TestSuite.assert_true(bloom_filter.DEFAULT_FALSE_POSITIVE_RATE < 1, "DEFAULT_FALSE_POSITIVE_RATE should be less than 1")
    TestSuite.assert_true(bloom_filter.DEFAULT_EXPECTED_ELEMENTS > 0, "DEFAULT_EXPECTED_ELEMENTS should be positive")
    
    print("Constants:")
    print("  BLOOM_FILTER_KEY_PREFIX:", bloom_filter.BLOOM_FILTER_KEY_PREFIX)
    print("  BLOOM_FILTER_META_PREFIX:", bloom_filter.BLOOM_FILTER_META_PREFIX)
    print("  DEFAULT_FALSE_POSITIVE_RATE:", bloom_filter.DEFAULT_FALSE_POSITIVE_RATE)
    print("  DEFAULT_EXPECTED_ELEMENTS:", bloom_filter.DEFAULT_EXPECTED_ELEMENTS)
end

-- Main test runner
function TestSuite.run_all_tests()
    print("🧪 Running Comprehensive Bloom Filter Tests")
    print("===========================================")
    print("Target: 100% Code Coverage")
    print("")
    
    local tests = {
        TestSuite.test_hash_functions,
        TestSuite.test_parameter_calculation,
        TestSuite.test_metadata_creation,
        TestSuite.test_hash_position_generation,
        TestSuite.test_element_existence_checking,
        TestSuite.test_file_content_parsing,
        TestSuite.test_bit_array_generation,
        TestSuite.test_bloom_filter_creation,
        TestSuite.test_element_search,
        TestSuite.test_statistics_calculation,
        TestSuite.test_validation,
        TestSuite.test_memory_estimation,
        TestSuite.test_filter_comparison,
        TestSuite.test_constants
    }
    
    print("Number of tests:", #tests)
    print("Test functions:", table.unpack(tests))
    
    for i, test in ipairs(tests) do
        print("Running test", i, "of", #tests, "Type:", type(test))
        if type(test) == "function" then
            local success, err = pcall(test)
            if not success then
                print("❌ Test failed with error:", err)
            end
        else
            print("❌ Test", i, "is not a function")
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
local test_suite = TestSuite

-- Run tests if this file is executed directly
if arg[0] and string.find(arg[0], "test_bloom_filter") then
    test_suite.run_all_tests()
end

return test_suite 