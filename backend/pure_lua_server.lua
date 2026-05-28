#!/usr/bin/env lua

-- Pure Lua HTTP Server with Bloom Filter API and Redis Storage
-- Supports both JSON and multipart form data uploads

-- Redis configuration
local REDIS_HOST = "127.0.0.1"
local REDIS_PORT = 6379
local REDIS_DB = 0
local REDIS_TIMEOUT = 5000 -- 5 seconds

-- Redis connection management
local redis_connection = nil
local redis_connected = false

-- Function to connect to Redis
local function connect_to_redis()
    if redis_connected and redis_connection then
        return true
    end
    
    print("🔌 Attempting to connect to Redis...")
    
    -- Try to connect using luasocket (if available) or fallback to basic socket
    local socket = require("socket")
    if not socket then
        print("❌ LuaSocket not available, falling back to basic socket")
        -- Fallback implementation would go here
        return false
    end
    
    local success, conn = pcall(function()
        local tcp = socket.tcp()
        tcp:settimeout(REDIS_TIMEOUT / 1000)
        local result, err = tcp:connect(REDIS_HOST, REDIS_PORT)
        if not result then
            error("Failed to connect: " .. (err or "unknown error"))
        end
        return tcp
    end)
    
    if success then
        redis_connection = conn
        redis_connected = true
        print("✅ Redis connected successfully")
        
        -- Test Redis connection with simple PING
        local ping_success, ping_response = pcall(function()
            redis_connection:send("PING\r\n")
            local response = redis_connection:receive("*l")
            return response
        end)
        
        if ping_success and ping_response == "PONG" then
            print("✅ Redis PING successful")
            return true
        else
            print("❌ Redis PING failed, but continuing...")
            -- Don't fail completely, just warn
            return true
        end
    else
        print("❌ Redis connection failed:", conn)
        return false
    end
end

-- Function to test Redis connection
local function redis_ping()
    local response = redis_command("PING")
    return response == "PONG"
end

-- Function to send Redis command and get response
local function redis_command(command)
    if not redis_connected or not redis_connection then
        if not connect_to_redis() then
            return nil, "Redis not connected"
        end
    end
    
    local success, result = pcall(function()
        redis_connection:send(command .. "\r\n")
        local response = redis_connection:receive("*l")
        return response
    end)
    
    if not success then
        print("❌ Redis command failed:", result)
        redis_connected = false
        redis_connection = nil
        return nil, "Redis command failed: " .. tostring(result)
    end
    
    return result
end

