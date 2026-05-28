# Bloom Filter System - Project Overview

## 🎯 Project Description

A complete system for storing and searching data using Bloom filters with Redis backend and a modern web frontend. The system efficiently handles large datasets by converting them into space-efficient bloom filters while maintaining fast search capabilities.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Storage       │
│   (Web App)     │◄──►│   (Lua Scripts) │◄──►│   (Redis)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Components

1. **Frontend Application** - Modern web interface for file upload and search
2. **Lua Backend Scripts** - Redis EVAL commands for bloom filter operations
3. **Redis Storage** - Efficient bit array storage using Redis SETBIT/GETBIT
4. **Sample Data** - Test files for demonstration

## 📁 Project Structure

```
bloomFilter/
├── README.md                 # Main project documentation
├── PROJECT_OVERVIEW.md       # This file - detailed project overview
├── setup.sh                  # Setup script for dependencies
├── demo.sh                   # Demo script showing system capabilities
│
├── backend/                  # Backend implementation
│   ├── bloom_filter.lua      # Main bloom filter library
│   ├── redis_server.lua      # HTTP server implementation
│   ├── redis_client.lua      # Simple Redis client for testing
│   ├── redis_commands.lua    # All Redis commands in one file
│   └── redis_scripts/        # Individual Redis EVAL scripts
│       ├── create_bloom_filter.lua
│       ├── process_file.lua
│       ├── check_element.lua
│       ├── get_metadata.lua
│       ├── list_filters.lua
│       └── delete_filter.lua
│
├── frontend/                 # Frontend web application
│   ├── index.html            # Main HTML interface
│   ├── styles.css            # Modern CSS styling
│   ├── script.js             # JavaScript functionality
│   └── package.json          # Frontend dependencies
│
└── test_data/                # Sample data for testing
    └── sample_words.txt      # Sample word list (30 unique words)
```

## 🚀 Key Features

### 1. **Efficient Data Storage**
- Converts text/CSV files into space-efficient bloom filters
- Uses Redis bit arrays for optimal memory usage
- Configurable false positive rates and expected element counts

### 2. **Fast Search Operations**
- O(k) search complexity where k is the number of hash functions
- Guaranteed "definitely not found" for non-existent items
- "Might exist" indication for potential matches

### 3. **Modern Web Interface**
- Drag & drop file upload
- Real-time file information display
- Bloom filter management (create, load, delete)
- Interactive search interface
- Responsive design for all devices

### 4. **Redis Integration**
- Direct Redis EVAL commands for maximum performance
- Efficient bit manipulation using SETBIT/GETBIT
- Metadata storage for filter information
- Atomic operations for consistency

## 🔧 Technical Implementation

### Bloom Filter Algorithm
- **Hash Functions**: 3 independent hash functions (DJB2, FNV-1a variants)
- **Bit Array**: Redis bit array for efficient storage
- **Optimal Sizing**: Automatic calculation based on expected elements and false positive rate
- **Formula**: `size = -n * ln(p) / (ln(2)²)` where n=elements, p=false_positive_rate

### Hash Functions Used
1. **Hash1**: DJB2 variant with 33 multiplier
2. **Hash2**: FNV-1a variant with 31 multiplier  
3. **Hash3**: Custom variant with 37 multiplier

### Redis Data Structure
```
bloom_filter_meta:{filter_name} -> Hash containing metadata
bloom_filter:{filter_name} -> Bit array for bloom filter
```

## 📊 Performance Characteristics

### Memory Usage
- **Space Complexity**: O(m) where m is the calculated bit array size
- **Typical Compression**: 10-100x smaller than storing original data
- **Example**: 10,000 words → ~12KB bloom filter vs ~100KB+ original

### Time Complexity
- **Insertion**: O(n × k) where n=elements, k=hash_functions
- **Search**: O(k) constant time regardless of data size
- **Creation**: O(n × k) one-time setup cost

### False Positive Rate
- **Configurable**: 0.1% to 10% (0.001 to 0.1)
- **Default**: 1% (0.01)
- **Trade-off**: Lower rate = larger size, higher accuracy

## 🎮 Usage Examples

### 1. **Command Line (Redis EVAL)**
```bash
# Create bloom filter from file
redis-cli --eval backend/redis_scripts/process_file.lua fruits 30 0.01 "$(cat test_data/sample_words.txt)"

# Check if element exists
redis-cli --eval backend/redis_scripts/check_element.lua fruits apple

# List all filters
redis-cli --eval backend/redis_scripts/list_filters.lua
```

