# Testing Guide - TaxBridge Mobile App

## 🚀 Quick Start Testing

### Prerequisites
1. ✅ Laravel backend running on `http://127.0.0.1:8000`
2. ✅ Flutter dependencies installed (`flutter pub get`)
3. ✅ API base URL configured in `lib/core/network/api_endpoints.dart`

---

## 📱 Testing Items/Services Feature

### Step 1: Run the App
```bash
cd e:\Flutter Project\Tax_Bridge\tax_bridge
flutter run
```

### Step 2: Navigate to Items Screen
- Tap on "Items / Services" from the navigation menu
- Or use the route: `Get.to(() => const ItemsList())`

### Step 3: Test Create Item

**Action:** Tap "Add New Item / Service" button

**Fill the form:**
- Item/Service Description: `Technical Consulting Services`
- HS Code: `9815.1000`
- Price: `250000`
- Tax Rate: `16`
- Unit of Measure: `Per Project`

**Tap:** "Save Item"

**Expected Result:**
- ✅ Green success snackbar: "Item created successfully"
- ✅ Form closes automatically
- ✅ New item appears at the top of the list
- ✅ Item card shows all entered information

**API Call Made:**
```
POST http://127.0.0.1:8000/api/items/store
```

### Step 4: Test View Items List

**Expected Result:**
- ✅ Items load automatically on screen open
- ✅ Each item card shows:
  - Item description
  - HS Code (if available)
  - Unit of Measure badge
  - Status badge ("Ok")
  - Price (formatted as "PKR 250,000")
  - Tax Rate (e.g., "16%")
  - Edit button (orange)
  - Delete button (red)

**API Call Made:**
```
GET http://127.0.0.1:8000/api/items?page=1
```

### Step 5: Test Search

**Action:** Type in the search bar

**Expected Result:**
- ✅ Items filter as you type
- ✅ Search works on item description

### Step 6: Test Edit Item

**Action:** Tap "Edit" button on any item

**Expected Result:**
- ✅ Form opens with existing data pre-filled
- ✅ Title shows "Edit Item / Service"
- ✅ All fields are editable

**Modify:** Change price to `300000`

**Tap:** "Update Item"

**Expected Result:**
- ✅ Green success snackbar: "Item updated successfully"
- ✅ Form closes
- ✅ Item card shows updated price

**API Call Made:**
```
POST http://127.0.0.1:8000/api/items/update
```

### Step 7: Test Delete Item

**Action:** Tap "Delete" button on any item

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ Dialog shows: "Are you sure you want to delete [Item Name]?"

**Tap:** "Delete"

**Expected Result:**
- ✅ Green success snackbar: "Item deleted successfully"
- ✅ Item removed from list
- ✅ Total count decreases

**API Call Made:**
```
POST http://127.0.0.1:8000/api/items/delete
```

### Step 8: Test Pull-to-Refresh

**Action:** Pull down on the list

**Expected Result:**
- ✅ Refresh indicator appears
- ✅ List reloads from API
- ✅ Latest data displayed

### Step 9: Test Pagination

**Action:** Scroll to bottom of list (if more than 15 items)

**Expected Result:**
- ✅ Loading spinner appears at bottom
- ✅ Next page of items loads automatically
- ✅ Items append to existing list

**API Call Made:**
```
GET http://127.0.0.1:8000/api/items?page=2
```

### Step 10: Test Empty State

**Action:** Delete all items (or test with empty database)

**Expected Result:**
- ✅ Empty state appears with:
  - Inventory icon
  - "No Items" title
  - "Add your first item or service to get started" message
  - "Add Item" button

---

## 📱 Testing Clients Feature

### Step 1: Navigate to Clients Screen
- Tap on "Clients" from the navigation menu

### Step 2: Test Create Client

**Action:** Tap "Add Client" floating button

**Fill the form:**
- Client Name: `ABC Corporation`
- Client Type: Select "Registered"
- ID Type: Select "NTN"
- NTN/CNIC: `1234567-8`
- Address: `123 Main Street, Karachi`
- Province: `Sindh`
- Contact Number: `+92-300-1234567`
- Contact Person: `John Doe`

**Tap:** "Save Client"

**Expected Result:**
- ✅ Green success snackbar: "Client created successfully"
- ✅ Form closes
- ✅ New client appears in list

**API Call Made:**
```
POST http://127.0.0.1:8000/api/buyers/store
```

### Step 3: Test View Client Details

**Action:** Tap on any client card

**Expected Result:**
- ✅ Detail screen opens
- ✅ Shows client avatar with initial
- ✅ Shows all client information
- ✅ Edit button in app bar

### Step 4: Test Edit Client

**Action:** Tap edit icon in client detail screen

**Expected Result:**
- ✅ Form opens with existing data
- ✅ All fields editable

**Modify:** Change contact number

**Tap:** "Update Client"

**Expected Result:**
- ✅ Success snackbar appears
- ✅ Client updated in list

**API Call Made:**
```
POST http://127.0.0.1:8000/api/buyers/update
```

### Step 5: Test Delete Client

