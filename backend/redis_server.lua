-- Redis Server with HTTP API for Bloom Filter Operations
-- This script provides a simple HTTP server interface for bloom filter operations

local http = require "http"
local json = require "cjson"
local redis = require "redis"
local bloom_filter = require "bloom_filter"

-- Configuration
local PORT = 8080
local REDIS_HOST = "localhost"
local REDIS_PORT = 6379

-- Initialize Redis connection
local redis_client = redis.connect(REDIS_HOST, REDIS_PORT)
if not redis_client then
    print("Failed to connect to Redis")
    os.exit(1)
end

-- HTTP request handler
local function handle_request(req)
    local method = req.method
    local path = req.path
    local headers = req.headers
    local body = req.body
    
    -- CORS headers
    local response_headers = {
        ["Access-Control-Allow-Origin"] = "*",
        ["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS",
        ["Access-Control-Allow-Headers"] = "Content-Type",
        ["Content-Type"] = "application/json"
    }
    
    -- Handle preflight requests
    if method == "OPTIONS" then
        return {
            status = 200,
            headers = response_headers,
            body = ""
        }
    end
    
    -- Route handling
    if method == "POST" and path == "/api/bloom-filter/create" then
        -- Create bloom filter from file upload
        local success, data = pcall(json.decode, body)
        if not success then
            return {
                status = 400,
                headers = response_headers,
                body = json.encode({error = "Invalid JSON"})
            }
        end
        
        local filter_name = data.filter_name
        local file_content = data.file_content
        local expected_elements = data.expected_elements
        local false_positive_rate = data.false_positive_rate
        
        if not filter_name or not file_content then
            return {
                status = 400,
                headers = response_headers,
                body = json.encode({error = "Missing required fields"})
            }
        end
        
        local result, err = bloom_filter.process_file_and_create_bloom_filter(
            redis_client, filter_name, file_content, expected_elements, false_positive_rate
        )
        
        if not result then
            return {
                status = 500,
                headers = response_headers,
                body = json.encode({error = err})
            }
        end
        
        return {
            status = 200,
            headers = response_headers,
            body = json.encode(result)
        }
        
    elseif method == "GET" and path == "/api/bloom-filter/list" then
        -- List all bloom filters
        local filters = bloom_filter.list_bloom_filters(redis_client)
        
        return {
            status = 200,
            headers = response_headers,
            body = json.encode({filters = filters})
        }
        
    elseif method == "GET" and path:match("^/api/bloom%-filter/([^/]+)/metadata$") then
        -- Get bloom filter metadata
        local filter_name = path:match("^/api/bloom%-filter/([^/]+)/metadata$")
        local metadata = bloom_filter.get_bloom_filter_metadata(redis_client, filter_name)
        
        if not metadata then
            return {
                status = 404,
                headers = response_headers,
                body = json.encode({error = "Bloom filter not found"})
            }
        end
        
        return {
            status = 200,
            headers = response_headers,
            body = json.encode(metadata)
        }
        
    elseif method == "POST" and path:match("^/api/bloom%-filter/([^/]+)/search$") then
        -- Search for element in bloom filter
        local filter_name = path:match("^/api/bloom%-filter/([^/]+)/search$")
        local success, data = pcall(json.decode, body)
        
        if not success then
            return {
                status = 400,
                headers = response_headers,
                body = json.encode({error = "Invalid JSON"})
            }
        end
        
        local element = data.element
        if not element then
            return {
                status = 400,
                headers = response_headers,
                body = json.encode({error = "Missing element to search"})
            }
        end
        
        local exists = bloom_filter.check_element_in_bloom_filter(redis_client, filter_name, element)
        
        if exists == nil then
            return {
                status = 404,
                headers = response_headers,
                body = json.encode({error = "Bloom filter not found"})
            }
        end
        
        return {
            status = 200,
            headers = response_headers,
            body = json.encode({exists = exists, element = element, filter = filter_name})
        }
        
    elseif method == "DELETE" and path:match("^/api/bloom%-filter/([^/]+)$") then
        -- Delete bloom filter
        local filter_name = path:match("^/api/bloom%-filter/([^/]+)$")
        local success = bloom_filter.delete_bloom_filter(redis_client, filter_name)
        
        if not success then
            return {
                status = 500,
                headers = response_headers,
                body = json.encode({error = "Failed to delete bloom filter"})
            }
        end
        
        return {
            status = 200,
            headers = response_headers,
            body = json.encode({message = "Bloom filter deleted successfully"})
        }
        
    else
        -- 404 Not Found
        return {
            status = 404,
            headers = response_headers,
            body = json.encode({error = "Endpoint not found"})
        }
    end
end

-- Start HTTP server
print("Starting Bloom Filter Redis Server on port " .. PORT)
print("Redis connection: " .. REDIS_HOST .. ":" .. REDIS_PORT)

local server = http.server(PORT, handle_request)
if server then
    print("Server started successfully")
    server:start()
else
    print("Failed to start server")
    os.exit(1)
end 