### 2. **Web Interface**
1. Open http://localhost:3000
2. Upload TXT/CSV file
3. Configure bloom filter parameters
4. Create and store filter
5. Load filter and search for items

### 3. **Programmatic Usage**
```lua
-- Load bloom filter library
local bloom_filter = require "bloom_filter"

-- Create filter
local filter = bloom_filter.create_bloom_filter(redis_client, "my_filter", 1000, 0.01)

-- Add elements
local count = bloom_filter.add_elements_to_bloom_filter(redis_client, "my_filter", {"item1", "item2"})

-- Check element
local exists = bloom_filter.check_element_in_bloom_filter(redis_client, "my_filter", "item1")
```

## 🛠️ Setup and Installation

### Prerequisites
- **Redis**: In-memory data structure store
- **Lua**: Scripting language for Redis
- **Node.js**: Frontend development server
- **Modern Browser**: For web interface

### Quick Start
```bash
# 1. Clone repository
git clone <repository-url>
cd bloomFilter

# 2. Run setup script
./setup.sh

# 3. Start frontend
cd frontend && npm run dev

# 4. Run demo (optional)
./demo.sh
```

### Manual Setup
```bash
# Install Redis
brew install redis  # macOS
sudo apt-get install redis-server  # Ubuntu

# Install Lua
brew install lua    # macOS
sudo apt-get install lua5.3  # Ubuntu

# Install Node.js
# Download from https://nodejs.org/

# Start Redis
redis-server

# Install frontend dependencies
cd frontend && npm install

# Start frontend
npm run dev
```

## 🔍 Testing and Validation

### Sample Data
- **sample_words.txt**: 30 unique fruit names
- **Demo Script**: Comprehensive testing of all features
- **Performance Tests**: Large dataset creation and search

### Validation Commands
```bash
# Run complete demo
./demo.sh

# Test individual components
redis-cli --eval backend/redis_scripts/process_file.lua test 10 0.01 "line1\nline2\nline3"
redis-cli --eval backend/redis_scripts/check_element.lua test line1
redis-cli --eval backend/redis_scripts/list_filters.lua
```

## 📈 Use Cases

### 1. **Large Dataset Search**
- Email address validation
- Username availability checking
- URL filtering
- Spam detection

### 2. **Memory-Constrained Environments**
- Embedded systems
- Mobile applications
- High-performance servers
- IoT devices

### 3. **Real-Time Applications**
- Web application filters
- API rate limiting
- Content filtering
- Cache warming

## 🔒 Security Considerations

### Data Privacy
- Bloom filters only store hash values, not original data
- No way to reconstruct original data from filter
- Suitable for sensitive information

### Access Control
- Redis authentication recommended for production
- Network isolation for sensitive deployments
- Rate limiting for public APIs

## 🚀 Future Enhancements

### Planned Features
- **Scalable Bloom Filters**: Automatic resizing
- **Counting Bloom Filters**: Element frequency tracking
- **Distributed Bloom Filters**: Multi-node support
- **Compression**: Further memory optimization

### Performance Improvements
- **Parallel Processing**: Multi-threaded hash computation
- **Memory Mapping**: Direct memory access for large filters
- **Cache Optimization**: Redis memory optimization

## 📚 References and Resources

### Bloom Filter Theory
- [Bloom Filter Wikipedia](https://en.wikipedia.org/wiki/Bloom_filter)
- [Bloom Filter Calculator](https://hur.st/bloomfilter/)
- [Redis Bit Operations](https://redis.io/commands/setbit)

### Implementation Details
- [Redis EVAL Documentation](https://redis.io/commands/eval)
- [Lua Programming Language](https://www.lua.org/)
- [Redis Data Types](https://redis.io/topics/data-types)

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create feature branch
3. Implement changes
4. Add tests
5. Submit pull request

### Code Standards
- **Lua**: Follow Lua style guide
- **JavaScript**: ES6+ with modern practices
- **CSS**: BEM methodology
- **Documentation**: Clear and comprehensive

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues
1. **Redis Connection**: Ensure Redis server is running
2. **Port Conflicts**: Check if ports 3000/8080 are available
3. **File Permissions**: Ensure scripts are executable
4. **Dependencies**: Verify all prerequisites are installed

### Getting Help
- Check the demo script for examples
- Review Redis logs for backend issues
- Check browser console for frontend issues
- Create an issue with detailed error information

---

**Happy Bloom Filtering! 🌸** 