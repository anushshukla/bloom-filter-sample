#!/bin/bash

# Bloom Filter System Demo Script
# This script demonstrates the complete functionality of the bloom filter system

echo "🎯 Bloom Filter System Demo"
echo "=========================="
echo ""

# Check if Redis is running
if ! redis-cli ping &> /dev/null; then
    echo "❌ Redis is not running. Starting Redis..."
    redis-server --daemonize yes
    sleep 2
fi

echo "✅ Redis is running"
echo ""

# Demo 1: Create a bloom filter from file
echo "📁 Demo 1: Creating bloom filter from sample data"
echo "------------------------------------------------"

# Read the sample file content
if [ -f "test_data/sample_words.txt" ]; then
    echo "📖 Reading sample data from test_data/sample_words.txt"
    file_content=$(cat test_data/sample_words.txt | tr '\n' '\n')
    
    # Create bloom filter using Redis EVAL
    echo "🔧 Creating bloom filter 'fruits' with 30 expected elements..."
    result=$(redis-cli --eval backend/redis_scripts/process_file.lua fruits 30 0.01 "$file_content")
    echo "Result: $result"
    echo ""
else
    echo "❌ Sample data file not found"
    exit 1
fi

# Demo 2: Check some elements
echo "🔍 Demo 2: Checking elements in bloom filter"
echo "--------------------------------------------"

echo "Checking 'apple' (should exist):"
redis-cli --eval backend/redis_scripts/check_element.lua fruits apple

echo "Checking 'banana' (should exist):"
redis-cli --eval backend/redis_scripts/check_element.lua fruits banana

echo "Checking 'dragonfruit' (should not exist):"
redis-cli --eval backend/redis_scripts/check_element.lua fruits dragonfruit

echo "Checking 'mango' (should exist):"
redis-cli --eval backend/redis_scripts/check_element.lua fruits mango
echo ""

# Demo 3: Get metadata
echo "📊 Demo 3: Getting bloom filter metadata"
echo "----------------------------------------"

echo "Metadata for 'fruits' filter:"
redis-cli --eval backend/redis_scripts/get_metadata.lua fruits
echo ""

# Demo 4: List all filters
echo "📋 Demo 4: Listing all bloom filters"
echo "------------------------------------"

echo "Available bloom filters:"
redis-cli --eval backend/redis_scripts/list_filters.lua
echo ""

# Demo 5: Create another filter
echo "📁 Demo 5: Creating another bloom filter"
echo "----------------------------------------"

echo "🔧 Creating bloom filter 'colors' with sample data..."
colors_data="red\ngreen\nblue\nyellow\npurple\norange\npink\nbrown\nblack\nwhite"
result=$(redis-cli --eval backend/redis_scripts/process_file.lua colors 15 0.01 "$colors_data")
echo "Result: $result"
echo ""

# Demo 6: Check elements in new filter
echo "🔍 Demo 6: Checking elements in 'colors' filter"
echo "-----------------------------------------------"

echo "Checking 'red' (should exist):"
redis-cli --eval backend/redis_scripts/check_element.lua colors red

echo "Checking 'blue' (should exist):"
redis-cli --eval backend/redis_scripts/check_element.lua colors blue

echo "Checking 'gray' (should not exist):"
redis-cli --eval backend/redis_scripts/check_element.lua colors gray
echo ""

# Demo 7: List all filters again
echo "📋 Demo 7: Listing all bloom filters (updated)"
echo "-----------------------------------------------"

echo "Available bloom filters:"
redis-cli --eval backend/redis_scripts/list_filters.lua
echo ""

# Demo 8: Performance test
echo "⚡ Demo 8: Performance test with larger dataset"
echo "-----------------------------------------------"

echo "🔧 Creating bloom filter 'numbers' with 1000 elements..."
numbers_data=""
for i in {1..1000}; do
    numbers_data="${numbers_data}number_$i\n"
done

start_time=$(date +%s.%N)
result=$(redis-cli --eval backend/redis_scripts/process_file.lua numbers 1000 0.01 "$numbers_data")
end_time=$(date +%s.%N)

echo "Result: $result"
echo "Time taken: $(echo "$end_time - $start_time" | bc) seconds"
echo ""

# Demo 9: Search performance
echo "🔍 Demo 9: Search performance test"
echo "-----------------------------------"

echo "Searching for existing elements (should be fast):"
start_time=$(date +%s.%N)
redis-cli --eval backend/redis_scripts/check_element.lua numbers number_500
end_time=$(date +%s.%N)
echo "Time taken: $(echo "$end_time - $start_time" | bc) seconds"

echo "Searching for non-existing elements (should be fast):"
start_time=$(date +%s.%N)
redis-cli --eval backend/redis_scripts/check_element.lua numbers nonexistent_9999
end_time=$(date +%s.%N)
echo "Time taken: $(echo "$end_time - $start_time" | bc) seconds"
echo ""

# Demo 10: Memory usage
echo "💾 Demo 10: Memory usage information"
echo "------------------------------------"

echo "Redis memory info:"
redis-cli info memory | grep -E "(used_memory|used_memory_peak|used_memory_rss)"
echo ""

echo "Bloom filter keys:"
redis-cli keys "bloom_filter*"
echo ""

# Demo 11: Cleanup
echo "🧹 Demo 11: Cleanup (optional)"
echo "--------------------------------"

read -p "Do you want to clean up the demo filters? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting demo filters..."
    redis-cli --eval backend/redis_scripts/delete_filter.lua fruits
    redis-cli --eval backend/redis_scripts/delete_filter.lua colors
    redis-cli --eval backend/redis_scripts/delete_filter.lua numbers
    echo "✅ Demo filters cleaned up"
else
    echo "Demo filters preserved for further testing"
fi

echo ""
echo "🎉 Demo completed!"
echo ""
echo "🚀 Next steps:"
echo "1. Start the frontend: cd frontend && npm run dev"
echo "2. Open http://localhost:3000 in your browser"
echo "3. Upload the sample file: test_data/sample_words.txt"
echo "4. Create bloom filters and search through the web interface!"
echo ""
echo "🔧 Redis commands used in this demo:"
echo "  - Create filter: redis-cli --eval backend/redis_scripts/process_file.lua filter_name expected_elements false_positive_rate \"file_content\""
echo "  - Check element: redis-cli --eval backend/redis_scripts/check_element.lua filter_name element"
echo "  - List filters: redis-cli --eval backend/redis_scripts/list_filters.lua"
echo "  - Get metadata: redis-cli --eval backend/redis_scripts/get_metadata.lua filter_name"
echo "  - Delete filter: redis-cli --eval backend/redis_scripts/delete_filter.lua filter_name" 