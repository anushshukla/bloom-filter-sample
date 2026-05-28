/**
 * Frontend Bloom Filter Implementation
 * Performs fast client-side searches using Bloom Filter data from backend
 */

class FrontendBloomFilter {
    constructor(bloomFilterData) {
        // Handle both snake_case (backend) and camelCase (frontend) property names
        this.name = bloomFilterData.name;
        this.size = bloomFilterData.size;
        this.hashCount = bloomFilterData.hash_count || bloomFilterData.hashCount;
        this.expectedElements = bloomFilterData.expected_elements || bloomFilterData.expectedElements;
        this.falsePositiveRate = bloomFilterData.false_positive_rate || bloomFilterData.falsePositiveRate;
        this.createdAt = bloomFilterData.created_at || bloomFilterData.createdAt;
        this.actualElements = bloomFilterData.actual_elements || bloomFilterData.actualElements;
        
        // Convert set positions back to sparse bit array for fast lookup
        this.bitArray = new Set(bloomFilterData.set_positions || bloomFilterData.setPositions || []);
        
        // Hash function parameters
        this.hashParams = bloomFilterData.hash_params || bloomFilterData.hashParams || {};
        
        console.log(`🔍 Frontend Bloom Filter initialized: ${this.name} (${this.size} bits, ${this.hashCount} hashes)`);
        console.log(`🔍 Bloom Filter data received:`, bloomFilterData);
        console.log(`🔍 Set positions:`, bloomFilterData.set_positions || bloomFilterData.setPositions || []);
        console.log(`🔍 Bit array created with ${this.bitArray.size} positions`);
        console.log(`🔍 First 10 bit array positions:`, Array.from(this.bitArray).slice(0, 10));
    }
    
    /**
     * Hash function 1 (same as backend)
     */
    hash1(str, size) {
        if (!str || !size || size <= 0) {
            return 1;
        }
        let hash = 5381;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash * 33) + str.charCodeAt(i)) % size;
        }
        return (hash % size) + 1;
    }
    
    /**
     * Hash function 2 (same as backend)
     */
    hash2(str, size) {
        if (!str || !size || size <= 0) {
            return 1;
        }
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash * 31) + str.charCodeAt(i)) % size;
        }
        return (hash % size) + 1;
    }
    
    /**
     * Hash function 3 (same as backend)
     */
    hash3(str, size) {
        if (!str || !size || size <= 0) {
            return 1;
        }
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash * 37) + str.charCodeAt(i)) % size;
        }
        return (hash % size) + 1;
    }
    
    /**
     * Generate hash positions for an element
     */
    generateHashPositions(element) {
        return [
            this.hash1(element, this.size),
            this.hash2(element, this.size),
            this.hash3(element, this.size)
        ];
    }
    
    /**
     * Check if element exists in the Bloom Filter
     */
    search(element) {
        if (!element || typeof element !== 'string' || element.length === 0) {
            return false;
        }
        
        const hashPositions = this.generateHashPositions(element);
        console.log(`🔍 Searching for "${element}" in bloom filter "${this.name}"`);
        console.log(`🔍 Hash positions:`, hashPositions);
        console.log(`🔍 Bit array size:`, this.bitArray.size);
        console.log(`🔍 Bit array contents:`, Array.from(this.bitArray).slice(0, 10), '...');
        
        // Check if all hash positions are set in the bit array
        for (const position of hashPositions) {
            console.log(`🔍 Checking position ${position}: ${this.bitArray.has(position) ? 'SET' : 'NOT SET'}`);
            if (!this.bitArray.has(position)) {
                console.log(`❌ Position ${position} not set, element NOT FOUND`);
                return false;
            }
        }
        
        console.log(`✅ All positions set, element MIGHT EXIST`);
        return true;
    }
    
    /**
     * Get Bloom Filter statistics
     */
    getStats() {
        const setBits = this.bitArray.size;
        const bitDensity = setBits / this.size;
        const falsePositiveProbability = Math.pow(bitDensity, this.hashCount);
        
        return {
            setBits,
            totalBits: this.size,
            bitDensity,
            falsePositiveProbability,
            actualElements: this.actualElements,
            expectedElements: this.expectedElements,
            falsePositiveRate: this.falsePositiveRate
        };
    }
    
    /**
     * Get memory usage estimate
     */
    getMemoryUsage() {
        const bytes = Math.ceil(this.size / 8);
        const kilobytes = bytes / 1024;
        const megabytes = kilobytes / 1024;
        
        return {
            bits: this.size,
            bytes,
            kilobytes,
            megabytes
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FrontendBloomFilter;
} 