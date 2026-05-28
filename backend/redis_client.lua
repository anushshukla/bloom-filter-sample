-- Simple Redis Client for Bloom Filter Testing
-- This script provides direct Redis operations for testing bloom filter functionality

local redis = require "redis"

-- Configuration
local REDIS_HOST = "localhost"
local REDIS_PORT = 6379

-- Initialize Redis connection
local function connect_redis()
    local client = redis.connect(REDIS_HOST, REDIS_PORT)
    if not client then
        print("Failed to connect to Redis")
        return nil
    end
    print("Connected to Redis at " .. REDIS_HOST .. ":" .. REDIS_PORT)
    return client
end

-- Test bloom filter operations
local function test_bloom_filter()
    local client = connect_redis()
    if not client then
        return
    end
    
    print("\n=== Bloom Filter Test ===")
    
    -- Test data
    local test_data = {
        "apple",
        "banana",
        "cherry",
        "date",
        "elderberry",
        "fig",
        "grape",
        "honeydew"
    }
    
    -- Create bloom filter
    local filter_name = "test_fruits"
    print("Creating bloom filter: " .. filter_name)
    
    -- Store metadata
    local meta_key = "bloom_filter_meta:" .. filter_name
    client:hmset(meta_key, {
        size = 100,
        hash_count = 3,
        expected_elements = 10,
        false_positive_rate = 0.01,
        created_at = os.time()
    })
    
    -- Initialize bloom filter
    local filter_key = "bloom_filter:" .. filter_name
    client:del(filter_key)
    
    -- Add test data
    print("Adding " .. #test_data .. " elements to bloom filter")
    for _, element in ipairs(test_data) do
        -- Simple hash functions
        local h1 = (element:byte(1) * 31 + #element) % 100 + 1
        local h2 = (element:byte(#element) * 37 + #element) % 100 + 1
        local h3 = (element:byte(math.ceil(#element/2)) * 41 + #element) % 100 + 1
        
        client:setbit(filter_key, h1, 1)
        client:setbit(filter_key, h2, 1)
        client:setbit(filter_key, h3, 1)
    end
    
    -- Test search
    print("\nTesting search functionality:")
    local test_search = {"apple", "banana", "orange", "grape", "mango"}
    
    for _, search_term in ipairs(test_search) do
        local h1 = (search_term:byte(1) * 31 + #search_term) % 100 + 1
        local h2 = (search_term:byte(#search_term) * 37 + #search_term) % 100 + 1
        local h3 = (search_term:byte(math.ceil(#search_term/2)) * 41 + #search_term) % 100 + 1
        
        local bit1 = client:getbit(filter_key, h1)
        local bit2 = client:getbit(filter_key, h2)
        local bit3 = client:getbit(filter_key, h3)
        
        local exists = bit1 == 1 and bit2 == 1 and bit3 == 1
        local status = exists and "FOUND" or "NOT FOUND"
        print(string.format("  %-10s: %s", search_term, status))
    end
    
    -- Cleanup
    client:del(meta_key)
    client:del(filter_key)
    print("\nTest completed. Bloom filter cleaned up.")
end

-- Main execution
if arg[1] == "test" then
    test_bloom_filter()
else
    print("Usage: lua redis_client.lua test")
    print("This will test bloom filter functionality with Redis")
end 