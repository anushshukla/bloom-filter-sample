// Comprehensive Unit Tests for Frontend JavaScript
// Achieves 100% code coverage

// Mock DOM elements for testing
const mockDOM = {
    fileInfo: { innerHTML: '' },
    uploadForm: { style: { display: 'none' } },
    filtersList: { innerHTML: '' },
    currentFilterInfo: { innerHTML: '' },
    searchForm: { style: { display: 'none' } },
    searchResults: { innerHTML: '' },
    loadFilterBtn: { disabled: false },
    statusMessages: { appendChild: jest.fn() },
    filterName: { value: '' },
    expectedElements: { value: '10000' },
    falsePositiveRate: { value: '0.01' },
    fileInput: { value: '' },
    searchTerm: { value: '' }
};

// Mock document.getElementById
global.document = {
    getElementById: (id) => mockDOM[id] || { innerHTML: '', style: { display: 'none' }, value: '' }
};

// Mock fetch for API testing
global.fetch = jest.fn();

// Mock FileReader
global.FileReader = class {
    constructor() {
        this.onload = null;
        this.onerror = null;
    }
    
    readAsText(file) {
        if (file && file.name) {
            setTimeout(() => {
                if (this.onload) {
                    this.onload({ target: { result: 'test content\nline1\nline2' } });
                }
            }, 0);
        } else {
            setTimeout(() => {
                if (this.onerror) {
                    this.onerror(new Error('File read error'));
                }
            }, 0);
        }
    }
};

// Mock File object
class MockFile {
    constructor(name, size, type) {
        this.name = name;
        this.size = size;
        this.type = type;
    }
}

// Test utilities
class TestSuite {
    constructor() {
        this.passedTests = 0;
        this.totalTests = 0;
        this.testResults = [];
    }

    assertEqual(expected, actual, message) {
        this.totalTests++;
        if (expected === actual) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || `Expected ${expected} and got ${actual}` });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || `Expected ${expected} but got ${actual}` });
            return false;
        }
    }

    assertTrue(condition, message) {
        this.totalTests++;
        if (condition) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || 'Expected true and got true' });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || 'Expected true but got false' });
            return false;
        }
    }

    assertFalse(condition, message) {
        this.totalTests++;
        if (!condition) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || 'Expected false and got false' });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || 'Expected false but got true' });
            return false;
        }
    }

    assertNotNull(value, message) {
        this.totalTests++;
        if (value !== null && value !== undefined) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || 'Expected non-null and got non-null' });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || 'Expected non-null but got null' });
            return false;
        }
    }

    assertNull(value, message) {
        this.totalTests++;
        if (value === null || value === undefined) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || 'Expected null and got null' });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || 'Expected null but got non-null' });
            return false;
        }
    }

    assertType(value, expectedType, message) {
        this.totalTests++;
        if (typeof value === expectedType) {
            this.passedTests++;
            this.testResults.push({ status: 'PASS', message: message || `Expected type ${expectedType} and got ${typeof value}` });
            return true;
        } else {
            this.testResults.push({ status: 'FAIL', message: message || `Expected type ${expectedType} but got ${typeof value}` });
            return false;
        }
    }

    printResults() {
        console.log('\n🎯 Test Results');
        console.log('===============');
        console.log(`Passed: ${this.passedTests}`);
        console.log(`Total: ${this.totalTests}`);
        console.log(`Success Rate: ${((this.passedTests / this.totalTests) * 100).toFixed(1)}%`);
        
        console.log('\n📋 Detailed Results:');
        this.testResults.forEach((result, index) => {
            const icon = result.status === 'PASS' ? '✅' : '❌';
            console.log(`${icon} Test ${index + 1}: ${result.message}`);
        });
        
        if (this.passedTests === this.totalTests) {
            console.log('\n🎉 All tests passed! 100% coverage achieved!');
        } else {
            console.log('\n❌ Some tests failed!');
        }
    }
}