**Action:** Tap menu icon (⋮) on client card → Delete

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ Client deleted after confirmation

**API Call Made:**
```
POST http://127.0.0.1:8000/api/buyers/delete
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "No internet connection" Error

**Cause:** Backend server not running or wrong URL

**Solution:**
1. Verify Laravel server is running: `php artisan serve`
2. Check API URL in `lib/core/network/api_endpoints.dart`
3. For Android emulator, use `http://10.0.2.2:8000/api`

### Issue 2: "Unauthorized" (401) Error

**Cause:** No JWT token or expired token

**Solution:**
1. Implement login screen first
2. Save token after successful login
3. Token is automatically added to requests

### Issue 3: "Validation failed" (422) Error

**Cause:** Required fields missing or invalid data

**Solution:**
1. Check form validation
2. Ensure all required fields are filled
3. Check API response for specific field errors

### Issue 4: Items not loading

**Cause:** API response format mismatch

**Solution:**
1. Check API response structure matches expected format
2. Verify pagination data is present
3. Check console for error messages

### Issue 5: CORS Error (Web only)

**Cause:** Laravel backend not allowing requests

**Solution:**
Add to Laravel `config/cors.php`:
```php
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

---

## 🧪 Manual API Testing (Without App)

### Using cURL

**1. Create Item:**
```bash
curl -X POST http://127.0.0.1:8000/api/items/store \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "item_description=Test Item" \
  -F "item_hs_code=9815.1000" \
  -F "item_price=100000" \
  -F "item_tax_rate=16%" \
  -F "item_uom=Per Unit"
```

**2. Fetch Items:**
```bash
curl -X GET "http://127.0.0.1:8000/api/items?page=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**3. Update Item:**
```bash
curl -X POST http://127.0.0.1:8000/api/items/update \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "item_id=1" \
  -F "item_description=Updated Item" \
  -F "item_price=150000"
```

**4. Delete Item:**
```bash
curl -X POST http://127.0.0.1:8000/api/items/delete \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "item_id=1"
```

### Using Postman

**Import this collection:**

1. Create new request
2. Set method to POST
3. URL: `http://127.0.0.1:8000/api/items/store`
4. Headers:
   - `Authorization: Bearer YOUR_TOKEN`
5. Body (form-data):
   - `item_description`: Technical Consulting
   - `item_price`: 250000
   - `item_tax_rate`: 16%
   - `item_uom`: Per Project

---

## ✅ Testing Checklist

### Items Feature
- [ ] Items list loads on screen open
- [ ] Search filters items correctly
- [ ] Add button opens form
- [ ] Form validation works (required fields)
- [ ] Create item succeeds
- [ ] Success snackbar appears
- [ ] New item appears in list
- [ ] Edit button opens form with data
- [ ] Update item succeeds
- [ ] Delete shows confirmation
- [ ] Delete removes item
- [ ] Pull-to-refresh works
- [ ] Pagination loads more items
- [ ] Empty state shows when no items

### Clients Feature
- [ ] Clients list loads
- [ ] Stats show correct counts
- [ ] Add client form works
- [ ] Client type selection works
- [ ] Create client succeeds
- [ ] Client detail screen shows all info
- [ ] Edit client works
- [ ] Delete client works
- [ ] Logo upload works (if implemented)

### General
- [ ] Loading states show correctly
- [ ] Error messages are user-friendly
- [ ] Success messages appear
- [ ] Navigation works smoothly
- [ ] No crashes or freezes
- [ ] UI matches design screenshots

---

## 📊 Expected API Response Format

### Success Response (Create/Update)
```json
{
  "success": true,
  "code": 200,
  "message": "Item created successfully",
  "data": {
    "item_id": 1,
    "item_description": "Technical Consulting",
    "item_hs_code": "9815.1000",
    "item_price": 250000,
    "item_tax_rate": "16%",
    "item_uom": "Per Project"
  }
}
```

### Success Response (List - Paginated)
```json
{
  "success": true,
  "code": 200,
  "message": "Items fetched successfully",
  "data": {
    "current_page": 1,
    "data": [...],
    "last_page": 3,
    "per_page": 15,
    "total": 45
  },
  "isPaginated": true
}
```

### Error Response (Validation)
```json
{
  "success": false,
  "code": 422,
  "message": "Validation failed",
  "errors": {
    "item_description": ["The item description field is required."],
    "item_price": ["The item price must be a number."]
  }
}
```

---

## 🎯 Next Steps After Testing

1. ✅ Verify all Items CRUD operations work
2. ✅ Verify all Clients CRUD operations work
3. 🚧 Implement Invoice UI
4. 🚧 Test Invoice CRUD operations
5. 🚧 Test FBR posting
6. 🚧 Implement authentication flow
7. 🚧 Add navigation between screens
8. 🚧 Polish UI and fix any issues

---

## 📝 Notes

- Always check the console/logs for detailed error messages
- API responses should match the expected format
- JWT token is required for all authenticated endpoints
- Use Postman/cURL to test API independently if app issues occur
- Check Laravel logs for backend errors: `storage/logs/laravel.log`

---

**Happy Testing! 🚀**

