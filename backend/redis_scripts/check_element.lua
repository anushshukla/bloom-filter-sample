-- Check Element in Bloom Filter - Pure Function Version
-- Usage: redis-cli --eval check_element.lua filter_name element

local filter_name = KEYS[1]
local element = ARGV[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

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

-- Pure function to generate hash positions
local function generate_hash_positions(element, size)
    return {
        hash1(element, size),
        hash2(element, size),
        hash3(element, size)
    }
end

-- Pure function to check if element exists based on hash positions
local function check_element_exists(hash_positions, bit_values)
    for i, position in ipairs(hash_positions) do
        if bit_values[i] ~= 1 then
            return false
        end
    end
    return true
end

-- Get metadata
local metadata = redis.call("HGETALL", meta_key)
if #metadata == 0 then
    return {err = "Bloom filter not found"}
end

local size = tonumber(metadata[2])

-- Generate hash positions using pure function
local hash_positions = generate_hash_positions(element, size)

-- Get bit values from Redis
local bit_values = {}
for i, position in ipairs(hash_positions) do
    local bit_value = redis.call("GETBIT", filter_key, position - 1) -- Redis uses 0-based indexing
    table.insert(bit_values, bit_value)
end

-- Check if element exists using pure function
local exists = check_element_exists(hash_positions, bit_values)

return {element, exists and 1 or 0, hash_positions[1], hash_positions[2], hash_positions[3], bit_values[1], bit_values[2], bit_values[3]} 