// Bloom Filter Frontend Application - Pure Functions
// Handles file upload, bloom filter management, and search functionality

// Pure utility functions
const utils = {
    // Pure function to format file size
    formatFileSize: (bytes) => {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    // Pure function to generate filter name from filename
    generateFilterName: (filename) => {
        return filename.replace(/\.(txt|csv)$/i, '').replace(/[^a-zA-Z0-9_-]/g, '_');
    },

    // Pure function to count lines in content
    countLines: (content) => {
        return content.split('\n').filter(line => line.trim().length > 0).length;
    },

    // Pure function to calculate expected elements
    calculateExpectedElements: (lineCount) => {
        return Math.max(1000, lineCount * 2);
    },

    // Pure function to validate file
    validateFile: (file) => {
        const errors = [];
        if (!file.name.match(/\.(txt|csv)$/i)) {
            errors.push('Please select a .txt or .csv file');
        }
        if (file.size === 0) {
            errors.push('File is empty');
        }
        if (file.size > 100 * 1024 * 1024) { // 100MB limit
            errors.push('File size too large (max 100MB)');
        }
        return { isValid: errors.length === 0, errors };
    },

    // Pure function to create file info object
    createFileInfo: (file, content) => {
        const lines = utils.countLines(content);
        return {
            name: file.name,
            size: file.size,
            formattedSize: utils.formatFileSize(file.size),
            lines: lines,
            type: file.type || 'text/plain',
            expectedElements: utils.calculateExpectedElements(lines),
            filterName: utils.generateFilterName(file.name)
        };
    },

    // Pure function to create bloom filter request payload
    createBloomFilterPayload: (filterName, fileContent, expectedElements, falsePositiveRate) => {
        return {
            filter_name: filterName,
            file_content: fileContent,
            expected_elements: expectedElements,
            false_positive_rate: falsePositiveRate
        };
    },

    // Pure function to create search request payload
    createSearchPayload: (element) => {
        return { element };
    },

    // Pure function to format timestamp
    formatTimestamp: (timestamp) => {
        return new Date(timestamp * 1000).toLocaleString();
    },

    // Pure function to create status message
    createStatusMessage: (message, type = 'info') => {
        return {
            id: Date.now(),
            message,
            type,
            timestamp: new Date()
        };
    },

    // Pure function to create filter item HTML
    createFilterItemHTML: (filter) => {
        // Debug: Log the filter object to see its structure
        console.log('🔍 Creating filter item HTML for filter:', filter);
        console.log('🔍 Filter properties:', {
            name: filter.name,
            size: filter.size,
            actual_elements: filter.actual_elements,
            expected_elements: filter.expected_elements,
            created_at: filter.created_at
        });
        
        // The backend returns bloom filter data directly
        // Note: metadata endpoint now only sends essential data for search
        const size = filter.size;
        const actualElements = filter.actual_elements || 'N/A';
        const expectedElements = filter.expected_elements || 'N/A';
        const createdAt = filter.created_at || 'N/A';
        
        const html = `
            <div class="filter-item" data-filter-name="${filter.name}">
                <div class="filter-info">
                    <h4>${filter.name}</h4>
                    <p>Size: ${size || 'N/A'} | Elements: ${actualElements !== 'N/A' ? actualElements : (expectedElements !== 'N/A' ? expectedElements : 'N/A')}</p>
                    <p>Created: ${createdAt !== 'N/A' ? utils.formatTimestamp(createdAt) : 'N/A'}</p>
                </div>
                <div class="filter-actions">
                    <button class="btn btn-info btn-sm" onclick="bloomFilterManager.selectFilter('${filter.name}')">
                        <i class="fas fa-check"></i> Select
                    </button>
                    <button class="btn btn-danger btn-sm" onclick="bloomFilterManager.deleteFilter('${filter.name}')">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </div>
            </div>
        `;
        
        console.log('🔍 Generated HTML:', html);
        return html;
    },

    // Pure function to create search result HTML
    createSearchResultHTML: (searchTerm, exists) => {
        const resultClass = exists ? 'found' : 'not-found';
        const resultText = exists ? 'MIGHT EXIST' : 'DEFINITELY NOT FOUND';
        const resultIcon = exists ? 'fa-check-circle' : 'fa-times-circle';
        const explanation = exists ? '(Bloom filter indicates item might exist)' : '(Bloom filter guarantees item does not exist)';
        
        return `
            <div class="search-result ${resultClass}">
                <i class="fas ${resultIcon}"></i>
                <strong>${searchTerm}</strong>: ${resultText}
                <small>${explanation}</small>
            </div>
        `;
    }
};

// Pure API functions
const api = {
    // Pure function to make HTTP request
    makeRequest: async (url, options = {}) => {
        console.log("🌐 makeRequest called with:", { url, options });
        
        const defaultOptions = {
            method: 'GET',
            headers: {
                'Accept': 'application/octet-stream, application/json' // Enable binary with JSON fallback
            },
            mode: 'cors', // Explicitly enable CORS
            credentials: 'omit', // Don't send cookies
            ...options
        };
        
        // Only add Content-Type for non-FormData requests
        if (!(options.body instanceof FormData)) {
            defaultOptions.headers['Content-Type'] = 'application/json';
        }

        console.log("📤 Final request options:", defaultOptions);

        try {
            console.log("🚀 Sending fetch request...");
            console.log("🔍 Request details:", { url, method: defaultOptions.method, headers: defaultOptions.headers });
            
            // Create AbortController for timeout handling
            const controller = new AbortController();
            const timeoutId = setTimeout(() => {
                console.log("⏰ Request timeout - aborting...");
                controller.abort();
            }, 30000); // 30 second timeout (increased back to 30s for debugging)
            
            console.log("🔍 Starting fetch with timeout...");
            const startTime = Date.now();
            
            // Try the request with retry logic
            let response;
            let attempt = 1;
            const maxAttempts = 3;
            
            while (attempt <= maxAttempts) {
                try {
                    console.log(`🔄 Attempt ${attempt}/${maxAttempts}...`);
                    response = await fetch(url, { ...defaultOptions, signal: controller.signal });
                    break; // Success, exit retry loop
                } catch (fetchError) {
                    console.log(`❌ Attempt ${attempt} failed:`, fetchError.message);
                    if (attempt === maxAttempts) throw fetchError;
                    attempt++;
                    // Wait before retry (exponential backoff)
                    await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
                }
            }
            
            const endTime = Date.now();
            clearTimeout(timeoutId); // Clear timeout if request completes
            
            console.log("📥 Response received in", endTime - startTime, "ms:", { status: response.status, statusText: response.statusText });
            
            // Check if response is binary
            const contentType = response.headers.get('content-type');
            console.log("📋 Content-Type:", contentType);
            
            let data;
            
            if (contentType && contentType.includes('application/octet-stream')) {
                // Binary response - decode it
                console.log("🔧 Processing binary response...");
                const binaryData = await response.arrayBuffer();
                console.log("🔧 Binary data received, size:", binaryData.byteLength, "bytes");
                console.log("🔧 Binary data preview:", Array.from(new Uint8Array(binaryData).slice(0, 20)));
                const binaryDecoder = new BinaryDecoder();
                data = binaryDecoder.decodeResponse(binaryData);
            } else {
                // JSON response - parse normally
                console.log("🔧 Processing JSON response...");
                data = await response.json();
            }
            
            console.log("📊 Parsed data:", data);
            
            return {
                success: response.ok,
                data,
                status: response.status,
                statusText: response.statusText
            };
        } catch (error) {
            console.error("❌ Error in makeRequest:", error);
            return {
                success: false,
                error: error.message,
                status: 0,
                statusText: 'Network Error'
            };
        }
    },

    // Pure function to create bloom filter
    createBloomFilter: async (payload) => {
        // Use JSON for now to avoid multipart parsing issues
        return api.makeRequest(`http://localhost:8080/api/bloom-filter/create`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
    },

    // Pure function to list bloom filters
    listBloomFilters: async () => {
        return api.makeRequest(`http://localhost:8080/api/bloom-filter/list`);
    },

    // Pure function to get bloom filter metadata
    getBloomFilterMetadata: async (filterName) => {
        return api.makeRequest(`http://localhost:8080/api/bloom-filter/${filterName}/metadata`);
    },

    // Pure function to search in bloom filter
    searchInBloomFilter: async (filterName, payload) => {
        return api.makeRequest(`http://localhost:8080/api/bloom-filter/${filterName}/search`, {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    },

    // Pure function to delete bloom filter
    deleteBloomFilter: async (filterName) => {
        return api.makeRequest(`http://localhost:8080/api/bloom-filter/${filterName}`, {
            method: 'DELETE'
        });
    }
};

// Pure file processing functions
const fileProcessor = {
    // Pure function to read file content
    readFileContent: (file) => {
        console.log('📖 readFileContent called for file:', file.name);
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                console.log('✅ File read successfully, content length:', e.target.result.length);
                resolve(e.target.result);
            };
            reader.onerror = (error) => {
                console.error('❌ File read error:', error);
                reject(new Error('Failed to read file'));
            };
            console.log('🔄 Starting file read...');
            reader.readAsText(file);
        });
    },

    // Pure function to process file
    processFile: async (file) => {
        console.log('🔍 processFile called with file:', file.name);
        
        const validation = utils.validateFile(file);
        console.log('✅ File validation result:', validation);
        
        if (!validation.isValid) {
            console.error('❌ File validation failed:', validation.errors);
            throw new Error(validation.errors.join(', '));
        }

        console.log('📖 Reading file content...');
        const content = await fileProcessor.readFileContent(file);
        console.log('📄 File content read, length:', content.length);
        
        console.log('🏷️ Creating file info...');
        const fileInfo = utils.createFileInfo(file, content);
        console.log('📊 File info created:', fileInfo);
        
        return fileInfo;
    }
};

// Pure UI state management
const uiState = {
    // Pure function to create initial state
    createInitialState: () => ({
        currentFilter: null,
        selectedFilterName: null,
        uploadedFile: null,
        fileInfo: null,
        filters: [],
        searchResults: []
    }),

    // Pure function to update state
    updateState: (currentState, updates) => ({
        ...currentState,
        ...updates
    }),

    // Pure function to add search result
    addSearchResult: (currentState, searchTerm, exists) => {
        const newResult = utils.createSearchResultHTML(searchTerm, exists);
        return {
            ...currentState,
            searchResults: [newResult, ...currentState.searchResults]
        };
    },

    // Pure function to select filter
    selectFilter: (currentState, filterName) => {
        return {
            ...currentState,
            selectedFilterName: filterName
        };
    },

    // Pure function to load filter
    loadFilter: (currentState, filter) => {
        return {
            ...currentState,
            currentFilter: filter,
            selectedFilterName: filter.name
        };
    },

    // Pure function to clear filter
    clearFilter: (currentState) => {
        return {
            ...currentState,
            currentFilter: null,
            selectedFilterName: null,
            searchResults: []
        };
    }
};

// Pure UI render functions
const uiRenderer = {
    // Pure function to render file info
    renderFileInfo: (fileInfo) => {
        const fileInfoElement = document.getElementById('fileInfo');
        if (fileInfoElement) {
            fileInfoElement.innerHTML = `
                <h4>File Information</h4>
                <p><strong>Name:</strong> ${fileInfo.name}</p>
                <p><strong>Size:</strong> ${fileInfo.formattedSize}</p>
                <p><strong>Lines:</strong> ${fileInfo.lines}</p>
                <p><strong>Type:</strong> ${fileInfo.type}</p>
            `;
        }
    },

    // Pure function to render upload form
    renderUploadForm: (fileInfo) => {
        const uploadForm = document.getElementById('uploadForm');
        if (uploadForm) {
            uploadForm.style.display = 'block';
            
            // Set form values
            document.getElementById('filterName').value = fileInfo.filterName;
            document.getElementById('expectedElements').value = fileInfo.expectedElements;
        }
    },

    // Pure function to render filters list
    renderFiltersList: (filters) => {
        const filtersList = document.getElementById('filtersList');
        if (!filtersList) {
            console.error('❌ filtersList element not found!');
            return;
        }

        console.log('🔍 Rendering filters list with', filters.length, 'filters');
        console.log('🔍 filtersList element:', filtersList);
        
        if (filters.length === 0) {
            console.log('🔍 No filters, showing placeholder');
            filtersList.innerHTML = `
                <div class="loading-placeholder">
                    <i class="fas fa-info-circle"></i>
                    <p>No bloom filters found. Upload a file to create one.</p>
                </div>
            `;
            return;
        }

        console.log('🔍 Rendering', filters.length, 'filters');
        const html = filters.map(filter => utils.createFilterItemHTML(filter)).join('');
        console.log('🔍 Final HTML to insert:', html);
        
        filtersList.innerHTML = html;
        
        console.log('🔍 After setting innerHTML, filtersList contains:', filtersList.innerHTML);
    },

    // Pure function to render current filter info
    renderCurrentFilterInfo: (currentFilter) => {
        const currentFilterInfo = document.getElementById('currentFilterInfo');
        if (!currentFilterInfo) return;

        if (currentFilter) {
            // The FrontendBloomFilter converts snake_case to camelCase properties
            // Note: metadata endpoint now only sends essential data for search
            const size = currentFilter.size;
            const expectedElements = currentFilter.expectedElements || 'N/A';
            const actualElements = currentFilter.actualElements || 'N/A';
            const falsePositiveRate = currentFilter.falsePositiveRate || 'N/A';
            const createdAt = currentFilter.createdAt || 'N/A';
            
            console.log('🎨 Rendering filter info with data:', {
                name: currentFilter.name,
                size,
                expectedElements,
                actualElements,
                falsePositiveRate,
                createdAt
            });
            
            currentFilterInfo.innerHTML = `
                <h4>Current Filter: ${currentFilter.name}</h4>
                <p><strong>Size:</strong> ${size || 'N/A'}</p>
                <p><strong>Expected Elements:</strong> ${expectedElements}</p>
                <p><strong>Actual Elements:</strong> ${actualElements}</p>
                <p><strong>False Positive Rate:</strong> ${falsePositiveRate}</p>
                <p><strong>Created:</strong> ${createdAt !== 'N/A' ? utils.formatTimestamp(createdAt) : 'N/A'}</p>
            `;
        } else {
            currentFilterInfo.innerHTML = '<p>No filter loaded. Please load a bloom filter first.</p>';
        }
    },

    // Pure function to render search form
    renderSearchForm: (show) => {
        const searchForm = document.getElementById('searchForm');
        if (searchForm) {
            searchForm.style.display = show ? 'block' : 'none';
            console.log(`🎨 Search form display set to: ${show ? 'block' : 'none'}`);
            console.log(`🎨 Search form element:`, searchForm);
            console.log(`🎨 Search form computed style:`, window.getComputedStyle(searchForm).display);
        } else {
            console.error('❌ Search form element not found!');
        }
    },

    // Pure function to render search results
    renderSearchResults: (searchResults) => {
        const searchResultsElement = document.getElementById('searchResults');
        if (searchResultsElement) {
            searchResultsElement.innerHTML = searchResults.join('');
        }
    },

    // Pure function to update load button state
    updateLoadButtonState: (enabled) => {
        const loadFilterBtn = document.getElementById('loadFilterBtn');
        if (loadFilterBtn) {
            loadFilterBtn.disabled = !enabled;
        }
    },

    // Pure function to clear search input
    clearSearchInput: () => {
        const searchTermInput = document.getElementById('searchTerm');
        if (searchTermInput) {
            searchTermInput.value = '';
        }
    }
};

// Pure status management
const statusManager = {
    // Pure function to add status message
    addStatusMessage: (message, type = 'info') => {
        const statusMessages = document.getElementById('statusMessages');
        if (!statusMessages) return;

        const statusElement = document.createElement('div');
        statusElement.className = `status-message ${type}`;
        statusElement.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            ${message}
        `;

        statusMessages.appendChild(statusElement);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (statusElement.parentNode) {
                statusElement.parentNode.removeChild(statusElement);
            }
        }, 5000);
    }
};

// Main BloomFilterManager class using pure functions
class BloomFilterManager {
    constructor() {
        console.log('🚀 BloomFilterManager constructor called');
        
        // Initialize state
        this.state = uiState.createInitialState();
        console.log('✅ Initial state created');
        
        // Initialize event listeners
        this.initializeEventListeners();
        console.log('✅ Event listeners initialized');
        
        // Load initial data
        this.loadBloomFilters();
        console.log('✅ Initial bloom filters loaded');
        
        console.log('✅ BloomFilterManager constructor completed');
    }

    // Initialize event listeners
    initializeEventListeners() {
        console.log('🔧 Initializing event listeners...');
        
        // File input change
        const fileInput = document.getElementById('fileInput');
        console.log('📁 File input element:', fileInput);
        
        if (fileInput) {
            // Remove any existing listeners to prevent duplicates
            fileInput.removeEventListener('change', this.handleFileInputChange);
            
            // Create a bound event handler
            this.handleFileInputChange = (e) => {
                console.log('📂 File input change event triggered:', e.target.files[0]);
                if (e.target.files && e.target.files.length > 0) {
                    this.handleFileSelect(e.target.files[0]);
                    // Clear the input value to prevent the same file from triggering again
                    e.target.value = '';
                }
            };
            
            fileInput.addEventListener('change', this.handleFileInputChange);
            console.log('✅ File input change listener added');
        } else {
            console.error('❌ File input element not found!');
        }

        // Drag and drop
        const dropZone = document.getElementById('fileDropZone');
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });

        dropZone.addEventListener('dragleave', () => {
            dropZone.classList.remove('dragover');
        });

        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                this.handleFileSelect(files[0]);
            }
        });

        // Click on drop zone - only trigger file input if no file is currently selected
        dropZone.addEventListener('click', (e) => {
            // Prevent triggering if clicking on child elements
            if (e.target === dropZone) {
                const fileInput = document.getElementById('fileInput');
                if (fileInput && !this.state.uploadedFile) {
                    fileInput.click();
                }
            }
        });
    }

    // Handle file selection using pure functions
    async handleFileSelect(file) {
        console.log('🔍 handleFileSelect called with file:', file);
        if (!file) return;

        try {
            console.log('📁 Processing file:', file.name);
            console.log('📁 File size:', file.size, 'bytes');
            console.log('📁 File type:', file.type);
            
            const fileInfo = await fileProcessor.processFile(file);
            console.log('📊 File info created:', fileInfo);
            
            this.state = uiState.updateState(this.state, {
                uploadedFile: file,
                fileInfo: fileInfo
            });
            console.log('🔄 State updated with file:', this.state.uploadedFile?.name);

            console.log('🎨 Rendering file info...');
            uiRenderer.renderFileInfo(fileInfo);
            console.log('📝 Rendering upload form...');
            uiRenderer.renderUploadForm(fileInfo);
            console.log('✅ File selection completed successfully');
            
        } catch (error) {
            console.error('❌ Error in handleFileSelect:', error);
            statusManager.addStatusMessage('Error reading file: ' + error.message, 'error');
        }
    }

    // Create bloom filter using pure functions
    async createBloomFilter() {
        console.log("🚀 createBloomFilter called");
        
        const filterName = document.getElementById('filterName').value.trim();
        const expectedElements = parseInt(document.getElementById('expectedElements').value);
        const falsePositiveRate = parseFloat(document.getElementById('falsePositiveRate').value);

        console.log("📝 Form data:", { filterName, expectedElements, falsePositiveRate });

        if (!filterName) {
            statusManager.addStatusMessage('Please enter a filter name', 'error');
            return;
        }

        if (!this.state.uploadedFile) {
            statusManager.addStatusMessage('Please select a file first', 'error');
            return;
        }

        try {
            console.log("📤 Starting bloom filter creation...");
            statusManager.addStatusMessage('Creating bloom filter...', 'info');
            
            const content = await fileProcessor.readFileContent(this.state.uploadedFile);
            console.log("📄 File content read:", content.length, "characters");
            
            const payload = utils.createBloomFilterPayload(filterName, content, expectedElements, falsePositiveRate);
            console.log("📦 Payload created:", payload);
            
            console.log("🌐 Making API request...");
            const result = await api.createBloomFilter(payload);
            console.log("📥 API response:", result);
            console.log("📥 Response structure:", {
                success: result.success,
                hasData: !!result.data,
                hasError: !!result.error,
                dataKeys: result.data ? Object.keys(result.data) : 'no data',
                errorKeys: result.error ? Object.keys(result.error) : 'no error'
            });
            
            if (!result.success) {
                // Handle both binary and JSON response formats
                const errorMessage = result.error || result.data?.error || 'Failed to create bloom filter';
                throw new Error(errorMessage);
            }

            // Create frontend Bloom Filter instance for client-side search
            if (result.data.filter) {
                console.log("🔍 Creating frontend filter...");
                const frontendFilter = new FrontendBloomFilter(result.data.filter);
                console.log('🔍 Frontend Bloom Filter created:', frontendFilter);
                
                // Store the filter for later use
                this.state = uiState.updateState(this.state, {
                    currentFilter: frontendFilter,
                    selectedFilterName: filterName
                });
                
                // Show success message and filter info
                statusManager.addStatusMessage(`Bloom filter '${filterName}' created successfully with ${result.data.filter.actual_elements || result.data.elements_processed} elements`, 'success');
                
                // Pass file information for detailed display
                const fileInfo = {
                    name: this.state.uploadedFile.name,
                    size: this.state.uploadedFile.size,
                    type: this.state.uploadedFile.type,
                    contentLength: content.length,
                    expectedElements: expectedElements,
                    falsePositiveRate: falsePositiveRate
                };
                
                this.displayFilterInfo(frontendFilter, fileInfo);
            } else {
                statusManager.addStatusMessage(`Bloom filter '${filterName}' created successfully with ${result.data.elements_processed} elements`, 'success');
            }
            
            this.resetUploadForm();
            this.loadBloomFilters();
            
        } catch (error) {
            console.error("❌ Error in createBloomFilter:", error);
            statusManager.addStatusMessage('Error creating bloom filter: ' + error.message, 'error');
        }
    }
    
    // Display Bloom Filter information and search interface
    displayFilterInfo(filter, fileInfo) {
        const stats = filter.getStats();
        const memory = filter.getMemoryUsage();
        
        // Calculate efficiency metrics
        const originalFileSize = fileInfo ? fileInfo.size : 0;
        const contentLength = fileInfo ? fileInfo.contentLength : 0;
        const bloomFilterSizeBytes = filter.size / 8;
        
        // Get set positions from the correct property (bitArray for frontend filter)
        const setPositions = filter.bitArray ? Array.from(filter.bitArray) : (filter.set_positions || []);
        const setPositionsSize = setPositions.length * 4; // 4 bytes per integer
        
        // Calculate optimized frontend payload size with better compression estimates
        let frontendPayloadSize = 0;
        if (setPositions.length > 0) {
            // Base size: JSON structure overhead
            const jsonOverhead = 50; // bytes for JSON wrapper, quotes, brackets, etc.
            
            // Optimized integer encoding based on value ranges
            let totalIntegerSize = 0;
            for (const pos of setPositions) {
                if (pos < 128) {
                    totalIntegerSize += 1; // 1 byte for small numbers
                } else if (pos < 32768) {
                    totalIntegerSize += 2; // 2 bytes for medium numbers
                } else {
                    totalIntegerSize += 4; // 4 bytes for large numbers
                }
            }
            
            // Add comma separators
            const separatorSize = Math.max(0, setPositions.length - 1);
            
            frontendPayloadSize = jsonOverhead + totalIntegerSize + separatorSize;
        }
        
        const compressionRatio = originalFileSize > 0 ? (bloomFilterSizeBytes / originalFileSize).toFixed(2) : 'N/A';
        const memoryEfficiency = bloomFilterSizeBytes > 0 ? ((setPositionsSize / bloomFilterSizeBytes) * 100).toFixed(2) : 'N/A';
        
        // Calculate additional efficiency metrics
        const sparseStorageRatio = bloomFilterSizeBytes > 0 ? (setPositionsSize / bloomFilterSizeBytes).toFixed(3) : 'N/A';
        const payloadEfficiency = originalFileSize > 0 ? (frontendPayloadSize / originalFileSize).toFixed(3) : 'N/A';
        
        const infoHtml = `
            <div class="filter-info">
                <h3>🔍 Bloom Filter: ${filter.name}</h3>
                
                <!-- Data Flow Funnel -->
                <div class="funnel-container">
                    <h4 class="funnel-title">📊 Data Flow & Size Transformation</h4>
                    <div class="funnel-flow">
                        
                        <!-- Step 1: File Upload -->
                        <div class="funnel-step">
                            <div class="funnel-step-icon upload">
                                <i class="fas fa-upload"></i>
                            </div>
                            <div class="funnel-step-content">
                                <div class="funnel-step-title">📁 File Upload</div>
                                <div class="funnel-step-details">
                                    <div class="funnel-step-detail">
                                        <span class="label">File Size:</span>
                                        <span class="value">${fileInfo ? (fileInfo.size / 1024).toFixed(2) + ' KB' : 'N/A'}</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Content:</span>
                                        <span class="value">${fileInfo ? contentLength + ' chars' : 'N/A'}</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Elements:</span>
                                        <span class="value">${fileInfo ? fileInfo.expectedElements : 'N/A'}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Arrow -->
                        <div class="funnel-arrow"></div>
                        
                        <!-- Step 2: Backend Storage -->
                        <div class="funnel-step">
                            <div class="funnel-step-icon backend">
                                <i class="fas fa-database"></i>
                            </div>
                            <div class="funnel-step-content">
                                <div class="funnel-step-title">💾 Backend Storage (Memory)</div>
                                <div class="funnel-step-details">
                                    <div class="funnel-step-detail">
                                        <span class="label">Full Filter:</span>
                                        <span class="value">${(bloomFilterSizeBytes / 1024).toFixed(2)} KB</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Set Positions:</span>
                                        <span class="value">${setPositions.length} ints</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Actual Storage:</span>
                                        <span class="value">${(setPositionsSize / 1024).toFixed(2)} KB</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Arrow -->
                        <div class="funnel-arrow"></div>
                        
                        <!-- Step 3: Frontend Payload -->
                        <div class="funnel-step">
                            <div class="funnel-step-icon frontend">
                                <i class="fas fa-mobile-alt"></i>
                            </div>
                            <div class="funnel-step-content">
                                <div class="funnel-step-title">📱 Frontend Payload</div>
                                <div class="funnel-step-details">
                                    <div class="funnel-step-detail">
                                        <span class="label">Transfer Size:</span>
                                        <span class="value">~${(frontendPayloadSize / 1024).toFixed(2)} KB</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Data Type:</span>
                                        <span class="value">JSON</span>
                                    </div>
                                    <div class="funnel-step-detail">
                                        <span class="label">Search Ready:</span>
                                        <span class="value">✅ Yes</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Size Comparison Highlights -->
                    <div class="size-highlight">
                        📈 <strong>Size Transformation:</strong> ${fileInfo ? (fileInfo.size / 1024).toFixed(2) : 'N/A'} KB → ${(bloomFilterSizeBytes / 1024).toFixed(2)} KB → ~${(frontendPayloadSize / 1024).toFixed(2)} KB
                    </div>
                    
                    <div class="compression-ratio">
                        🎯 <strong>Storage Efficiency:</strong> Sparse storage: ${sparseStorageRatio}x | <strong>Memory Usage:</strong> ${memoryEfficiency}% | <strong>Payload Ratio:</strong> ${payloadEfficiency}x
                    </div>
                    
                    <!-- Efficiency Improvements -->
                    <div class="efficiency-highlights">
                        <div class="efficiency-item">
                            <span class="efficiency-icon">💾</span>
                            <span class="efficiency-label">Sparse Storage:</span>
                            <span class="efficiency-value">${(setPositionsSize / 1024).toFixed(2)} KB vs ${(bloomFilterSizeBytes / 1024).toFixed(2)} KB (${((setPositionsSize / bloomFilterSizeBytes) * 100).toFixed(1)}%)</span>
                        </div>
                        <div class="efficiency-item">
                            <span class="efficiency-icon">📡</span>
                            <span class="efficiency-label">Network Transfer:</span>
                            <span class="efficiency-value">~${(frontendPayloadSize / 1024).toFixed(2)} KB (${((frontendPayloadSize / setPositionsSize) * 100).toFixed(1)}% of sparse storage)</span>
                        </div>
                    </div>
                </div>
                
                <!-- File Upload Details -->
                <div class="info-section">
                    <h4><i class="fas fa-upload"></i> File Upload Details</h4>
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="label">File Name:</span>
                            <span class="value">${fileInfo ? fileInfo.name : 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">File Size:</span>
                            <span class="value">${fileInfo ? (fileInfo.size / 1024).toFixed(2) + ' KB' : 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Content Length:</span>
                            <span class="value">${fileInfo ? contentLength + ' characters' : 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">File Type:</span>
                            <span class="value">${fileInfo ? fileInfo.type : 'N/A'}</span>
                        </div>
                    </div>
                </div>
                
                <!-- Bloom Filter Configuration -->
                <div class="info-section">
                    <h4><i class="fas fa-cogs"></i> Bloom Filter Configuration</h4>
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="label">Expected Elements:</span>
                            <span class="value">${fileInfo ? fileInfo.expectedElements.toLocaleString() : 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">False Positive Rate:</span>
                            <span class="value">${fileInfo ? (fileInfo.falsePositiveRate * 100).toFixed(2) + '%' : 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Hash Functions:</span>
                            <span class="value">${filter.hashCount || 3}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Calculated Size:</span>
                            <span class="value">${filter.size.toLocaleString()} bits</span>
                        </div>
                    </div>
                </div>
                
                <!-- Memory & Storage Details -->
                <div class="info-section">
                    <h4><i class="fas fa-memory"></i> Memory & Storage Details</h4>
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="label">Full Bloom Filter:</span>
                            <span class="value">${(bloomFilterSizeBytes / 1024).toFixed(2)} KB</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Set Positions:</span>
                            <span class="value">${setPositions.length} integers</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Backend Storage:</span>
                            <span class="value">${(setPositionsSize / 1024).toFixed(2)} KB</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Frontend Payload:</span>
                            <span class="value">~${Math.ceil((setPositionsSize * 1.5) / 1024 * 100) / 100} KB</span>
                        </div>
                    </div>
                </div>
                
                <!-- Efficiency Metrics -->
                <div class="info-section">
                    <h4><i class="fas fa-chart-line"></i> Efficiency Metrics</h4>
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="label">Compression Ratio:</span>
                            <span class="value">${compressionRatio}x</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Memory Efficiency:</span>
                            <span class="value">${memoryEfficiency}%</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Set Bits:</span>
                            <span class="value">${stats.setBits} / ${stats.totalBits}</span>
                        </div>
                        <div class="info-item">
                            <span class="label">Bit Density:</span>
                            <span class="value">${(stats.bitDensity * 100).toFixed(2)}%</span>
                        </div>
                    </div>
                </div>
                
                <!-- Search Interface -->
                <div class="search-section">
                    <h4><i class="fas fa-search"></i> Test Search</h4>
                    <input type="text" id="searchInput" placeholder="Enter element to search" class="search-input">
                    <button onclick="bloomFilterManager.searchElement()" class="search-btn">Search</button>
                    <div id="searchResult" class="search-result"></div>
                </div>
            </div>
        `;
        
        const filterInfoElement = document.getElementById('filterInfo');
        filterInfoElement.innerHTML = infoHtml;
        filterInfoElement.style.display = 'block';
        filterInfoElement.classList.add('show');
    }
    
    // Search element in the current Bloom Filter
    searchElement() {
        const searchInput = document.getElementById('searchInput');
        const searchResult = document.getElementById('searchResult');
        
        if (!this.state.currentFilter) {
            searchResult.innerHTML = '<span class="error">No Bloom Filter loaded</span>';
            return;
        }
        
        const element = searchInput.value.trim();
        if (!element) {
            searchResult.innerHTML = '<span class="warning">Please enter an element to search</span>';
            return;
        }
        
        const exists = this.state.currentFilter.search(element);
        const resultClass = exists ? 'success' : 'info';
        const resultText = exists 
            ? `"${element}" MIGHT exist in the filter (could be a false positive)`
            : `"${element}" definitely does NOT exist in the filter`;
        
        searchResult.innerHTML = `<span class="${resultClass}">${resultText}</span>`;
    }

    // Reset upload form
    resetUploadForm() {
        uiRenderer.renderSearchForm(false);
        document.getElementById('uploadForm').style.display = 'none';
        document.getElementById('fileInput').value = '';
        
        this.state = uiState.updateState(this.state, {
            uploadedFile: null,
            fileInfo: null
        });
        
        document.getElementById('filterName').value = '';
        document.getElementById('expectedElements').value = '10000';
        document.getElementById('falsePositiveRate').value = '0.01';
    }

    // Load available bloom filters using pure functions
    async loadBloomFilters() {
        try {
            const result = await api.listBloomFilters();
            
            if (!result.success) {
                throw new Error('Failed to load bloom filters');
            }

            this.state = uiState.updateState(this.state, {
                filters: result.data.filters || []
            });
            
            uiRenderer.renderFiltersList(this.state.filters);
            
        } catch (error) {
            statusManager.addStatusMessage('Error loading bloom filters: ' + error.message, 'error');
            uiRenderer.renderFiltersList([]);
        }
    }

    // Select a bloom filter using pure functions
    selectFilter(filterName) {
        // Remove previous selection
        document.querySelectorAll('.filter-item').forEach(item => {
            item.classList.remove('selected');
        });
        
        // Select new filter
        const filterItem = document.querySelector(`[data-filter-name="${filterName}"]`);
        if (filterItem) {
            filterItem.classList.add('selected');
        }
        
        this.state = uiState.selectFilter(this.state, filterName);
        uiRenderer.updateLoadButtonState(true);
        
        statusManager.addStatusMessage(`Selected bloom filter: ${filterName}`, 'info');
    }

    // Load selected bloom filter using pure functions
    async loadSelectedFilter() {
        if (!this.state.selectedFilterName) {
            statusManager.addStatusMessage('Please select a bloom filter first', 'error');
            return;
        }

        try {
            const result = await api.getBloomFilterMetadata(this.state.selectedFilterName);
            
            if (!result.success) {
                throw new Error('Failed to load bloom filter metadata');
            }

            // The backend returns bloom filter data under result.data.filter
            const filterData = {
                name: this.state.selectedFilterName,
                ...result.data.filter  // Spread all the properties from the filter object
            };
            
            console.log('🔍 Loaded filter data:', filterData);
            console.log('🔍 Filter properties:', {
                size: filterData.size,
                expected_elements: filterData.expected_elements,
                actual_elements: filterData.actual_elements,
                false_positive_rate: filterData.false_positive_rate,
                created_at: filterData.created_at,
                set_positions: filterData.set_positions,
                hash_count: filterData.hash_count
            });
            console.log('🔍 Set positions length:', filterData.set_positions ? filterData.set_positions.length : 'undefined');
            console.log('🔍 First 10 set positions:', filterData.set_positions ? filterData.set_positions.slice(0, 10) : 'undefined');
            
            // Create a FrontendBloomFilter instance for client-side operations
            const frontendFilter = new FrontendBloomFilter(filterData);
            console.log('🔍 Frontend Bloom Filter created:', frontendFilter);
            
            // Store the FrontendBloomFilter instance in state
            this.state = uiState.loadFilter(this.state, frontendFilter);
            
            // Render the filter info and search form
            uiRenderer.renderCurrentFilterInfo(frontendFilter);
            uiRenderer.renderSearchForm(true);
            
            console.log('🔍 Search form should now be visible');
            console.log('🔍 Current state:', this.state);
            
            // Verify search form is visible
            setTimeout(() => {
                const searchForm = document.getElementById('searchForm');
                if (searchForm) {
                    console.log('🔍 Search form visibility check:');
                    console.log('  - Element:', searchForm);
                    console.log('  - Style display:', searchForm.style.display);
                    console.log('  - Computed display:', window.getComputedStyle(searchForm).display);
                    console.log('  - Is visible:', searchForm.style.display === 'block');
                }
            }, 100);
            
            statusManager.addStatusMessage(`Bloom filter '${this.state.selectedFilterName}' loaded successfully`, 'success');
            
        } catch (error) {
            statusManager.addStatusMessage('Error loading bloom filter: ' + error.message, 'error');
        }
    }

    // Search in bloom filter using client-side FrontendBloomFilter instance
    async searchInBloomFilter() {
        const searchTerm = document.getElementById('searchTerm').value.trim();
        
        if (!searchTerm) {
            statusManager.addStatusMessage('Please enter a search term', 'error');
            return;
        }

        if (!this.state.currentFilter) {
            statusManager.addStatusMessage('Please load a bloom filter first', 'error');
            return;
        }

        try {
            console.log(`🔍 Searching for "${searchTerm}" in client-side bloom filter: ${this.state.currentFilter.name}`);
            
            // Use the client-side bloom filter for instant search (no API call needed)
            const exists = this.state.currentFilter.search(searchTerm);
            
            console.log(`🔍 Search result for "${searchTerm}": ${exists ? 'MIGHT EXIST' : 'DEFINITELY NOT FOUND'}`);
            
            // Add search result to state and render
            this.state = uiState.addSearchResult(this.state, searchTerm, exists);
            uiRenderer.renderSearchResults(this.state.searchResults);
            uiRenderer.clearSearchInput();
            
            // Show success message
            const resultText = exists ? 'MIGHT EXIST' : 'DEFINITELY NOT FOUND';
            statusManager.addStatusMessage(`Search completed: "${searchTerm}" ${resultText}`, 'success');
            
        } catch (error) {
            console.error('❌ Error in client-side search:', error);
            statusManager.addStatusMessage('Error searching: ' + error.message, 'error');
        }
    }

    // Delete bloom filter using pure functions
    async deleteFilter(filterName) {
        if (!confirm(`Are you sure you want to delete the bloom filter '${filterName}'?`)) {
            return;
        }

        try {
            const result = await api.deleteBloomFilter(filterName);
            
            if (!result.success || !result.data.success) {
                throw new Error('Failed to delete bloom filter');
            }

            statusManager.addStatusMessage(`Bloom filter '${filterName}' deleted successfully`, 'success');
            
            // If this was the current filter, clear it
            if (this.state.currentFilter && this.state.currentFilter.name === filterName) {
                this.state = uiState.clearFilter(this.state);
                uiRenderer.renderCurrentFilterInfo(null);
                uiRenderer.renderSearchForm(false);
            }
            
            this.loadBloomFilters();
            
        } catch (error) {
            statusManager.addStatusMessage('Error deleting bloom filter: ' + error.message, 'error');
        }
    }
}

// Initialize application
let bloomFilterManager;
let isInitialized = false;

document.addEventListener('DOMContentLoaded', () => {
    try {
        console.log('🚀 Initializing Bloom Filter Manager...');
        bloomFilterManager = new BloomFilterManager();
        isInitialized = true;
        console.log('✅ Bloom Filter Manager initialized successfully');
        
        // Hide loading placeholders and show ready state
        const loadingPlaceholder = document.querySelector('.loading-placeholder');
        if (loadingPlaceholder) {
            loadingPlaceholder.innerHTML = `
                <i class="fas fa-check-circle"></i>
                <p>System ready! Click "Refresh Filters" to load available bloom filters</p>
            `;
        }
        
        // Add ready status message
        if (statusManager && statusManager.addStatusMessage) {
            statusManager.addStatusMessage('Bloom Filter Manager ready!', 'success');
        }
        
        // Debug: Check if file input element exists
        const fileInput = document.getElementById('fileInput');
        console.log('🔍 File input element found:', fileInput);
        if (fileInput) {
            console.log('✅ File input element exists and is ready');
        } else {
            console.error('❌ File input element NOT FOUND!');
        }
        
    } catch (error) {
        console.error('❌ Failed to initialize Bloom Filter Manager:', error);
        if (statusManager && statusManager.addStatusMessage) {
            statusManager.addStatusMessage('Failed to initialize system: ' + error.message, 'error');
        }
    }
});

// Make functions globally accessible for HTML onclick handlers
window.createBloomFilter = function() {
    console.log('🌐 Global createBloomFilter called');
    console.log('🔍 bloomFilterManager:', bloomFilterManager);
    console.log('🔍 isInitialized:', isInitialized);
    
    if (bloomFilterManager && typeof bloomFilterManager.createBloomFilter === 'function') {
        console.log('✅ Calling bloomFilterManager.createBloomFilter()');
        bloomFilterManager.createBloomFilter();
    } else {
        console.error('❌ bloomFilterManager not ready or createBloomFilter method not found');
        if (statusManager && statusManager.addStatusMessage) {
            statusManager.addStatusMessage('System not ready yet. Please wait a moment and try again.', 'error');
        }
    }
};

window.loadBloomFilters = function() {
    if (bloomFilterManager && typeof bloomFilterManager.loadBloomFilters === 'function') {
        bloomFilterManager.loadBloomFilters();
    } else {
        console.error('❌ bloomFilterManager not ready or loadBloomFilters method not found');
        statusManager.addStatusMessage('System not ready yet. Please wait a moment and try again.', 'error');
    }
};

window.loadSelectedFilter = function() {
    if (bloomFilterManager && typeof bloomFilterManager.loadSelectedFilter === 'function') {
        bloomFilterManager.loadSelectedFilter();
    } else {
        console.error('❌ bloomFilterManager not ready or loadSelectedFilter method not found');
        statusManager.addStatusMessage('System not ready yet. Please wait a moment and try again.', 'error');
    }
};

window.searchInBloomFilter = function() {
    if (bloomFilterManager && typeof bloomFilterManager.searchInBloomFilter === 'function') {
        bloomFilterManager.searchInBloomFilter();
    } else {
        console.error('❌ bloomFilterManager not ready or searchInBloomFilter method not found');
        statusManager.addStatusMessage('System not ready yet. Please wait a moment and try again.', 'error');
    }
}; 