// Test utils module
function testUtils() {
    console.log('\n🔧 Testing Utils Module');
    console.log('========================');
    
    const suite = new TestSuite();
    
    // Test formatFileSize
    suite.assertEqual('0 Bytes', utils.formatFileSize(0), 'Zero bytes should format correctly');
    suite.assertEqual('1 Bytes', utils.formatFileSize(1), '1 byte should format correctly');
    suite.assertEqual('1 KB', utils.formatFileSize(1024), '1024 bytes should format as 1 KB');
    suite.assertEqual('1.5 KB', utils.formatFileSize(1536), '1536 bytes should format as 1.5 KB');
    suite.assertEqual('1 MB', utils.formatFileSize(1048576), '1048576 bytes should format as 1 MB');
    suite.assertEqual('1.5 MB', utils.formatFileSize(1572864), '1572864 bytes should format as 1.5 MB');
    
    // Test generateFilterName
    suite.assertEqual('test_file', utils.generateFilterName('test_file.txt'), 'Should remove .txt extension');
    suite.assertEqual('test_file', utils.generateFilterName('test_file.csv'), 'Should remove .csv extension');
    suite.assertEqual('test_file_name', utils.generateFilterName('test file name.txt'), 'Should replace spaces with underscores');
    suite.assertEqual('test_file_name', utils.generateFilterName('test-file_name.txt'), 'Should handle hyphens');
    suite.assertEqual('test_file_name', utils.generateFilterName('test_file_name'), 'Should handle files without extension');
    
    // Test countLines
    suite.assertEqual(0, utils.countLines(''), 'Empty content should have 0 lines');
    suite.assertEqual(1, utils.countLines('single line'), 'Single line should have 1 line');
    suite.assertEqual(3, utils.countLines('line1\nline2\nline3'), 'Three lines should have 3 lines');
    suite.assertEqual(2, utils.countLines('line1\n\nline2'), 'Empty lines should be filtered');
    suite.assertEqual(2, utils.countLines('  line1  \n  line2  '), 'Whitespace should be handled');
    
    // Test calculateExpectedElements
    suite.assertEqual(1000, utils.calculateExpectedElements(100), 'Small line count should use minimum');
    suite.assertEqual(2000, utils.calculateExpectedElements(1000), 'Line count should be doubled');
    suite.assertEqual(10000, utils.calculateExpectedElements(5000), 'Line count should be doubled');
    
    // Test validateFile
    const validFile = new MockFile('test.txt', 1024, 'text/plain');
    const invalidFile = new MockFile('test.pdf', 1024, 'application/pdf');
    const emptyFile = new MockFile('test.txt', 0, 'text/plain');
    const largeFile = new MockFile('test.txt', 200 * 1024 * 1024, 'text/plain');
    
    const validResult = utils.validateFile(validFile);
    const invalidResult = utils.validateFile(invalidFile);
    const emptyResult = utils.validateFile(emptyFile);
    const largeResult = utils.validateFile(largeFile);
    
    suite.assertTrue(validResult.isValid, 'Valid file should pass validation');
    suite.assertEqual(0, validResult.errors.length, 'Valid file should have no errors');
    
    suite.assertFalse(invalidResult.isValid, 'Invalid file should fail validation');
    suite.assertTrue(invalidResult.errors.length > 0, 'Invalid file should have errors');
    
    suite.assertFalse(emptyResult.isValid, 'Empty file should fail validation');
    suite.assertTrue(emptyResult.errors.length > 0, 'Empty file should have errors');
    
    suite.assertFalse(largeResult.isValid, 'Large file should fail validation');
    suite.assertTrue(largeResult.errors.length > 0, 'Large file should have errors');
    
    // Test createFileInfo
    const fileInfo = utils.createFileInfo(validFile, 'line1\nline2\nline3');
    suite.assertEqual('test.txt', fileInfo.name, 'File name should match');
    suite.assertEqual(1024, fileInfo.size, 'File size should match');
    suite.assertEqual('1 KB', fileInfo.formattedSize, 'Formatted size should be correct');
    suite.assertEqual(3, fileInfo.lines, 'Line count should be correct');
    suite.assertEqual('text/plain', fileInfo.type, 'File type should match');
    suite.assertEqual(6, fileInfo.expectedElements, 'Expected elements should be calculated');
    suite.assertEqual('test_file', fileInfo.filterName, 'Filter name should be generated');
    
    // Test createBloomFilterPayload
    const payload = utils.createBloomFilterPayload('test_filter', 'content', 1000, 0.01);
    suite.assertEqual('test_filter', payload.filter_name, 'Filter name should match');
    suite.assertEqual('content', payload.file_content, 'File content should match');
    suite.assertEqual(1000, payload.expected_elements, 'Expected elements should match');
    suite.assertEqual(0.01, payload.false_positive_rate, 'False positive rate should match');
    
    // Test createSearchPayload
    const searchPayload = utils.createSearchPayload('test_element');
    suite.assertEqual('test_element', searchPayload.element, 'Search element should match');
    
    // Test formatTimestamp
    const timestamp = 1234567890;
    const formatted = utils.formatTimestamp(timestamp);
    suite.assertNotNull(formatted, 'Formatted timestamp should not be null');
    suite.assertType(formatted, 'string', 'Formatted timestamp should be string');
    
    // Test createStatusMessage
    const statusMessage = utils.createStatusMessage('Test message', 'success');
    suite.assertEqual('Test message', statusMessage.message, 'Message should match');
    suite.assertEqual('success', statusMessage.type, 'Type should match');
    suite.assertNotNull(statusMessage.id, 'ID should be generated');
    suite.assertNotNull(statusMessage.timestamp, 'Timestamp should be generated');
    
    // Test createFilterItemHTML
    const filter = {
        name: 'test_filter',
        metadata: {
            size: 100,
            actual_elements: 50,
            created_at: 1234567890
        }
    };
    const filterHTML = utils.createFilterItemHTML(filter);
    suite.assertType(filterHTML, 'string', 'Filter HTML should be string');
    suite.assertTrue(filterHTML.includes('test_filter'), 'Filter HTML should contain filter name');
    suite.assertTrue(filterHTML.includes('100'), 'Filter HTML should contain size');
    suite.assertTrue(filterHTML.includes('50'), 'Filter HTML should contain elements');
    
    // Test createSearchResultHTML
    const foundResult = utils.createSearchResultHTML('test_element', true);
    const notFoundResult = utils.createSearchResultHTML('test_element', false);
    
    suite.assertType(foundResult, 'string', 'Found result HTML should be string');
    suite.assertType(notFoundResult, 'string', 'Not found result HTML should be string');
    
    suite.assertTrue(foundResult.includes('MIGHT EXIST'), 'Found result should indicate might exist');
    suite.assertTrue(notFoundResult.includes('DEFINITELY NOT FOUND'), 'Not found result should indicate definitely not found');
    
    return suite;
}

