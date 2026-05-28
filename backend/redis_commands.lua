-- Redis EVAL Commands for Bloom Filter Operations
-- These commands can be executed directly with redis-cli

-- Command 1: Create Bloom Filter
-- Usage: redis-cli --eval create_bloom_filter.lua key_name expected_elements false_positive_rate
local CREATE_BLOOM_FILTER = [[
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
]]

-- Command 2: Add Elements to Bloom Filter
-- Usage: redis-cli --eval add_elements.lua filter_name element1 element2 element3 ...
local ADD_ELEMENTS = [[
local filter_name = KEYS[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

-- Get metadata
local metadata = redis.call("HGETALL", meta_key)
if #metadata == 0 then
    return {err = "Bloom filter not found"}
end

local size = tonumber(metadata[2])
local hash_count = tonumber(metadata[4])

-- Hash functions
local function hash1(str, size)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash2(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash3(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 37) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

-- Process each element
local added_count = 0
for i = 1, #ARGV do
    local element = ARGV[i]
    if element and #element > 0 then
        -- Apply hash functions
        local h1 = hash1(element, size)
        local h2 = hash2(element, size)
        local h3 = hash3(element, size)
        
        -- Set bits in bloom filter
        redis.call("SETBIT", filter_key, h1, 1)
        redis.call("SETBIT", filter_key, h2, 1)
        redis.call("SETBIT", filter_key, h3, 1)
        
        added_count = added_count + 1
    end
end

-- Update metadata with actual count
redis.call("HSET", meta_key, "actual_elements", added_count)

return {added_count, size, hash_count}
]]

-- Command 3: Check Element in Bloom Filter
-- Usage: redis-cli --eval check_element.lua filter_name element
local CHECK_ELEMENT = [[
local filter_name = KEYS[1]
local element = ARGV[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

-- Get metadata
local metadata = redis.call("HGETALL", meta_key)
if #metadata == 0 then
    return {err = "Bloom filter not found"}
end

local size = tonumber(metadata[2])

-- Hash functions
local function hash1(str, size)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash2(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash3(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 37) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

-- Apply hash functions
local h1 = hash1(element, size)
local h2 = hash2(element, size)
local h3 = hash3(element, size)

-- Check if all bits are set
local bit1 = redis.call("GETBIT", filter_key, h1)
local bit2 = redis.call("GETBIT", filter_key, h2)
local bit3 = redis.call("GETBIT", filter_key, h3)

local exists = bit1 == 1 and bit2 == 1 and bit3 == 1

return {element, exists and 1 or 0, h1, h2, h3, bit1, bit2, bit3}
]]

-- Command 4: Get Bloom Filter Metadata
-- Usage: redis-cli --eval get_metadata.lua filter_name
local GET_METADATA = [[
local filter_name = KEYS[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

local metadata = redis.call("HGETALL", meta_key)
if #metadata == 0 then
    return {err = "Bloom filter not found"}
end

-- Get actual elements count
local actual_elements = redis.call("HLEN", filter_key)

return {filter_name, metadata, actual_elements}
]]

-- Command 5: List All Bloom Filters
-- Usage: redis-cli --eval list_filters.lua
local LIST_FILTERS = [[
local keys = redis.call("KEYS", "bloom_filter_meta:*")
local filters = {}

for i, key in ipairs(keys) do
    local filter_name = string.gsub(key, "bloom_filter_meta:", "")
    local metadata = redis.call("HGETALL", key)
    if #metadata > 0 then
        table.insert(filters, filter_name)
        for j = 1, #metadata, 2 do
            table.insert(filters, metadata[j])
            table.insert(filters, metadata[j + 1])
        end
    end
end

return filters
]]

-- Command 6: Delete Bloom Filter
-- Usage: redis-cli --eval delete_filter.lua filter_name
local DELETE_FILTER = [[
local filter_name = KEYS[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

local deleted_meta = redis.call("DEL", meta_key)
local deleted_filter = redis.call("DEL", filter_key)

return {filter_name, deleted_meta, deleted_filter}
]]

-- Command 7: Process File and Create Bloom Filter
-- Usage: redis-cli --eval process_file.lua filter_name expected_elements false_positive_rate "line1\nline2\nline3"
local PROCESS_FILE = [[
local filter_name = KEYS[1]
local expected_elements = tonumber(ARGV[1]) or 10000
local false_positive_rate = tonumber(ARGV[2]) or 0.01
local file_content = ARGV[3]

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

-- Hash functions
local function hash1(str, size)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash2(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

local function hash3(str, size)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 37) + string.byte(str, i)) % size
    end
    return hash % size + 1
end

-- Process file content line by line
local lines = {}
for line in string.gmatch(file_content, "[^\r\n]+") do
    line = string.gsub(line, "^%s*(.-)%s*$", "%1") -- trim whitespace
    if #line > 0 then
        table.insert(lines, line)
    end
end

-- Add elements to bloom filter
local added_count = 0
for _, element in ipairs(lines) do
    -- Apply hash functions
    local h1 = hash1(element, size)
    local h2 = hash2(element, size)
    local h3 = hash3(element, size)
    
    -- Set bits in bloom filter
    redis.call("SETBIT", filter_key, h1, 1)
    redis.call("SETBIT", filter_key, h2, 1)
    redis.call("SETBIT", filter_key, h3, 1)
    
    added_count = added_count + 1
end

-- Update metadata with actual count
redis.call("HSET", meta_key, "actual_elements", added_count)

return {filter_name, size, hash_count, expected_elements, false_positive_rate, added_count, #lines}
]]

-- Export all commands
return {
    CREATE_BLOOM_FILTER = CREATE_BLOOM_FILTER,
    ADD_ELEMENTS = ADD_ELEMENTS,
    CHECK_ELEMENT = CHECK_ELEMENT,
    GET_METADATA = GET_METADATA,
    LIST_FILTERS = LIST_FILTERS,
    DELETE_FILTER = DELETE_FILTER,
    PROCESS_FILE = PROCESS_FILE
} 