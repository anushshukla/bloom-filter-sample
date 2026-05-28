-- Process File and Create Bloom Filter - Pure Function Version
-- Usage: redis-cli --eval process_file.lua filter_name expected_elements false_positive_rate "line1\nline2\nline3"

local filter_name = KEYS[1]
local expected_elements = tonumber(ARGV[1]) or 10000
local false_positive_rate = tonumber(ARGV[2]) or 0.01
local file_content = ARGV[3]

-- Pure hash functions
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

-- Pure function to calculate bloom filter parameters
local function calculate_bloom_filter_params(expected_elements, false_positive_rate)
    local size = math.ceil(-expected_elements * math.log(false_positive_rate) / (math.log(2) ^ 2))
    local hash_count = math.ceil(size / expected_elements * math.log(2))
    return size, hash_count
end

-- Pure function to generate hash positions
local function generate_hash_positions(element, size)
    return {
        hash1(element, size),
        hash2(element, size),
        hash3(element, size)
    }
end

-- Pure function to parse file content
local function parse_file_content(file_content)
    local elements = {}
    for line in string.gmatch(file_content, "[^\r\n]+") do
        line = string.gsub(line, "^%s*(.-)%s*$", "%1") -- trim whitespace
        if #line > 0 then
            table.insert(elements, line)
        end
    end
    return elements
end

-- Pure function to create bloom filter metadata
local function create_metadata(filter_name, expected_elements, false_positive_rate)
    local size, hash_count = calculate_bloom_filter_params(expected_elements, false_positive_rate)
    return {
        name = filter_name,
        size = size,
        hash_count = hash_count,
        expected_elements = expected_elements,
        false_positive_rate = false_positive_rate,
        created_at = redis.call("TIME")[1]
    }
end

-- Pure function to generate bloom filter bit array
local function generate_bit_array(elements, size)
    local bit_array = {}
    
    for _, element in ipairs(elements) do
        if element and #element > 0 then
            local hash_positions = generate_hash_positions(element, size)
            for _, position in ipairs(hash_positions) do
                bit_array[position] = true
            end
        end
    end
    
    return bit_array
end

-- Main execution using pure functions
local metadata = create_metadata(filter_name, expected_elements, false_positive_rate)
local elements = parse_file_content(file_content)
local bit_array = generate_bit_array(elements, metadata.size)

-- Store metadata in Redis
local meta_key = "bloom_filter_meta:" .. filter_name
redis.call("HMSET", meta_key, 
    "size", metadata.size,
    "hash_count", metadata.hash_count,
    "expected_elements", metadata.expected_elements,
    "false_positive_rate", metadata.false_positive_rate,
    "created_at", metadata.created_at
)

-- Initialize and populate bloom filter in Redis
local filter_key = "bloom_filter:" .. filter_name
redis.call("DEL", filter_key)

-- Set bits in Redis
local added_count = 0
for position, _ in pairs(bit_array) do
    redis.call("SETBIT", filter_key, position - 1, 1) -- Redis uses 0-based indexing
    added_count = added_count + 1
end

-- Update metadata with actual count
redis.call("HSET", meta_key, "actual_elements", #elements)

return {filter_name, metadata.size, metadata.hash_count, metadata.expected_elements, metadata.false_positive_rate, #elements, #elements} 