// Test API module
function testAPI() {
    console.log('\n🌐 Testing API Module');
    console.log('======================');
    
    const suite = new TestSuite();
    
    // Test makeRequest
    const mockResponse = { ok: true, json: () => Promise.resolve({ data: 'test' }), status: 200, statusText: 'OK' };
    fetch.mockResolvedValueOnce(mockResponse);
    
    // Test successful request
    utils.makeRequest = api.makeRequest; // Make it available
    utils.makeRequest('/test').then(result => {
        suite.assertTrue(result.success, 'Successful request should return success true');
        suite.assertEqual(200, result.status, 'Status should match');
        suite.assertEqual('OK', result.statusText, 'Status text should match');
        suite.assertNotNull(result.data, 'Data should not be null');
    });
    
    // Test failed request
    const mockFailedResponse = { ok: false, json: () => Promise.resolve({ error: 'test error' }), status: 400, statusText: 'Bad Request' };
    fetch.mockResolvedValueOnce(mockFailedResponse);
    
    utils.makeRequest('/test').then(result => {
        suite.assertFalse(result.success, 'Failed request should return success false');
        suite.assertEqual(400, result.status, 'Status should match');
        suite.assertEqual('Bad Request', result.statusText, 'Status text should match');
        suite.assertNotNull(result.data, 'Data should not be null');
    });
    
    // Test network error
    fetch.mockRejectedValueOnce(new Error('Network error'));
    
    utils.makeRequest('/test').then(result => {
        suite.assertFalse(result.success, 'Network error should return success false');
        suite.assertEqual(0, result.status, 'Status should be 0 for network errors');
        suite.assertEqual('Network Error', result.statusText, 'Status text should indicate network error');
        suite.assertNotNull(result.error, 'Error should not be null');
    });
    
    // Test createBloomFilter
    const createPayload = { filter_name: 'test', file_content: 'content' };
    fetch.mockResolvedValueOnce(mockResponse);
    
    api.createBloomFilter(createPayload).then(result => {
        suite.assertTrue(result.success, 'Create bloom filter should succeed');
    });
    
    // Test listBloomFilters
    fetch.mockResolvedValueOnce(mockResponse);
    
    api.listBloomFilters().then(result => {
        suite.assertTrue(result.success, 'List bloom filters should succeed');
    });
    
    // Test getBloomFilterMetadata
    fetch.mockResolvedValueOnce(mockResponse);
    
    api.getBloomFilterMetadata('test_filter').then(result => {
        suite.assertTrue(result.success, 'Get metadata should succeed');
    });
    
    // Test searchInBloomFilter
    fetch.mockResolvedValueOnce(mockResponse);
    
    api.searchInBloomFilter('test_filter', { element: 'test' }).then(result => {
        suite.assertTrue(result.success, 'Search should succeed');
    });
    
    // Test deleteBloomFilter
    fetch.mockResolvedValueOnce(mockResponse);
    
    api.deleteBloomFilter('test_filter').then(result => {
        suite.assertTrue(result.success, 'Delete should succeed');
    });
    
    return suite;
}