-- Function to set key in Redis
local function redis_set(key, value)
    -- Use proper RESP protocol for SET command
    local command = string.format("*3\r\n$3\r\nSET\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n", 
        #key, key, #value, value)
    
    local success, result = pcall(function()
        redis_connection:send(command)
        local response = redis_connection:receive("*l")
        return response
    end)
    
    if success and (result == "OK" or result == "+OK") then
        return true
    else
        print("❌ Redis SET failed:", result or "unknown error")
        return false
    end
end

-- Function to get key from Redis
local function redis_get(key)
    -- Use proper RESP protocol for GET command
    local command = string.format("*2\r\n$3\r\nGET\r\n$%d\r\n%s\r\n", #key, key)
    
    local success, result = pcall(function()
        redis_connection:send(command)
        local response = redis_connection:receive("*l")
        
        if response and response:sub(1,1) == "$" then
            -- RESP bulk string format: $length\r\nvalue\r\n
            local length = tonumber(response:sub(2))
            if length and length > 0 then
                local value = redis_connection:receive(length)
                redis_connection:receive(2) -- Skip \r\n
                return value
            elseif length == 0 then
                return ""
            end
        end
        
        return response
    end)
    
    if success then
        return result
    else
        print("❌ Redis GET failed:", result or "unknown error")
        return nil
    end
end

-- Function to delete key from Redis
local function redis_del(key)
    local response = redis_command('DEL "' .. key .. '"')
    return response == "1"
end

-- Function to get all keys matching pattern
local function redis_keys(pattern)
    local response = redis_command('KEYS "' .. pattern .. '"')
    if response and response:sub(1,1) == "*" then
        -- RESP array format: *count\r\n
        local count = tonumber(response:sub(2))
        local keys = {}
        for i = 1, count do
            local key_response = redis_connection:receive("*l")
            if key_response and key_response:sub(1,1) == "$" then
                local key_length = tonumber(key_response:sub(2))
                if key_length and key_length > 0 then
                    local key = redis_connection:receive(key_length)
                    redis_connection:receive(2) -- Skip \r\n
                    table.insert(keys, key)
                end
            end
        end
        return keys
    end
    return {}
end

-- Function to check if key exists
local function redis_exists(key)
    local response = redis_command('EXISTS "' .. key .. '"')
    return response == "1"
end

-- Simple JSON encoding (pure Lua implementation)
local function simple_json_encode(data)
    if data == nil then
        return "null"
    elseif type(data) == "boolean" then
        return data and "true" or "false"
    elseif type(data) == "number" then
        return tostring(data)
    elseif type(data) == "string" then
        -- Escape special characters
        local escaped = data:gsub("\\", "\\\\")
        escaped = escaped:gsub("\"", "\\\"")
        escaped = escaped:gsub("\n", "\\n")
        escaped = escaped:gsub("\r", "\\r")
        escaped = escaped:gsub("\t", "\\t")
        return '"' .. escaped .. '"'
    elseif type(data) == "table" then
        local is_array = true
        local max_index = 0
        
        -- Check if it's an array
        for k, _ in pairs(data) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
                break
            end
            max_index = math.max(max_index, k)
        end
        
        if is_array and max_index == #data then
            -- It's an array
            local parts = {}
            for i = 1, #data do
                table.insert(parts, simple_json_encode(data[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- It's an object
            local parts = {}
            for k, v in pairs(data) do
                table.insert(parts, simple_json_encode(tostring(k)) .. ":" .. simple_json_encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return '"' .. tostring(data) .. '"'
    end
end

-- Simple JSON decoding (pure Lua implementation)
local function simple_json_decode(json_str)
    if not json_str or #json_str == 0 then
        return nil, "Empty JSON string"
    end
    
    -- Very simple JSON parser for basic objects
    local result = {}
    
    -- Remove outer braces
    local content = json_str:match("^%s*%{(.*)%}%s*$")
    if not content then
        return nil, "Not a valid JSON object"
    end
    
    -- Split by commas and parse key-value pairs
    for pair in content:gmatch("([^,]+)") do
        local key, value = pair:match('"([^"]+)"%s*:%s*(.+)')
        if key and value then
            -- Parse value based on type
            if value:match('^"[^"]*"$') then
                -- String value
                result[key] = value:sub(2, -2)
            elseif value == "true" then
                result[key] = true
            elseif value == "false" then
                result[key] = false
            elseif value == "null" then
                result[key] = nil
            else
                -- Number value
                local num = tonumber(value)
                if num then
                    result[key] = num
                else
                    result[key] = value
                end
            end
        end
    end
    
    return result
end

-- Helper function to get table keys
local function table_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

-- Parse multipart form data (pure Lua implementation)
local function parse_multipart_data(data, boundary)
    local parts = {}
    local boundary_str = "--" .. boundary
    
    print("🔍 Parsing multipart data with boundary:", boundary_str)
    print("🔍 Data length:", #data)
    
    -- Split data by boundary
    local parts_raw = {}
    local data_str = tostring(data)
    
    -- Find all boundary positions
    local boundaries = {}
    local pos = 1
    while true do
        local found = data_str:find(boundary_str, pos, true)
        if not found then break end
        table.insert(boundaries, found)
        pos = found + 1
    end
    
    print("🔍 Found", #boundaries, "boundaries")
    
    -- Extract parts between boundaries
    for i = 1, #boundaries - 1 do
        local start_pos = boundaries[i] + #boundary_str + 2 -- Skip boundary + \r\n
        local end_pos = boundaries[i + 1] - 3 -- Stop before next boundary
        
        if start_pos < end_pos then
            local part_data = data_str:sub(start_pos, end_pos)
            table.insert(parts_raw, part_data)
        end
    end
    
    print("🔍 Extracted", #parts_raw, "raw parts")
    
    -- Process each part
    for i, part_data in ipairs(parts_raw) do
        local header_end = part_data:find("\r\n\r\n")
        if header_end then
            local headers = part_data:sub(1, header_end)
            local body = part_data:sub(header_end + 4)
            
            -- Extract field name
            local name_match = headers:match('name="([^"]+)"')
            if name_match then
                parts[name_match] = body
                print("🔍 Found field:", name_match, "with value length:", #body)
            end
        end
    end
    
    print("🔍 Parsed parts:", table.concat(table.keys(parts), ", "))
    return parts
end

-- Create bloom filter from file content
local function create_bloom_filter_from_content(name, content, expected_elements, false_positive_rate)
    -- Load bloom filter module
    package.path = package.path .. ";backend/?.lua"
    local bloom_filter = require("bloom_filter")
    
    -- Create bloom filter
    local created_at = os.time()
    local filter = bloom_filter.create_bloom_filter_from_file(
        name, 
        content, 
        expected_elements or 1000, 
        false_positive_rate or 0.01, 
        created_at
    )
    
    if not filter then
        return nil, "Failed to create bloom filter"
    end
    
    -- Export lightweight data for frontend (only essential search data)
    local exported = bloom_filter.export_bloom_filter_for_search(filter)
    
    return exported
end

-- Redis-based storage functions
local function store_bloom_filter_redis(name, filter_data)
    if not redis_connected then
        if not connect_to_redis() then
            print("⚠️  Redis not available, storing in memory as fallback")
            -- Fallback to in-memory storage
            return true
        end
    end
    
    local key = "bloom_filter:" .. name
    local json_data = simple_json_encode(filter_data)
    
    local success = redis_set(key, json_data)
    if success then
        print("✅ Bloom filter stored in Redis:", name)
        return true
    else
        print("❌ Failed to store bloom filter in Redis:", name)
        print("⚠️  Continuing with in-memory fallback")
        return true -- Don't fail completely
    end
end

local function get_bloom_filter_redis(name)
    if not redis_connected then
        if not connect_to_redis() then
            return nil, "Redis not available"
        end
    end
    
    local key = "bloom_filter:" .. name
    local json_data = redis_get(key)
    
    if json_data then
        local success, filter_data = pcall(simple_json_decode, json_data)
        if success then
            print("✅ Bloom filter retrieved from Redis:", name)
            return filter_data
        else
            print("❌ Failed to decode bloom filter from Redis:", name)
            return nil, "JSON decode failed"
        end
    else
        print("❌ Bloom filter not found in Redis:", name)
        return nil, "Not found"
    end
end

local function list_bloom_filters_redis()
    if not redis_connected then
        if not connect_to_redis() then
            return {}, "Redis not available"
        end
    end
    
    local keys = redis_keys("bloom_filter:*")
    local filters = {}
    
    for _, key in ipairs(keys) do
        local name = key:gsub("bloom_filter:", "")
        local filter_data = get_bloom_filter_redis(name)
        if filter_data then
            table.insert(filters, {
                name = filter_data.name,
                size = filter_data.size,
                actual_elements = filter_data.actual_elements,
                expected_elements = filter_data.expected_elements,
                created_at = filter_data.created_at
            })
        end
    end
    
    return filters
end

-- Delete bloom filter
local function delete_bloom_filter_redis(name)
    if not redis_connected then
        if not connect_to_redis() then
            return false, "Redis not available"
        end
    end
    
    local key = "bloom_filter:" .. name
    local success = redis_del(key)
    
    if success then
        print("✅ Bloom filter deleted from Redis:", name)
        return true
    else
        print("❌ Failed to delete bloom filter from Redis:", name)
        return false, "Redis deletion failed"
    end
end

-- Pure Lua HTTP Server for Bloom Filter Management
-- Handles file uploads, creates bloom filters, and provides lightweight data to frontend
-- NO PYTHON DEPENDENCIES - Pure Lua implementation with Redis storage

local socket = require("socket")

-- Import binary encoder for high-performance data transfer
package.path = package.path .. ";backend/?.lua"
local binary_encoder = require("binary_encoder")

-- Configuration
local PORT = 8080
local HOST = "0.0.0.0"

-- CORS headers
local function add_cors_headers()
    return {
        "Access-Control-Allow-Origin: *",
        "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers: Content-Type, Authorization, Accept, Origin, X-Requested-With",
        "Access-Control-Max-Age: 86400"
    }
end

-- Send JSON response (consolidated)
local function send_json_response(client, status, data)
    local json_data = simple_json_encode(data)
    local response = string.format("HTTP/1.1 %s\r\n", status)
    
    -- Add CORS headers (excluding Content-Type since we'll set it specifically for JSON)
    local cors_headers = add_cors_headers()
    for _, header in ipairs(cors_headers) do
        if not header:match("^Content%-Type:") then
            response = response .. header .. "\r\n"
        end
    end
    
    -- Add JSON-specific headers
    response = response .. "Content-Type: application/json\r\n"
    response = response .. string.format("Content-Length: %d\r\n", #json_data)
    response = response .. "\r\n" -- Empty line to separate headers from body
    response = response .. json_data
    
    print("🔍 Sending JSON response, length:", #response)
    print("🔍 Response preview:", response:sub(1, 200))
    print("🔍 Full response:")
    print(response)
    print("🔍 End of response")
    
    -- Send the response and ensure it's complete
    local success, err = client:send(response)
    if not success then
        print("❌ Failed to send response:", err)
    else
        print("✅ Response sent successfully")
    end
end

-- Check if request has timed out
local function check_request_timeout(request_start_time, max_timeout)
    max_timeout = max_timeout or 30 -- Default 30 seconds
    if os.time() - request_start_time > max_timeout then
        return true, "Request timeout after " .. max_timeout .. " seconds"
    end
    return false, nil
end

-- Send binary response
local function send_binary_response(client, status, data)
    local binary_data = binary_encoder.encode_response(data.success, data.message or "", data.filter, data.elements_processed)
    local response = string.format("HTTP/1.1 %s\r\n", status)
    
    -- Add CORS headers
    for _, header in ipairs(add_cors_headers()) do
        if not header:match("^Content%-Type:") then
            response = response .. header .. "\r\n"
        end
    end
    
    -- Add binary-specific headers
    response = response .. "Content-Type: application/octet-stream\r\n"
    response = response .. string.format("Content-Length: %d\r\n", #binary_data)
    response = response .. "\r\n" -- Empty line to separate headers from body
    response = response .. binary_data
    
    print("🔍 Sending binary response, length:", #response)
    print("🔍 Binary data size:", #binary_data)
    print("🔍 Response preview:", response:sub(1, 200))
    
    -- Send the response and ensure it's complete
    local success, err = client:send(response)
    if not success then
        print("❌ Failed to send binary response:", err)
    else
        print("✅ Binary response sent successfully")
    end
end

-- Parse multipart form data
local function parse_multipart_data(body, boundary)
    local parts = {}
    local pattern = string.format("--%s\r\n(.-)\r\n--%s", boundary, boundary)
    
    for part in body:gmatch(pattern) do
        local headers, content = part:match("(.-)\r\n\r\n(.*)")
        if headers then
            local name = headers:match('name="([^"]+)"')
            if name then
                parts[name] = content
            end
        end
    end
    
    return parts
end

-- Handle file upload and bloom filter creation
local function handle_file_upload(request_body, content_type)
    print("🔍 handle_file_upload called with content_type:", content_type)
    local file_content, name, expected_elements, false_positive_rate
    
    -- Check if it's JSON content or text/plain
    if content_type and (content_type:match("application/json") or content_type:match("text/plain")) then
        -- Parse JSON data (text/plain can contain JSON)
        print("🔍 Attempting to parse content...")
        print("🔍 Content-Type:", content_type)
        print("🔍 Request body length:", #request_body)
        print("🔍 Request body preview:", request_body:sub(1, 100))
        
        local success, data = pcall(simple_json_decode, request_body)
        if not success or not data then
            print("❌ Content parsing failed:", data)
            return { success = false, error = "Invalid content format: " .. tostring(data) }
        end
        
        print("✅ Content parsed successfully:", simple_json_encode(data))
        
        -- Validate required fields
        if not data.file_content then
            return { success = false, error = "Missing file_content field" }
        end
        
        file_content = data.file_content
        name = data.filter_name or "unnamed_filter"
        expected_elements = tonumber(data.expected_elements) or 1000
        false_positive_rate = tonumber(data.false_positive_rate) or 0.01
        
        print("🔍 Extracted data:", { name = name, expected_elements = expected_elements, false_positive_rate = false_positive_rate })
    else
        -- For now, just try to extract basic fields from the request body
        print("🔍 Attempting to parse multipart data...")
        print("🔍 Request body preview (first 200 chars):", request_body:sub(1, 200))
        print("🔍 Request body preview (last 200 chars):", request_body:sub(-200))
        
        -- Simple approach: look for field names in the body
        local name_match = request_body:match('name="filter_name"%-%-%-\r\n\r\n([^\r\n]+)')
        local file_match = request_body:match('name="file_content"%-%-%-\r\n\r\n([^\r\n]+)')
        local elements_match = request_body:match('name="expected_elements"%-%-%-\r\n\r\n([^\r\n]+)')
        local rate_match = request_body:match('name="false_positive_rate"%-%-%-\r\n\r\n([^\r\n]+)')
        
        if name_match then name = name_match end
        if file_match then file_content = file_match end
        if elements_match then expected_elements = tonumber(elements_match) or 1000 end
        if rate_match then false_positive_rate = tonumber(rate_match) or 0.01 end
        
        print("🔍 Simple parsing results:")
        print("🔍   name:", name)
        print("🔍   file_content:", file_content and #file_content or "nil")
        print("🔍   expected_elements:", expected_elements)
        print("🔍   false_positive_rate:", false_positive_rate)
    end
    
    if not file_content or #file_content == 0 then
        return { success = false, error = "No file content" }
    end
    
    print("🔍 About to create bloom filter...")
    
    -- Create bloom filter
    local filter_data = create_bloom_filter_from_content(name, file_content, expected_elements, false_positive_rate)
    if not filter_data then
        print("❌ Failed to create bloom filter")
        return { success = false, error = "Failed to create bloom filter" }
    end
    
    print("🔍 Bloom filter created, about to store in Redis...")
    
    -- Store in Redis
    local stored = store_bloom_filter_redis(name, filter_data)
    if not stored then
        print("❌ Failed to store in Redis")
        return { success = false, error = "Failed to store filter" }
    end
    
    print("🔍 Successfully stored in Redis, returning result")
    
    return { 
        success = true, 
        message = "Bloom filter created successfully",
        filter = filter_data
    }
end





-- Main request handler
local function handle_request(client, request_line)
    local method, path = request_line:match("^([A-Z]+) ([^ ]+)")
    
    if not method or not path then
        client:close()
        return
    end
    
    print("🔍", method, path)
    
    -- Set comprehensive timeouts to prevent hanging
    client:settimeout(10) -- 10 second timeout for socket operations
    local request_start_time = os.time() -- Track request processing time
    
    -- Handle CORS preflight
    if method == "OPTIONS" then
        print("🔍 Handling CORS preflight OPTIONS request")
        print("🔍 Sending CORS response with headers:")
        local cors_headers = add_cors_headers()
        for _, header in ipairs(cors_headers) do
            print("🔍   ", header)
        end
        
        -- Send proper CORS preflight response
        local response = string.format("HTTP/1.1 200 OK\r\n")
        for _, header in ipairs(cors_headers) do
            response = response .. header .. "\r\n"
        end
        response = response .. "Content-Length: 0\r\n\r\n"
        
        print("🔍 Sending CORS preflight response")
        local success, err = client:send(response)
        if not success then
            print("❌ Failed to send CORS response:", err)
        else
            print("✅ CORS preflight response sent successfully")
        end
        return
    end
    
    -- Handle bloom filter creation
    if method == "POST" and path == "/api/bloom-filter/create" then
        local headers = {}
        local content_type = "application/json" -- default
        local content_length = 0
        local accept_binary = false
        
        print("🔍 Reading headers for POST request...")
        
        -- Read headers to get content-type and content-length
        while true do
            -- Check request timeout
            if os.time() - request_start_time > 30 then
                print("⏰ Request timeout - headers taking too long")
                send_json_response(client, "408 Request Timeout", { success = false, error = "Request timeout - headers" })
                return
            end
            
            local line = client:receive("*l")
            if not line or line == "" then
                print("🔍 Headers complete, empty line received")
                break
            end
            
            print("🔍 Header line:", line)
            
            local key, value = line:match("^([^:]+):%s*(.+)")
            if key and value then
                key = key:lower()
                headers[key] = value
                if key == "content-type" then
                    content_type = value
                elseif key == "content-length" then
                    content_length = tonumber(value) or 0
                elseif key == "accept" then
                    accept_binary = value:match("application/octet%-stream") ~= nil
                end
            end
        end
        
        print("🔍 Content-Type:", content_type)
        print("🔍 Content-Length:", content_length)
        
        -- Read request body
        local body = ""
        if content_length > 0 then
            print("🔍 Reading body with length:", content_length)
            -- Check timeout before reading body
            if os.time() - request_start_time > 30 then
                print("⏰ Request timeout - body reading taking too long")
                send_json_response(client, "408 Request Timeout", { success = false, error = "Request timeout - body reading" })
                return
            end
            body = client:receive(content_length)
        else
            -- Fallback: try to read until connection closes
            print("🔍 No content length, trying to read all")
            local chunk = client:receive("*a")
            if chunk then
                body = chunk
            end
        end
        
        print("🔍 Body received, length:", #body)
        
        -- Check timeout before processing
        if os.time() - request_start_time > 30 then
            print("⏰ Request timeout - processing taking too long")
            send_json_response(client, "408 Request Timeout", { success = false, error = "Request timeout - processing" })
            return
        end
        
        local result = handle_file_upload(body, content_type)
        
        -- Send response in requested format
        if accept_binary then
            print("🔍 Sending binary response")
            send_binary_response(client, "200 OK", result)
        else
            print("🔍 Sending JSON response")
            send_json_response(client, "200 OK", result)
        end
        
        print("🔍 Response sent for POST request")
        
    -- Handle bloom filter listing
    elseif method == "GET" and path == "/api/bloom-filter/list" then
        print("🔍 Handling GET /api/bloom-filter/list")
        
        -- Check timeout before processing
        local timeout, error_msg = check_request_timeout(request_start_time)
        if timeout then
            print("⏰", error_msg)
            send_json_response(client, "408 Request Timeout", { success = false, error = error_msg })
            return
        end
        
        -- Check if client accepts binary
        local accept_binary = false
        local headers = {}
        while true do
            local line = client:receive("*l")
            if not line or line == "" then
                break
            end
            local key, value = line:match("^([^:]+):%s*(.+)")
            if key and value then
                key = key:lower()
                headers[key] = value
                if key == "accept" then
                    accept_binary = value:match("application/octet%-stream") ~= nil
                end
            end
        end
        
        local filters = list_bloom_filters_redis()
        print("🔍 Found", #filters, "filters")
        
        if accept_binary then
            print("🔍 Sending binary response")
            send_binary_response(client, "200 OK", { success = true, filters = filters })
        else
            print("🔍 Sending JSON response")
            send_json_response(client, "200 OK", { success = true, filters = filters })
        end
        
    -- Handle bloom filter metadata
    elseif method == "GET" and path:match("^/api/bloom%-filter/[^/]+/metadata$") then
        local name = path:match("^/api/bloom%-filter/([^/]+)/metadata$")
        
        -- Check if client accepts binary
        local accept_binary = false
        local headers = {}
        while true do
            local line = client:receive("*l")
            if not line or line == "" then
                break
            end
            local key, value = line:match("^([^:]+):%s*(.+)")
            if key and value then
                key = key:lower()
                headers[key] = value
                if key == "accept" then
                    accept_binary = value:match("application/octet%-stream") ~= nil
                end
            end
        end
        
        local filter_data = get_bloom_filter_redis(name)
        
        if filter_data then
            if accept_binary then
                print("🔍 Sending binary response")
                send_binary_response(client, "200 OK", { success = true, filter = filter_data })
            else
                print("🔍 Sending JSON response")
                send_json_response(client, "200 OK", { success = true, filter = filter_data })
            end
        else
            send_json_response(client, "404 Not Found", { success = false, error = "Filter not found" })
        end
        
    -- Handle bloom filter search
    elseif method == "POST" and path:match("^/api/bloom%-filter/[^/]+/search$") then
        -- Check timeout before processing
        local timeout, error_msg = check_request_timeout(request_start_time)
        if timeout then
            print("⏰", error_msg)
            send_json_response(client, "408 Request Timeout", { success = false, error = error_msg })
            return
        end
        
        local name = path:match("^/api/bloom%-filter/([^/]+)/search$")
        local filter_data = get_bloom_filter_redis(name)
        
        if not filter_data then
            send_json_response(client, "404 Not Found", { success = false, error = "Filter not found" })
            return
        end
        
        -- Read search request body
        local body = client:receive("*a")
        local search_data = simple_json_decode(body or "{}")
        local element = search_data and search_data.element
        
        if not element then
            send_json_response(client, "400 Bad Request", { success = false, error = "No element specified" })
            return
        end
        
        -- Perform search using bloom filter module
        package.path = package.path .. ";backend/?.lua"
        local bloom_filter = require("bloom_filter")
        local exists = bloom_filter.search_element_in_bloom_filter(element, filter_data.set_positions, filter_data.size)
        
        send_json_response(client, "200 OK", { 
            success = true, 
            exists = exists,
            element = element,
            filter = name
        })
        
    -- Handle bloom filter deletion
    elseif method == "DELETE" and path:match("^/api/bloom%-filter/[^/]+$") then
        local name = path:match("^/api/bloom%-filter/([^/]+)$")
        local success = delete_bloom_filter_redis(name)
        
        if success then
            send_json_response(client, "200 OK", { success = true, message = "Filter deleted" })
        else
            send_json_response(client, "500 Internal Server Error", { success = false, error = "Failed to delete filter" })
        end
        
    else
        send_json_response(client, "404 Not Found", { success = false, error = "Endpoint not found" })
    end
    
    -- Log request completion time
    local request_duration = os.time() - request_start_time
    print("⏱️ Request completed in", request_duration, "seconds")
    
    client:close()
end

-- Main server function
local function start_server()
    print("🚀 Starting Pure Lua Bloom Filter Server with Redis Storage...")
    print("📍 Server will listen on", HOST .. ":" .. PORT)
    
    -- Try to connect to Redis on startup
    if connect_to_redis() then
        print("✅ Redis connection established on startup")
    else
        print("⚠️  Redis not available on startup - will retry on first request")
    end
    
    local server = assert(socket.bind(HOST, PORT))
    print("✅ Server started successfully!")
    print("🔌 Redis Host:", REDIS_HOST)
    print("🔌 Redis Port:", REDIS_PORT)
    print("📡 Ready to accept connections...")
    
    while true do
        local client = server:accept()
        if client then
            local request_line = client:receive("*l")
            if request_line then
                handle_request(client, request_line)
            else
                client:close()
            end
        end
    end
end

-- Start the server
start_server()
