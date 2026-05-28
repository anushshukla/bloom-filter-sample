-- List All Bloom Filters
-- Usage: redis-cli --eval list_filters.lua

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