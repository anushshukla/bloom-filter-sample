# Bloom Filter with Redis and Frontend - Pure Functions

A complete system for storing and searching data using Bloom filters with Redis backend and a modern web frontend, built with **pure functions** for maximum testability and maintainability.

## 🎯 **Pure Function Architecture**

This system is built using **pure functions** throughout, providing:

- **🔬 Easy Testing**: All core logic can be tested without external dependencies
- **🧩 Modularity**: Functions are composable and reusable
- **📚 Maintainability**: Clear separation of concerns and predictable behavior
- **🚀 Performance**: Optimized algorithms with no side effects
- **🔄 Immutability**: State changes are explicit and traceable

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Storage       │
│   (Pure JS)     │◄──►│   (Pure Lua)    │◄──►│   (Redis)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Pure Function Components**

1. **Core Bloom Filter Logic** - Pure mathematical operations
2. **Data Processing** - Pure file parsing and validation
3. **State Management** - Immutable state updates
4. **UI Rendering** - Pure rendering functions
5. **API Layer** - Pure HTTP request handling
6. **Redis Adapter** - Pure data conversion functions

## 🚀 Key Features

### **Pure Bloom Filter Operations**
- **Hash Functions**: 3 independent, deterministic hash functions
- **Parameter Calculation**: Optimal size and hash count computation
- **Bit Array Generation**: Pure bit manipulation logic
- **Element Search**: O(k) search complexity with pure functions
- **Statistics Calculation**: Memory usage and performance metrics

### **Pure Data Processing**
- **File Validation**: Pure validation without side effects
- **Content Parsing**: Line-by-line processing with pure functions
- **Data Transformation**: Immutable data structures
- **Error Handling**: Pure error validation and reporting

### **Pure Frontend Architecture**
- **State Management**: Immutable state updates using pure functions
- **UI Rendering**: Pure rendering functions for all components
- **Event Handling**: Pure event processing and state transitions
- **API Communication**: Pure HTTP request/response handling

## 📁 Project Structure

```
bloomFilter/
├── README.md                 # This file
├── PROJECT_OVERVIEW.md       # Detailed technical overview
├── setup.sh                  # Automated setup script
├── demo.sh                   # Comprehensive demo
│
├── backend/                  # Pure Lua backend
│   ├── bloom_filter.lua      # Pure bloom filter library
│   ├── redis_adapter.lua     # Pure Redis operations
│   ├── test_pure_functions.lua # Pure function tests
│   └── redis_scripts/        # Redis EVAL scripts
│       ├── process_file.lua  # Pure file processing
│       ├── check_element.lua # Pure element checking
│       └── ...               # Other pure operations
│
├── frontend/                 # Pure JavaScript frontend
│   ├── index.html            # HTML interface
│   ├── styles.css            # CSS styling
│   ├── script.js             # Pure function implementation
│   └── package.json          # Dependencies
│
└── test_data/                # Sample data
    └── sample_words.txt      # Test word list
```

## 🔧 **Pure Function Benefits**

### **1. Testability**
```lua
-- Test pure functions without Redis
local bloom_filter = require "bloom_filter"
local filter = bloom_filter.create_bloom_filter_from_file("test", "line1\nline2", 10, 0.01)
local exists = bloom_filter.search_element_in_bloom_filter("line1", filter.bit_array, filter.metadata.size)
assert(exists == true)
```

### **2. Composability**
```lua
-- Compose pure functions
local elements = bloom_filter.parse_file_content(file_content)
local metadata = bloom_filter.create_bloom_filter_metadata(name, #elements, 0.01)
local bit_array = bloom_filter.generate_bloom_filter_bit_array(elements, metadata.size)
```

### **3. Predictability**
```lua
-- Same input always produces same output
local hash1 = bloom_filter.hash1("test", 100)
local hash2 = bloom_filter.hash1("test", 100)
assert(hash1 == hash2) -- Always true
```

### **4. Performance**
```lua
-- Pure functions can be optimized and cached
local size, hash_count = bloom_filter.calculate_bloom_filter_params(1000, 0.01)
-- No side effects, can be memoized
```

## 🛠️ Setup and Installation

### **Quick Start**
```bash
# 1. Clone and setup
git clone <repository-url>
cd bloomFilter
./setup.sh

# 2. Start frontend
cd frontend && npm run dev

# 3. Run pure function tests
lua backend/test_pure_functions.lua

# 4. Run demo
./demo.sh
```

### **Prerequisites**
- **Redis**: In-memory data store
- **Lua**: Scripting language
- **Node.js**: Frontend development
- **Modern Browser**: Web interface

## 🧪 **Testing Pure Functions**

### **Run All Tests**
```bash
lua backend/test_pure_functions.lua
```

### **Test Individual Components**
```lua
local tests = require "test_pure_functions"
tests.test_hash_functions()
tests.test_parameter_calculation()
tests.test_file_parsing()
```