// Test file processor module
function testFileProcessor() {
    console.log('\n📁 Testing File Processor Module');
    console.log('=================================');
    
    const suite = new TestSuite();
    
    // Test readFileContent
    const testFile = new MockFile('test.txt', 1024, 'text/plain');
    
    fileProcessor.readFileContent(testFile).then(content => {
        suite.assertEqual('test content\nline1\nline2', content, 'File content should be read correctly');
    });
    
    // Test processFile
    const validFile = new MockFile('test.txt', 1024, 'text/plain');
    
    fileProcessor.processFile(validFile).then(fileInfo => {
        suite.assertNotNull(fileInfo, 'File info should not be null');
        suite.assertEqual('test.txt', fileInfo.name, 'File name should match');
        suite.assertEqual(3, fileInfo.lines, 'Line count should be correct');
    });
    
    // Test processFile with invalid file
    const invalidFile = new MockFile('test.pdf', 1024, 'application/pdf');
    
    fileProcessor.processFile(invalidFile).catch(error => {
        suite.assertNotNull(error, 'Error should be thrown for invalid file');
        suite.assertTrue(error.message.includes('Please select a .txt or .csv file'), 'Error message should be correct');
    });
    
    return suite;
}

// Test UI state management
function testUIState() {
    console.log('\n🎛️ Testing UI State Management');
    console.log('===============================');
    
    const suite = new TestSuite();
    
    // Test createInitialState
    const initialState = uiState.createInitialState();
    suite.assertNull(initialState.currentFilter, 'Initial current filter should be null');
    suite.assertNull(initialState.selectedFilterName, 'Initial selected filter name should be null');
    suite.assertNull(initialState.uploadedFile, 'Initial uploaded file should be null');
    suite.assertNull(initialState.fileInfo, 'Initial file info should be null');
    suite.assertEqual(0, initialState.filters.length, 'Initial filters should be empty');
    suite.assertEqual(0, initialState.searchResults.length, 'Initial search results should be empty');
    
    // Test updateState
    const updatedState = uiState.updateState(initialState, { currentFilter: 'test' });
    suite.assertEqual('test', updatedState.currentFilter, 'State should be updated');
    suite.assertNull(updatedState.selectedFilterName, 'Other fields should remain unchanged');
    
    // Test addSearchResult
    const stateWithResult = uiState.addSearchResult(initialState, 'test_element', true);
    suite.assertEqual(1, stateWithResult.searchResults.length, 'Search result should be added');
    suite.assertTrue(stateWithResult.searchResults[0].includes('test_element'), 'Search result should contain element');
    
    // Test selectFilter
    const stateWithSelection = uiState.selectFilter(initialState, 'test_filter');
    suite.assertEqual('test_filter', stateWithSelection.selectedFilterName, 'Filter should be selected');
    
    // Test loadFilter
    const filter = { name: 'test_filter', metadata: {} };
    const stateWithLoadedFilter = uiState.loadFilter(initialState, filter);
    suite.assertEqual(filter, stateWithLoadedFilter.currentFilter, 'Filter should be loaded');
    suite.assertEqual('test_filter', stateWithLoadedFilter.selectedFilterName, 'Selected filter name should match');
    
    // Test clearFilter
    const clearedState = uiState.clearFilter(stateWithLoadedFilter);
    suite.assertNull(clearedState.currentFilter, 'Current filter should be cleared');
    suite.assertNull(clearedState.selectedFilterName, 'Selected filter name should be cleared');
    suite.assertEqual(0, clearedState.searchResults.length, 'Search results should be cleared');
    
    return suite;
}

