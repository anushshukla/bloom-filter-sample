#!/usr/bin/env python3
"""
Comprehensive test suite for http://localhost:8080/api/bloom-filter/create
Tests various scenarios including valid requests, edge cases, and error conditions
"""

import requests
import json
import time
from typing import Dict, Any, List

class BloomFilterCreateTester:
    def __init__(self, base_url: str = "http://localhost:8080/api/bloom-filter/create"):
        self.base_url = base_url
        self.headers = {"Content-Type": "application/json"}
        self.test_results = []
        
    def run_test(self, test_name: str, payload: Dict[str, Any], expected_success: bool, description: str = ""):
        """Run a single test and record results"""
        print(f"\n🧪 {test_name}")
        if description:
            print(f"   {description}")
        
        try:
            start_time = time.time()
            response = requests.post(self.base_url, headers=self.headers, json=payload, timeout=30)
            end_time = time.time()
            
            response_time = end_time - start_time
            success = response.status_code == 200 and response.json().get("success", False)
            
            result = {
                "test_name": test_name,
                "expected_success": expected_success,
                "actual_success": success,
                "status_code": response.status_code,
                "response_time": response_time,
                "response": response.json() if response.status_code == 200 else response.text,
                "passed": success == expected_success
            }
            
            if result["passed"]:
                print(f"   ✅ PASSED (Response time: {response_time:.3f}s)")
            else:
                print(f"   ❌ FAILED (Expected: {expected_success}, Got: {success})")
                print(f"   Response: {result['response']}")
            
            self.test_results.append(result)
            return result
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "expected_success": expected_success,
                "actual_success": False,
                "error": str(e),
                "passed": False
            }
            print(f"   ❌ ERROR: {e}")
            self.test_results.append(result)
            return result
    
    def run_all_tests(self):
        """Run all test cases"""
        print("🚀 Starting Bloom Filter Create Endpoint Tests")
        print("=" * 60)
        
        # Test 1: Valid request with minimal data
        self.run_test(
            "Test 1: Valid minimal request",
            {
                "filter_name": "test_minimal",
                "file_content": "apple\nbanana",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Basic bloom filter creation with minimal data"
        )
        
        # Test 2: Valid request with larger dataset
        self.run_test(
            "Test 2: Valid large dataset",
            {
                "filter_name": "test_large_dataset",
                "file_content": "apple\nbanana\ncherry\ndate\nelderberry\nfig\ngrape\nhoneydew\nkiwi\nlemon",
                "expected_elements": 1000,
                "false_positive_rate": 0.001
            },
            expected_success=True,
            description="Bloom filter with larger dataset and lower false positive rate"
        )
        
        # Test 3: Test with different false positive rates
        self.run_test(
            "Test 3: Low false positive rate",
            {
                "filter_name": "test_low_fpr",
                "file_content": "test1\ntest2\ntest3",
                "expected_elements": 100,
                "false_positive_rate": 0.001
            },
            expected_success=True,
            description="Very low false positive rate (0.001)"
        )
        
        # Test 4: Test with high expected elements
        self.run_test(
            "Test 4: High expected elements",
            {
                "filter_name": "test_high_elements",
                "file_content": "item1\nitem2\nitem3",
                "expected_elements": 100000,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Very high expected elements (100,000)"
        )
        
        # Test 5: Test with single element
        self.run_test(
            "Test 5: Single element",
            {
                "filter_name": "test_single_element",
                "file_content": "single_item",
                "expected_elements": 10,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Single element in file content"
        )
        
        # Test 6: Test with empty file content (should fail)
        self.run_test(
            "Test 6: Empty file content",
            {
                "filter_name": "test_empty_content",
                "file_content": "",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=False,
            description="Empty file content should fail validation"
        )
        
        # Test 7: Test with missing file_content (should fail)
        self.run_test(
            "Test 7: Missing file_content",
            {
                "filter_name": "test_missing_content",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=False,
            description="Missing file_content field should fail validation"
        )
        
        # Test 8: Test with missing filter_name (should fail)
        self.run_test(
            "Test 8: Missing filter_name",
            {
                "file_content": "test",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=False,
            description="Missing filter_name field should fail validation"
        )
        
        # Test 9: Test with missing expected_elements (should use default)
        self.run_test(
            "Test 9: Missing expected_elements",
            {
                "filter_name": "test_default_elements",
                "file_content": "test1\ntest2\ntest3",
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Missing expected_elements should use default value"
        )
        
        # Test 10: Test with missing false_positive_rate (should use default)
        self.run_test(
            "Test 10: Missing false_positive_rate",
            {
                "filter_name": "test_default_fpr",
                "file_content": "test1\ntest2\ntest3",
                "expected_elements": 100
            },
            expected_success=True,
            description="Missing false_positive_rate should use default value"
        )
        
        # Test 11: Test with all defaults (should work)
        self.run_test(
            "Test 11: All defaults",
            {
                "filter_name": "test_all_defaults",
                "file_content": "test"
            },
            expected_success=True,
            description="Only required fields, all others use defaults"
        )
        
        # Test 12: Test with special characters in content
        self.run_test(
            "Test 12: Special characters",
            {
                "filter_name": "test_special_chars",
                "file_content": "item_with_underscore\nitem-with-dash\nitem with spaces\nitem123",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Special characters and spaces in content"
        )
        
        # Test 13: Test with very long filter name
        self.run_test(
            "Test 13: Long filter name",
            {
                "filter_name": "very_long_filter_name_that_exceeds_normal_length_limits_and_tests_edge_cases_for_filter_naming_conventions",
                "file_content": "test",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Very long filter name to test edge cases"
        )
        
        # Test 14: Test with very large content
        self.run_test(
            "Test 14: Large content",
            {
                "filter_name": "test_large_content",
                "file_content": "\n".join([f"item_{i}" for i in range(1, 101)]),
                "expected_elements": 1000,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="100 items in file content"
        )
        
        # Test 15: Performance test with many elements
        self.run_test(
            "Test 15: Performance test",
            {
                "filter_name": "test_performance",
                "file_content": "\n".join([f"perf_item_{i}" for i in range(1, 1001)]),
                "expected_elements": 10000,
                "false_positive_rate": 0.001
            },
            expected_success=True,
            description="1000 items with high expected elements for performance testing"
        )
        
        # Test 16: Test with duplicate filter name (should work, creates new filter)
        self.run_test(
            "Test 16: Duplicate filter name (first)",
            {
                "filter_name": "test_duplicate",
                "file_content": "first_content",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="First filter with duplicate name"
        )
        
        self.run_test(
            "Test 16: Duplicate filter name (second)",
            {
                "filter_name": "test_duplicate",
                "file_content": "second_content",
                "expected_elements": 100,
                "false_positive_rate": 0.01
            },
            expected_success=True,
            description="Second filter with same name (should overwrite)"
        )
        
        self.print_summary()
    
    def print_summary(self):
        """Print test summary"""
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["passed"])
        failed_tests = total_tests - passed_tests
        
        print(f"Total Tests: {total_tests}")
        print(f"✅ Passed: {passed_tests}")
        print(f"❌ Failed: {failed_tests}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        if failed_tests > 0:
            print("\n❌ Failed Tests:")
            for result in self.test_results:
                if not result["passed"]:
                    print(f"   - {result['test_name']}")
                    if "error" in result:
                        print(f"     Error: {result['error']}")
                    elif "response" in result:
                        print(f"     Response: {result['response']}")
        
        print("\n🎯 All tests completed!")

if __name__ == "__main__":
    tester = BloomFilterCreateTester()
    tester.run_all_tests()
