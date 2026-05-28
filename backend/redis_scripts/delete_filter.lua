-- Delete Bloom Filter
-- Usage: redis-cli --eval delete_filter.lua filter_name

local filter_name = KEYS[1]
local meta_key = "bloom_filter_meta:" .. filter_name
local filter_key = "bloom_filter:" .. filter_name

local deleted_meta = redis.call("DEL", meta_key)
local deleted_filter = redis.call("DEL", filter_key)

return {filter_name, deleted_meta, deleted_filter} 