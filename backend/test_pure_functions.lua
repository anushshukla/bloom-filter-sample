-- Test Pure Functions for Bloom Filter
-- This file demonstrates testing pure functions without external dependencies

-- Add backend directory to Lua path
package.path = package.path .. ";backend/?.lua"
local bloom_filter = require "bloom_filter"

-- Test utility functions
local function assert_equal(expected, actual, message)
    if expected ~= actual then
        print("❌ FAIL: " .. (message or "Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
        return false
    else
        print("✅ PASS: " .. (message or "Expected " .. tostring(expected) .. " and got " .. tostring(actual)))
        return true
    end
end

local function assert_true(condition, message)
    if not condition then
        print("❌ FAIL: " .. (message or "Expected true but got false"))
        return false
    else
        print("✅ PASS: " .. (message or "Expected true and got true"))
        return true
    end
end

local function assert_false(condition, message)
    if condition then
        print("❌ FAIL: " .. (message or "Expected false but got true"))
        return false
    else
        print("✅ PASS: " .. (message or "Expected false and got false"))
        return true
    end
end

local function assert_table_equals(expected, actual, message)
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
    return true
end

-- Test hash functions
local function test_hash_functions()
    print("\n🔍 Testing Hash Functions")
    print("=========================")
    
    local size = 100
    local test_string = "test"
    
    local h1 = bloom_filter.hash1(test_string, size)
    local h2 = bloom_filter.hash2(test_string, size)
    local h3 = bloom_filter.hash3(test_string, size)
    
    assert_true(h1 > 0 and h1 <= size, "Hash1 should be within valid range")
    assert_true(h2 > 0 and h2 <= size, "Hash2 should be within valid range")
    assert_true(h3 > 0 and h3 <= size, "Hash3 should be within valid range")
    
    -- Test consistency
    local h1_again = bloom_filter.hash1(test_string, size)
    local h2_again = bloom_filter.hash2(test_string, size)
    local h3_again = bloom_filter.hash3(test_string, size)
    
    assert_equal(h1, h1_again, "Hash1 should be consistent")
    assert_equal(h2, h2_again, "Hash2 should be consistent")
    assert_equal(h3, h3_again, "Hash3 should be consistent")
    
    -- Test different strings produce different hashes
    local h1_diff = bloom_filter.hash1("different", size)
    assert_true(h1 ~= h1_diff, "Different strings should produce different hashes")
end

-- Test bloom filter parameter calculation
local function test_parameter_calculation()
    print("\n📊 Testing Parameter Calculation")
    print("================================")
    
    local size, hash_count = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
    
    assert_true(size > 0, "Size should be positive")
    assert_true(hash_count > 0, "Hash count should be positive")
    assert_true(size >= 1000, "Size should be at least as large as expected elements")
    
    -- Test with different parameters
    local size2, hash_count2 = bloom_filter.calculate_bloom_filter_params(10000, 0.001)
    assert_true(size2 > size, "Lower false positive rate should result in larger size")
    
    print("Size for 1000 elements, 1% FPR:", size)
    print("Hash count for 1000 elements, 1% FPR:", hash_count)
    print("Size for 10000 elements, 0.1% FPR:", size2)
    print("Hash count for 10000 elements, 0.1% FPR:", hash_count2)
end

-- Test file content parsing
local function test_file_parsing()
    print("\n📁 Testing File Content Parsing")
    print("================================")
    
    local test_content = "line1\nline2\n  line3  \n\nline4\n"
    local elements = bloom_filter.parse_file_content(test_content)
    
    assert_equal(4, #elements, "Should parse 4 non-empty lines")
    assert_equal("line1", elements[1], "First line should be 'line1'")
    assert_equal("line2", elements[2], "Second line should be 'line2'")
    assert_equal("line3", elements[3], "Third line should be 'line3' (trimmed)")
    assert_equal("line4", elements[4], "Fourth line should be 'line4'")
    
    -- Test empty content
    local empty_elements = bloom_filter.parse_file_content("")
    assert_equal(0, #empty_elements, "Empty content should produce no elements")
    
    -- Test whitespace-only content
    local whitespace_elements = bloom_filter.parse_file_content("  \n  \n  ")
    assert_equal(0, #whitespace_elements, "Whitespace-only content should produce no elements")
end

-- Test bloom filter creation
local function test_bloom_filter_creation()
    print("\n🏗️ Testing Bloom Filter Creation")
    print("================================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("test_filter", test_content, 10, 0.01, 1234567890)
    
    assert_equal("test_filter", filter.metadata.name, "Filter name should match")
    assert_equal(3, filter.elements_processed, "Should process 3 elements")
    assert_equal(3, #filter.elements, "Should have 3 elements")
    assert_true(filter.metadata.size > 0, "Size should be calculated")
    assert_true(filter.metadata.hash_count > 0, "Hash count should be calculated")
    
    -- Test bit array generation
    assert_true(type(filter.bit_array) == "table", "Bit array should be generated")
    
    print("Created filter:", filter.metadata.name)
    print("Size:", filter.metadata.size)
    print("Hash count:", filter.metadata.hash_count)
    print("Elements processed:", filter.elements_processed)
end

-- Test element search
local function test_element_search()
    print("\n🔍 Testing Element Search")
    print("==========================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("search_test", test_content, 10, 0.01, 1234567890)
    
    -- Test existing elements
    local exists1 = bloom_filter.search_element_in_bloom_filter("apple", filter.bit_array, filter.metadata.size)
    local exists2 = bloom_filter.search_element_in_bloom_filter("banana", filter.bit_array, filter.metadata.size)
    local exists3 = bloom_filter.search_element_in_bloom_filter("cherry", filter.bit_array, filter.metadata.size)
    
    assert_true(exists1, "Should find 'apple'")
    assert_true(exists2, "Should find 'banana'")
    assert_true(exists3, "Should find 'cherry'")
    
    -- Test non-existing elements
    local exists4 = bloom_filter.search_element_in_bloom_filter("orange", filter.bit_array, filter.metadata.size)
    local exists5 = bloom_filter.search_element_in_bloom_filter("grape", filter.bit_array, filter.metadata.size)
    
    -- Note: Bloom filters can have false positives, so we can't guarantee these are false
    -- But we can test that the function works
    assert_true(type(exists4) == "boolean", "Search should return boolean for 'orange'")
    assert_true(type(exists5) == "boolean", "Search should return boolean for 'grape'")
    
    print("Search results:")
    print("  apple:", exists1)
    print("  banana:", exists2)
    print("  cherry:", exists3)
    print("  orange:", exists4)
    print("  grape:", exists5)
end

-- Test validation functions
local function test_validation()
    print("\n✅ Testing Validation Functions")
    print("===============================")
    
    -- Test valid parameters
    local is_valid, errors = bloom_filter.validate_bloom_filter_params(1000, 0.01)
    assert_true(is_valid, "Valid parameters should pass validation")
    assert_equal(0, #errors, "Should have no validation errors")
    
    -- Test invalid expected elements
    local is_valid2, errors2 = bloom_filter.validate_bloom_filter_params(-100, 0.01)
    assert_false(is_valid2, "Negative expected elements should fail validation")
    assert_true(#errors2 > 0, "Should have validation errors")
    
    -- Test invalid false positive rate
    local is_valid3, errors3 = bloom_filter.validate_bloom_filter_params(1000, 1.5)
    assert_false(is_valid3, "False positive rate > 1 should fail validation")
    assert_true(#errors3 > 0, "Should have validation errors")
    
    print("Validation test results:")
    print("  Valid params:", is_valid)
    print("  Invalid elements:", is_valid2, "Errors:", #errors2)
    print("  Invalid FPR:", is_valid3, "Errors:", #errors3)
end

-- Test statistics calculation
local function test_statistics()
    print("\n📈 Testing Statistics Calculation")
    print("=================================")
    
    local test_content = "apple\nbanana\ncherry\n"
    local filter = bloom_filter.create_bloom_filter_from_file("stats_test", test_content, 10, 0.01, 1234567890)
    
    local stats = bloom_filter.calculate_bloom_filter_stats(filter.bit_array, filter.metadata)
    
    assert_true(stats.set_bits > 0, "Should have some set bits")
    assert_equal(filter.metadata.size, stats.total_bits, "Total bits should match metadata")
    assert_true(stats.bit_density > 0, "Bit density should be positive")
    assert_true(stats.bit_density <= 1, "Bit density should be <= 1")
    assert_equal(3, stats.actual_elements, "Actual elements should match processed count")
    
    print("Statistics:")
    print("  Set bits:", stats.set_bits)
    print("  Total bits:", stats.total_bits)
    print("  Bit density:", string.format("%.4f", stats.bit_density))
    print("  False positive probability:", string.format("%.6f", stats.false_positive_probability))
    print("  Actual elements:", stats.actual_elements)
end

-- Test memory usage estimation
local function test_memory_estimation()
    print("\n💾 Testing Memory Usage Estimation")
    print("===================================")
    
    local size = 10000
    local memory = bloom_filter.estimate_memory_usage(size)
    
    assert_equal(size, memory.bits, "Bits should match input size")
    assert_true(memory.bytes > 0, "Bytes should be positive")
    assert_true(memory.kilobytes > 0, "Kilobytes should be positive")
    assert_true(memory.megabytes >= 0, "Megabytes should be non-negative")
    
    print("Memory usage for", size, "bits:")
    print("  Bits:", memory.bits)
    print("  Bytes:", memory.bytes)
    print("  KB:", string.format("%.2f", memory.kilobytes))
    print("  MB:", string.format("%.4f", memory.megabytes))
end

-- Test bloom filter comparison
local function test_filter_comparison()
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
    assert_true(comparison1.identical, "Identical filters should be identical")
    assert_equal(1.0, comparison1.similarity, "Similarity should be 1.0")
    assert_equal(0, comparison1.differences, "Should have no differences")
    
    -- Test different filters
    local comparison2 = bloom_filter.compare_bloom_filters(filter1, filter3)
    assert_false(comparison2.identical, "Different filters should not be identical")
    assert_true(comparison2.similarity > 0, "Similarity should be positive")
    assert_true(comparison2.differences > 0, "Should have some differences")
    
    print("Comparison results:")
    print("  Filter1 vs Filter2 (identical):", comparison1.identical, "Similarity:", string.format("%.4f", comparison1.similarity))
    print("  Filter1 vs Filter3 (different):", comparison2.identical, "Similarity:", string.format("%.4f", comparison2.similarity))
end

-- Main test runner
local function run_all_tests()
    print("🧪 Running Bloom Filter Pure Function Tests")
    print("===========================================")
    
    local tests = {
        test_hash_functions,
        test_parameter_calculation,
        test_file_parsing,
        test_bloom_filter_creation,
        test_element_search,
        test_validation,
        test_statistics,
        test_memory_estimation,
        test_filter_comparison
    }
    
    local passed = 0
    local total = 0
    
    for _, test in ipairs(tests) do
        local success = pcall(test)
        if success then
            passed = passed + 1
        end
        total = total + 1
        print("") -- Add spacing between tests
    end
    
    print("🎯 Test Results")
    print("===============")
    print("Passed:", passed)
    print("Total:", total)
    print("Success Rate:", string.format("%.1f%%", (passed / total) * 100))
    
    if passed == total then
        print("🎉 All tests passed!")
    else
        print("❌ Some tests failed!")
    end
end

-- Run tests if this file is executed directly
if arg[0] and string.find(arg[0], "test_pure_functions") then
    run_all_tests()
else
    print("Pure function test file loaded. Call run_all_tests() to run tests.")
end

-- Export test functions for external use
return {
    run_all_tests = run_all_tests,
    test_hash_functions = test_hash_functions,
    test_parameter_calculation = test_parameter_calculation,
    test_file_parsing = test_file_parsing,
    test_bloom_filter_creation = test_bloom_filter_creation,
    test_element_search = test_element_search,
    test_validation = test_validation,
    test_statistics = test_statistics,
    test_memory_estimation = test_memory_estimation,
    test_filter_comparison = test_filter_comparison
} 