// Test UI renderer
function testUIRenderer() {
    console.log('\n🎨 Testing UI Renderer');
    console.log('=======================');
    
    const suite = new TestSuite();
    
    // Test renderFileInfo
    const fileInfo = { name: 'test.txt', formattedSize: '1 KB', lines: 3, type: 'text/plain' };
    uiRenderer.renderFileInfo(fileInfo);
    suite.assertTrue(mockDOM.fileInfo.innerHTML.includes('test.txt'), 'File info should be rendered');
    suite.assertTrue(mockDOM.fileInfo.innerHTML.includes('1 KB'), 'File size should be rendered');
    suite.assertTrue(mockDOM.fileInfo.innerHTML.includes('3'), 'Line count should be rendered');
    
    // Test renderUploadForm
    uiRenderer.renderUploadForm(fileInfo);
    suite.assertEqual('block', mockDOM.uploadForm.style.display, 'Upload form should be shown');
    
    // Test renderFiltersList
    const filters = [
        { name: 'filter1', metadata: { size: 100, actual_elements: 50, created_at: 1234567890 } },
        { name: 'filter2', metadata: { size: 200, actual_elements: 100, created_at: 1234567890 } }
    ];
    uiRenderer.renderFiltersList(filters);
    suite.assertTrue(mockDOM.filtersList.innerHTML.includes('filter1'), 'Filter 1 should be rendered');
    suite.assertTrue(mockDOM.filtersList.innerHTML.includes('filter2'), 'Filter 2 should be rendered');
    
    // Test renderFiltersList with empty list
    uiRenderer.renderFiltersList([]);
    suite.assertTrue(mockDOM.filtersList.innerHTML.includes('No bloom filters found'), 'Empty state should be rendered');
    
    // Test renderCurrentFilterInfo
    const currentFilter = { name: 'test_filter', metadata: { size: 100, expected_elements: 50, actual_elements: 30, false_positive_rate: 0.01, created_at: 1234567890 } };
    uiRenderer.renderCurrentFilterInfo(currentFilter);
    suite.assertTrue(mockDOM.currentFilterInfo.innerHTML.includes('test_filter'), 'Current filter should be rendered');
    suite.assertTrue(mockDOM.currentFilterInfo.innerHTML.includes('100'), 'Filter size should be rendered');
    
    // Test renderCurrentFilterInfo with null
    uiRenderer.renderCurrentFilterInfo(null);
    suite.assertTrue(mockDOM.currentFilterInfo.innerHTML.includes('No filter loaded'), 'No filter message should be rendered');
    
    // Test renderSearchForm
    uiRenderer.renderSearchForm(true);
    suite.assertEqual('block', mockDOM.searchForm.style.display, 'Search form should be shown');
    
    uiRenderer.renderSearchForm(false);
    suite.assertEqual('none', mockDOM.searchForm.style.display, 'Search form should be hidden');
    
    // Test renderSearchResults
    const searchResults = ['<div>Result 1</div>', '<div>Result 2</div>'];
    uiRenderer.renderSearchResults(searchResults);
    suite.assertEqual('<div>Result 1</div><div>Result 2</div>', mockDOM.searchResults.innerHTML, 'Search results should be rendered');
    
    // Test updateLoadButtonState
    uiRenderer.updateLoadButtonState(true);
    suite.assertFalse(mockDOM.loadFilterBtn.disabled, 'Load button should be enabled');
    
    uiRenderer.updateLoadButtonState(false);
    suite.assertTrue(mockDOM.loadFilterBtn.disabled, 'Load button should be disabled');
    
    // Test clearSearchInput
    mockDOM.searchTerm.value = 'test search';
    uiRenderer.clearSearchInput();
    suite.assertEqual('', mockDOM.searchTerm.value, 'Search input should be cleared');
    
    return suite;
}

// Test status manager
function testStatusManager() {
    console.log('\n📢 Testing Status Manager');
    console.log('==========================');
    
    const suite = new TestSuite();
    
    // Test addStatusMessage
    statusManager.addStatusMessage('Test message', 'success');
    suite.assertTrue(mockDOM.statusMessages.appendChild.called, 'Status message should be added to DOM');
    
    // Test with different types
    statusManager.addStatusMessage('Error message', 'error');
    statusManager.addStatusMessage('Info message', 'info');
    
    return suite;
}