### **Test Coverage**
- ✅ Hash function consistency
- ✅ Parameter calculation accuracy
- ✅ File parsing correctness
- ✅ Bloom filter creation
- ✅ Element search functionality
- ✅ Validation logic
- ✅ Statistics calculation
- ✅ Memory estimation
- ✅ Filter comparison

## 📊 **Performance Characteristics**

### **Pure Function Performance**
- **Hash Generation**: O(n) where n is string length
- **Parameter Calculation**: O(1) mathematical operations
- **File Parsing**: O(n) where n is file size
- **Bit Array Generation**: O(n × k) where n=elements, k=hash_functions
- **Element Search**: O(k) constant time search

### **Memory Efficiency**
- **Pure Data Structures**: No unnecessary object creation
- **Immutable Updates**: Efficient state transitions
- **Optimized Algorithms**: Minimal memory footprint
- **Redis Integration**: Efficient bit array storage

## 🎮 **Usage Examples**

### **Pure Function Usage**
```lua
-- Create bloom filter purely
local filter = bloom_filter.create_bloom_filter_from_file(
    "my_filter", 
    "item1\nitem2\nitem3", 
    100, 
    0.01
)

-- Search elements purely
local exists = bloom_filter.search_element_in_bloom_filter(
    "item1", 
    filter.bit_array, 
    filter.metadata.size
)

-- Calculate statistics purely
local stats = bloom_filter.calculate_bloom_filter_stats(
    filter.bit_array, 
    filter.metadata
)
```

### **Redis Integration**
```bash
# Use pure functions with Redis
redis-cli --eval backend/redis_scripts/process_file.lua filter_name 100 0.01 "line1\nline2"
redis-cli --eval backend/redis_scripts/check_element.lua filter_name "line1"
```

### **Web Interface**
1. Open http://localhost:3000
2. Upload TXT/CSV file
3. Create bloom filter using pure functions
4. Search elements with pure logic
5. View results and statistics

## 🔒 **Security and Reliability**

### **Pure Function Security**
- **No Side Effects**: Functions cannot modify external state
- **Deterministic**: Same input always produces same output
- **Immutable Data**: Data cannot be accidentally modified
- **Predictable Behavior**: No hidden dependencies or state

### **Error Handling**
- **Pure Validation**: Input validation without side effects
- **Error Propagation**: Clean error handling through pure functions
- **Graceful Degradation**: System continues working with invalid inputs
- **Comprehensive Logging**: Pure error reporting and logging

## 🚀 **Future Enhancements**

### **Pure Function Extensions**
- **Memoization**: Cache pure function results for performance
- **Parallel Processing**: Pure functions can be parallelized safely
- **Streaming**: Pure functions for large data processing
- **Machine Learning**: Pure functions for adaptive bloom filters

### **Performance Improvements**
- **SIMD Operations**: Vectorized pure function implementations
- **Memory Pooling**: Efficient memory management for pure functions
- **Lazy Evaluation**: Pure functions with lazy computation
- **Compilation**: Compile pure functions to native code

## 📚 **References and Resources**

### **Pure Function Theory**
- [Functional Programming Principles](https://en.wikipedia.org/wiki/Functional_programming)
- [Pure Functions in JavaScript](https://www.freecodecamp.org/news/pure-function-vs-impure-function/)
- [Lua Functional Programming](https://lua-users.org/wiki/FunctionalProgramming)

### **Bloom Filter Implementation**
- [Bloom Filter Wikipedia](https://en.wikipedia.org/wiki/Bloom_filter)
- [Redis Bit Operations](https://redis.io/commands/setbit)
- [Lua Programming Language](https://www.lua.org/)

## 🤝 **Contributing**

### **Pure Function Guidelines**
1. **No Side Effects**: Functions should not modify external state
2. **Deterministic**: Same input should always produce same output
3. **Immutable Data**: Use immutable data structures
4. **Composable**: Functions should be easily composable
5. **Testable**: All functions should be testable in isolation

### **Development Setup**
```bash
# Test pure functions
lua backend/test_pure_functions.lua

# Run frontend tests
cd frontend && npm test

# Validate Redis scripts
redis-cli --eval backend/redis_scripts/process_file.lua test 10 0.01 "test"
```

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 **Support**

### **Pure Function Issues**
- **Test Failures**: Run `lua backend/test_pure_functions.lua`
- **Performance**: Profile pure function execution
- **Memory**: Check pure function memory usage
- **Logic Errors**: Validate pure function inputs/outputs

### **Getting Help**
- Check test results for pure function validation
- Review pure function documentation
- Test individual pure functions in isolation
- Create issues with pure function test cases

---

**🎉 Pure Functions for Pure Performance! 🌸**

*This system demonstrates how pure functions can create robust, testable, and maintainable software while maintaining high performance and reliability.*
