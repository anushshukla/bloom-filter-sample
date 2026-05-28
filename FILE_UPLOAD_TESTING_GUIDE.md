# 🚀 File Upload Testing Guide - Local Setup

## 🔍 **Issue Identified**

The file upload wasn't working because:
1. **Backend Server Not Running** - The Lua backend requires Redis and specific modules
2. **Missing Dependencies** - Lua modules like `http`, `cjson`, `redis` aren't available by default
3. **Port Mismatch** - Frontend expects backend on port 8080

## ✅ **Solution: Mock Backend Server**

I've created a Python mock backend server that simulates the API without requiring Redis or complex Lua modules.

---

## 🚀 **Quick Setup & Testing**

### **1. Start the Mock Backend Server**

```bash
# In the project root directory
python3 test_backend_server.py
```

**Expected Output:**
```
🚀 Mock Backend Server started on port 8080
📡 API endpoints available at http://localhost:8080/api/
🔍 Test file upload at http://localhost:3000 (frontend)
Press Ctrl+C to stop the server
```

### **2. Start the Frontend Server**

```bash
# In a new terminal, go to frontend directory
cd frontend
npm start
```

**Expected Output:**
```
Starting up http-server, serving ./
Available on:
  http://127.0.0.1:3000
  http://192.168.x.x:3000
```

### **3. Test File Upload**

1. **Open Browser:** Navigate to `http://localhost:3000`
2. **Upload File:** Use `test_data/sample_words.txt` or any `.txt`/`.csv` file
3. **Verify:** Check browser console and backend server logs

---

## 🧪 **API Testing with curl**

### **Test Backend Health**
```bash
curl -X GET http://localhost:8080/api/bloom-filter/list
```

**Expected Response:**
```json
{"success": true, "filters": []}
```

### **Test File Upload**
```bash
curl -X POST http://localhost:8080/api/bloom-filter/create \
  -H "Content-Type: application/json" \
  -d '{
    "filter_name": "test_filter",
    "file_content": "apple\nbanana\ncherry\norange",
    "expected_elements": 10,
    "false_positive_rate": 0.01
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "filter": {
    "name": "test_filter",
    "metadata": {
      "size": 1000,
      "hash_count": 3,
      "expected_elements": 10,
      "false_positive_rate": 0.01,
      "actual_elements": 4,
      "created_at": 1755141314
    },
    "elements_processed": 4
  },
  "message": "Bloom filter \"test_filter\" created successfully with 4 elements"
}
```

### **Verify Filter Creation**
```bash
curl -X GET http://localhost:8080/api/bloom-filter/list
```

**Expected Response:**
```json
{
  "success": true,
  "filters": [
    {
      "name": "test_filter",
      "metadata": {...}
    }
  ]
}
```

---

## 🔧 **Troubleshooting**

### **Backend Server Issues**

**Problem:** `Address already in use`
```bash
# Kill existing process on port 8080
lsof -ti:8080 | xargs kill -9
# Restart server
python3 test_backend_server.py
```

**Problem:** Python not found
```bash
# Install Python 3
brew install python3
# Or use python instead of python3
python test_backend_server.py
```

### **Frontend Issues**

**Problem:** Frontend can't connect to backend
```bash
# Check if backend is running
curl http://localhost:8080/api/bloom-filter/list

# Check frontend console for errors
# Open browser dev tools (F12) and check Console tab
```

**Problem:** CORS errors
```bash
# Backend should handle CORS automatically
# If issues persist, check browser console for CORS errors
```

---

## 📱 **Complete Testing Workflow**

### **Step 1: Start Backend**
```bash
# Terminal 1
cd /Users/anush/apps/wingify/bloomFilter
python3 test_backend_server.py
```

### **Step 2: Start Frontend**
```bash
# Terminal 2
cd /Users/anush/apps/wingify/bloomFilter/frontend
npm start
```

### **Step 3: Test in Browser**
1. Open `http://localhost:3000`
2. Click "Choose File" or drag & drop a file
3. Select `test_data/sample_words.txt`
4. Verify file info is displayed
5. Click "Create Bloom Filter"
6. Check success message

### **Step 4: Verify Backend**
```bash
# Terminal 3
curl http://localhost:8080/api/bloom-filter/list
```

---

## 🎯 **Expected Results**

### **Frontend Behavior**
- ✅ File selection works
- ✅ File info displayed correctly
- ✅ Upload button enabled
- ✅ Success message shown
- ✅ Filter appears in list

### **Backend Behavior**
- ✅ Server logs show API calls
- ✅ Filters stored in memory
- ✅ Correct responses sent
- ✅ CORS headers included

### **API Responses**
- ✅ 200 status codes
- ✅ JSON responses
- ✅ Proper error handling
- ✅ Data validation

---

## 🔍 **Debugging Tips**

### **Check Browser Console**
1. Open Dev Tools (F12)
2. Go to Console tab
3. Look for errors or API calls

### **Check Backend Logs**
```bash
# Backend server shows all API calls
[08:45:23] "POST /api/bloom-filter/create HTTP/1.1" 200
[08:45:24] "GET /api/bloom-filter/list HTTP/1.1" 200
```

### **Test API Endpoints**
```bash
# Test each endpoint individually
curl http://localhost:8080/api/bloom-filter/list
curl http://localhost:8080/api/bloom-filter/test_filter/metadata
curl "http://localhost:8080/api/bloom-filter/test_filter/search?element=apple"
```

---

## 🎉 **Success Indicators**

When everything is working correctly, you should see:

1. **Backend Server Running:**
   ```
   🚀 Mock Backend Server started on port 8080
   📡 API endpoints available at http://localhost:8080/api/
   ```

2. **Frontend Server Running:**
   ```
   Available on: http://127.0.0.1:3000
   ```

3. **File Upload Working:**
   - File selection dialog opens
   - File info displayed
   - Upload button enabled
   - Success message shown

4. **API Responses:**
   - All endpoints return 200 status
   - JSON responses are valid
   - Data is stored and retrieved

---

## 🚀 **Next Steps**

Once file upload is working:

1. **Test with Different Files:**
   - Large files (>1MB)
   - Different file types (.txt, .csv)
   - Files with special characters

2. **Test Search Functionality:**
   - Load created filters
   - Search for existing elements
   - Search for non-existing elements

3. **Test Edge Cases:**
   - Empty files
   - Very large files
   - Invalid file types

4. **Performance Testing:**
   - Upload speed
   - Search response time
   - Memory usage

---

**The mock backend server provides a working solution for testing file upload functionality without requiring Redis or complex Lua dependencies!** 🎯 