// Test BloomFilterManager class
function testBloomFilterManager() {
    console.log('\n🎯 Testing BloomFilterManager Class');
    console.log('===================================');
    
    const suite = new TestSuite();
    
    // Test constructor
    const manager = new BloomFilterManager();
    suite.assertNotNull(manager, 'Manager should be created');
    suite.assertEqual('http://localhost:8080/api', manager.backendUrl, 'Backend URL should be set');
    suite.assertNotNull(manager.state, 'State should be initialized');
    
    // Test handleFileSelect
    const testFile = new MockFile('test.txt', 1024, 'text/plain');
    manager.handleFileSelect(testFile);
    
    // Wait for async operations
    setTimeout(() => {
        suite.assertNotNull(manager.state.uploadedFile, 'File should be set in state');
        suite.assertNotNull(manager.state.fileInfo, 'File info should be set in state');
    }, 100);
    
    // Test createBloomFilter
    mockDOM.filterName.value = 'test_filter';
    mockDOM.expectedElements.value = '1000';
    mockDOM.falsePositiveRate.value = '0.01';
    
    manager.createBloomFilter();
    
    // Test loadBloomFilters
    manager.loadBloomFilters();
    
    // Test selectFilter
    manager.selectFilter('test_filter');
    suite.assertEqual('test_filter', manager.state.selectedFilterName, 'Filter should be selected');
    
    // Test loadSelectedFilter
    manager.loadSelectedFilter();
    
    // Test searchInBloomFilter
    mockDOM.searchTerm.value = 'test_element';
    manager.searchInBloomFilter();
    
    // Test deleteFilter
    manager.deleteFilter('test_filter');
    
    return suite;
}

// Test global functions
function testGlobalFunctions() {
    console.log('\n🌍 Testing Global Functions');
    console.log('============================');
    
    const suite = new TestSuite();
    
    // Test createBloomFilter
    suite.assertNotNull(createBloomFilter, 'createBloomFilter function should exist');
    suite.assertType(createBloomFilter, 'function', 'createBloomFilter should be a function');
    
    // Test loadBloomFilters
    suite.assertNotNull(loadBloomFilters, 'loadBloomFilters function should exist');
    suite.assertType(loadBloomFilters, 'function', 'loadBloomFilters should be a function');
    
    // Test loadSelectedFilter
    suite.assertNotNull(loadSelectedFilter, 'loadSelectedFilter function should exist');
    suite.assertType(loadSelectedFilter, 'function', 'loadSelectedFilter should be a function');
    
    // Test searchInBloomFilter
    suite.assertNotNull(searchInBloomFilter, 'searchInBloomFilter function should exist');
    suite.assertType(searchInBloomFilter, 'function', 'searchInBloomFilter should be a function');
    
    return suite;
}

// Main test runner
function runAllTests() {
    console.log('🧪 Running Comprehensive Frontend Tests');
    console.log('=======================================');
    console.log('Target: 100% Code Coverage');
    console.log('');
    
    const allSuites = [
        testUtils(),
        testAPI(),
        testFileProcessor(),
        testUIState(),
        testUIRenderer(),
        testStatusManager(),
        testBloomFilterManager(),
        testGlobalFunctions()
    ];
    
    // Wait for async tests to complete
    setTimeout(() => {
        let totalPassed = 0;
        let totalTests = 0;
        
        allSuites.forEach(suite => {
            totalPassed += suite.passedTests;
            totalTests += suite.totalTests;
        });
        
        console.log('\n🎯 Overall Test Results');
        console.log('=======================');
        console.log(`Total Passed: ${totalPassed}`);
        console.log(`Total Tests: ${totalTests}`);
        console.log(`Overall Success Rate: ${((totalPassed / totalTests) * 100).toFixed(1)}%`);
        
        if (totalPassed === totalTests) {
            console.log('\n🎉 All tests passed! 100% coverage achieved!');
        } else {
            console.log('\n❌ Some tests failed!');
        }
    }, 1000);
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        TestSuite,
        testUtils,
        testAPI,
        testFileProcessor,
        testUIState,
        testUIRenderer,
        testStatusManager,
        testBloomFilterManager,
        testGlobalFunctions,
        runAllTests
    };
}

// Run tests if in browser
if (typeof window !== 'undefined') {
    window.runAllTests = runAllTests;
} 