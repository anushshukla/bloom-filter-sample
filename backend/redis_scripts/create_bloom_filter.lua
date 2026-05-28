-- Create Bloom Filter
-- Usage: redis-cli --eval create_bloom_filter.lua key_name expected_elements false_positive_rate

local filter_name = KEYS[1]
local expected_elements = tonumber(ARGV[1]) or 10000
local false_positive_rate = tonumber(ARGV[2]) or 0.01

-- Calculate optimal size and hash count
local size = math.ceil(-expected_elements * math.log(false_positive_rate) / (math.log(2) ^ 2))
local hash_count = math.ceil(size / expected_elements * math.log(2))

-- Store metadata
local meta_key = "bloom_filter_meta:" .. filter_name
redis.call("HMSET", meta_key, 
    "size", size,
    "hash_count", hash_count,
    "expected_elements", expected_elements,
    "false_positive_rate", false_positive_rate,
    "created_at", redis.call("TIME")[1]
)

-- Initialize bloom filter
local filter_key = "bloom_filter:" .. filter_name
redis.call("DEL", filter_key)

return {filter_name, size, hash_count, expected_elements, false_positive_rate} 