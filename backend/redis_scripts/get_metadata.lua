-- Get Bloom Filter Metadata
-- Usage: redis-cli --eval get_metadata.lua filter_name

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