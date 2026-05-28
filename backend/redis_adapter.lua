-- Redis Adapter for Bloom Filter Operations
-- Author: AI Assistant
-- Description: Pure Redis operations separated from bloom filter logic

local bloom_filter = require "bloom_filter"

-- Pure function to convert bloom filter to Redis commands
local function bloom_filter_to_redis_commands(filter_name, bloom_filter_data)
    local commands = {}
    
    -- Metadata commands
    local meta_key = bloom_filter.BLOOM_FILTER_META_PREFIX .. filter_name
    local filter_key = bloom_filter.BLOOM_FILTER_KEY_PREFIX .. filter_name
    
    -- HMSET command for metadata
    local metadata_cmd = {
        command = "HMSET",
        key = meta_key,
        fields = {
            size = bloom_filter_data.metadata.size,
            hash_count = bloom_filter_data.metadata.hash_count,
            expected_elements = bloom_filter_data.metadata.expected_elements,
            false_positive_rate = bloom_filter_data.metadata.false_positive_rate,
            created_at = bloom_filter_data.metadata.created_at,
            actual_elements = bloom_filter_data.metadata.actual_elements or bloom_filter_data.elements_processed
        }
    }
    
    table.insert(commands, metadata_cmd)
    
    -- SETBIT commands for bloom filter
    for position, _ in pairs(bloom_filter_data.bit_array) do
        local setbit_cmd = {
            command = "SETBIT",
            key = filter_key,
            offset = position - 1, -- Redis uses 0-based indexing
            value = 1
        }
        table.insert(commands, setbit_cmd)
    end
    
    return commands
end

-- Pure function to convert Redis metadata to bloom filter format
local function redis_metadata_to_bloom_filter(filter_name, redis_metadata)
    local metadata = {}
    
    -- Convert Redis array format to table
    for i = 1, #redis_metadata, 2 do
        local key = redis_metadata[i]
        local value = redis_metadata[i + 1]
        
        -- Convert numeric values
        if key == "size" or key == "hash_count" or key == "expected_elements" or key == "actual_elements" then
            value = tonumber(value)
        elseif key == "false_positive_rate" then
            value = tonumber(value)
        elseif key == "created_at" then
            value = tonumber(value)
        end
        
        metadata[key] = value
    end
    
    metadata.name = filter_name
    return metadata
end

-- Pure function to convert Redis bit array to bloom filter format
local function redis_bit_array_to_bloom_filter(redis_bit_array, size)
    local bit_array = {}
    
    for i = 1, size do
        if redis_bit_array[i] == 1 then
            bit_array[i] = true
        end
    end
    
    return bit_array
end

-- Pure function to generate Redis search commands
local function generate_search_commands(filter_name, element)
    local meta_key = bloom_filter.BLOOM_FILTER_META_PREFIX .. filter_name
    local filter_key = bloom_filter.BLOOM_FILTER_KEY_PREFIX .. filter_name
    
    return {
        get_metadata = {
            command = "HGETALL",
            key = meta_key
        },
        get_bits = {
            command = "MGET",
            keys = {filter_key}
        }
    }
end

-- Pure function to generate Redis list commands
local function generate_list_commands()
    return {
        list_keys = {
            command = "KEYS",
            pattern = bloom_filter.BLOOM_FILTER_META_PREFIX .. "*"
        }
    }
end

-- Pure function to generate Redis delete commands
local function generate_delete_commands(filter_name)
    local meta_key = bloom_filter.BLOOM_FILTER_META_PREFIX .. filter_name
    local filter_key = bloom_filter.BLOOM_FILTER_KEY_PREFIX .. filter_name
    
    return {
        delete_metadata = {
            command = "DEL",
            key = meta_key
        },
        delete_filter = {
            command = "DEL",
            key = filter_key
        }
    }
end

-- Pure function to validate Redis response
local function validate_redis_response(response, expected_type)
    if not response then
        return false, "No response received"
    end
    
    if expected_type == "metadata" then
        if #response == 0 then
            return false, "No metadata found"
        end
        if #response % 2 ~= 0 then
            return false, "Invalid metadata format"
        end
    elseif expected_type == "bit_array" then
        if not response[1] then
            return false, "No bit array found"
        end
    end
    
    return true
end

-- Pure function to create bloom filter from Redis data
local function create_bloom_filter_from_redis(filter_name, redis_metadata, redis_bit_array)
    local metadata = redis_metadata_to_bloom_filter(filter_name, redis_metadata)
    local bit_array = redis_bit_array_to_bloom_filter(redis_bit_array, metadata.size)
    
    return {
        metadata = metadata,
        bit_array = bit_array
    }
end

-- Pure function to calculate Redis memory usage
local function calculate_redis_memory_usage(bloom_filter_data)
    local size = bloom_filter_data.metadata.size
    local bytes = math.ceil(size / 8)
    
    -- Redis overhead (approximately)
    local redis_overhead = 16 -- bytes for key structure
    local metadata_overhead = 64 -- bytes for hash metadata
    
    return {
        bloom_filter_bytes = bytes,
        total_bytes = bytes + redis_overhead + metadata_overhead,
        bloom_filter_kb = bytes / 1024,
        total_kb = (bytes + redis_overhead + metadata_overhead) / 1024
    }
end

-- Pure function to generate Redis pipeline commands
local function generate_pipeline_commands(commands)
    local pipeline = {}
    
    for _, cmd in ipairs(commands) do
        table.insert(pipeline, {
            command = cmd.command,
            key = cmd.key,
            args = cmd.args or {}
        })
    end
    
    return pipeline
end

-- Export pure functions
return {
    -- Core conversion functions
    bloom_filter_to_redis_commands = bloom_filter_to_redis_commands,
    redis_metadata_to_bloom_filter = redis_metadata_to_bloom_filter,
    redis_bit_array_to_bloom_filter = redis_bit_array_to_bloom_filter,
    create_bloom_filter_from_redis = create_bloom_filter_from_redis,
    
    -- Command generation functions
    generate_search_commands = generate_search_commands,
    generate_list_commands = generate_list_commands,
    generate_delete_commands = generate_delete_commands,
    generate_pipeline_commands = generate_pipeline_commands,
    
    -- Utility functions
    validate_redis_response = validate_redis_response,
    calculate_redis_memory_usage = calculate_redis_memory_usage
} 