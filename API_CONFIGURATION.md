# API Configuration - TaxBridge Mobile App

## ✅ API Base URL Updated

**Base URL:** `http://127.0.0.1:8000/api`

**File:** `lib/core/network/api_endpoints.dart`

---

## 📡 API Endpoints Configuration

### Items/Services Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| GET | `/items` | `http://127.0.0.1:8000/api/items` | Fetch all items (paginated) |
| POST | `/items/store` | `http://127.0.0.1:8000/api/items/store` | Create new item |
| POST | `/items/fetch` | `http://127.0.0.1:8000/api/items/fetch` | Fetch single item |
| POST | `/items/update` | `http://127.0.0.1:8000/api/items/update` | Update item |
| POST | `/items/delete` | `http://127.0.0.1:8000/api/items/delete` | Delete item |

### Buyers/Clients Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| GET | `/buyers` | `http://127.0.0.1:8000/api/buyers` | Fetch all buyers (paginated) |
| POST | `/buyers/store` | `http://127.0.0.1:8000/api/buyers/store` | Create new buyer |
| POST | `/buyers/fetch` | `http://127.0.0.1:8000/api/buyers/fetch` | Fetch single buyer |
| POST | `/buyers/update` | `http://127.0.0.1:8000/api/buyers/update` | Update buyer |
| POST | `/buyers/delete` | `http://127.0.0.1:8000/api/buyers/delete` | Delete buyer |

### Invoices Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| GET | `/invoices` | `http://127.0.0.1:8000/api/invoices` | Fetch all invoices (paginated) |
| POST | `/invoices/create` | `http://127.0.0.1:8000/api/invoices/create` | Create draft invoice |
| POST | `/invoices/edit` | `http://127.0.0.1:8000/api/invoices/edit` | Fetch invoice for editing |
| POST | `/invoices/update` | `http://127.0.0.1:8000/api/invoices/update` | Update invoice |
| POST | `/invoices/delete` | `http://127.0.0.1:8000/api/invoices/delete` | Delete invoice |
| POST | `/invoices/post-to-fbr` | `http://127.0.0.1:8000/api/invoices/post-to-fbr` | Post invoice to FBR |

### Authentication Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| POST | `/login` | `http://127.0.0.1:8000/api/login` | User login |
| POST | `/logout` | `http://127.0.0.1:8000/api/logout` | User logout |
| POST | `/refresh-token` | `http://127.0.0.1:8000/api/refresh-token` | Refresh JWT token |
| POST | `/forgot-password` | `http://127.0.0.1:8000/api/forgot-password` | Request password reset |
| POST | `/reset-password` | `http://127.0.0.1:8000/api/reset-password` | Reset password |

### Configuration Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| GET | `/company/fetch-configuration` | `http://127.0.0.1:8000/api/company/fetch-configuration` | Fetch company config |
| POST | `/company/update-configuration` | `http://127.0.0.1:8000/api/company/update-configuration` | Update company config |

### Dashboard & Logs Endpoints

| Method | Endpoint | Full URL | Purpose |
|--------|----------|----------|---------|
| GET | `/dashboard` | `http://127.0.0.1:8000/api/dashboard` | Fetch dashboard data |
| GET | `/activity-logs` | `http://127.0.0.1:8000/api/activity-logs` | Fetch activity logs |
| GET | `/audit-logs` | `http://127.0.0.1:8000/api/audit-logs` | Fetch audit logs |
| GET | `/fbr-errors` | `http://127.0.0.1:8000/api/fbr-errors` | Fetch FBR errors |

---

## 🔐 Authentication Headers

### JWT Bearer Token
All authenticated requests include:
```
Authorization: Bearer {access_token}
```

### X-Ock Header (Encryption Key)
Sensitive operations (like FBR posting) include:
```
X-Ock: {base64_encryption_key}
```

---

## 📤 Request Examples

### 1. Create Item (POST /items/store)

**Request:**
```http
POST http://127.0.0.1:8000/api/items/store
Content-Type: multipart/form-data
Authorization: Bearer {token}

item_description=Technical Consulting
item_hs_code=9815.1000
item_price=250000
item_tax_rate=16%
item_uom=Per Project
```

**Expected Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "Item created successfully",
  "data": {
    "item_id": 123,
    "item_description": "Technical Consulting",
    "item_hs_code": "9815.1000",
    "item_price": 250000,
    "item_tax_rate": "16%",
    "item_uom": "Per Project",
    "created_at": "2025-11-10T10:30:00Z"
  },
  "enc": 0
}
```

### 2. Fetch Items (GET /items?page=1)

**Request:**
```http
GET http://127.0.0.1:8000/api/items?page=1
Authorization: Bearer {token}
```

**Expected Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "Items fetched successfully",
  "data": {
    "current_page": 1,
    "data": [
      {
        "item_id": 123,
        "item_description": "Technical Consulting",
        "item_hs_code": "9815.1000",
        "item_price": 250000,
        "item_tax_rate": "16%",
        "item_uom": "Per Project"
      },
      {
        "item_id": 124,
        "item_description": "IT Support Services",
        "item_hs_code": "9815.2000",
        "item_price": 50000,
        "item_tax_rate": "16%",
        "item_uom": "Per Month"
      }
    ],
    "first_page_url": "http://127.0.0.1:8000/api/items?page=1",
    "from": 1,
    "last_page": 3,
    "last_page_url": "http://127.0.0.1:8000/api/items?page=3",
    "next_page_url": "http://127.0.0.1:8000/api/items?page=2",
    "path": "http://127.0.0.1:8000/api/items",
    "per_page": 15,
    "prev_page_url": null,
    "to": 15,
    "total": 45
  },
  "isPaginated": true
}
```

### 3. Update Item (POST /items/update)

**Request:**
```http
POST http://127.0.0.1:8000/api/items/update
Content-Type: multipart/form-data
Authorization: Bearer {token}

item_id=123
item_description=Updated Technical Consulting
item_price=300000
item_tax_rate=18%
```

**Expected Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "Item updated successfully",
  "data": {
    "item_id": 123,
    "item_description": "Updated Technical Consulting",
    "item_hs_code": "9815.1000",
    "item_price": 300000,
    "item_tax_rate": "18%",
    "item_uom": "Per Project",
    "updated_at": "2025-11-10T11:00:00Z"
  }
}
```

### 4. Delete Item (POST /items/delete)

**Request:**
```http
POST http://127.0.0.1:8000/api/items/delete
Content-Type: multipart/form-data
Authorization: Bearer {token}

item_id=123
```

**Expected Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "Item deleted successfully",
  "data": null
}
```

---

## 🧪 Testing the API

### Using Flutter App:
1. Run the app: `flutter run`
2. Navigate to Items/Services screen
3. Try creating a new item
4. Check the console for API requests/responses

### Using Postman/cURL:

**Test Create Item:**
```bash
curl -X POST http://127.0.0.1:8000/api/items/store \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "item_description=Test Item" \
  -F "item_price=100000" \
  -F "item_tax_rate=16%"
```

**Test Fetch Items:**
```bash
curl -X GET http://127.0.0.1:8000/api/items?page=1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## ⚙️ Configuration Steps

### 1. Update API URL (Already Done ✅)
```dart
// lib/core/network/api_endpoints.dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

### 2. For Production Deployment
When deploying to production, update to your production URL:
```dart
static const String baseUrl = 'https://api.taxbridge.pk/api';
```

### 3. For Android Emulator
If testing on Android emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```
(10.0.2.2 is the special IP that maps to localhost on Android emulator)

### 4. For iOS Simulator
iOS simulator can use:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

### 5. For Physical Device
Use your computer's local IP address:
```dart
static const String baseUrl = 'http://192.168.1.XXX:8000/api';
```

---

## 🔍 Debugging API Calls

### Enable Logging in ApiClient

Add this to see all API requests/responses:

```dart
// In api_client.dart, add logging
print('🌐 API Request: ${uri.toString()}');
print('📤 Headers: $headers');
print('📦 Body: $body');
print('📥 Response: ${response.body}');
```

### Check Network Issues

1. **CORS Issues**: Ensure Laravel backend allows requests from mobile app
2. **SSL/HTTPS**: Use HTTP for local development
3. **Firewall**: Ensure port 8000 is not blocked
4. **Server Running**: Verify Laravel server is running on port 8000

---

## 📝 Notes

### Field Naming Convention
The API uses snake_case for field names:
- `item_description` (not `itemDescription`)
- `item_hs_code` (not `itemHsCode`)
- `item_price` (not `itemPrice`)

The Flutter models handle conversion between snake_case (API) and camelCase (Dart).

### Response Envelope
All API responses follow this structure:
```json
{
  "success": true/false,
  "code": 200,
  "message": "Success message",
  "data": {...},
  "enc": 0/1,
  "isPaginated": true/false
}
```

### Error Responses
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

## ✅ Summary

- ✅ Base URL configured: `http://127.0.0.1:8000/api`
- ✅ All endpoints defined and mapped
- ✅ Authentication headers configured
- ✅ Request/Response handling implemented
- ✅ Error handling in place
- ✅ Ready for testing!

**Next Steps:**
1. Ensure Laravel backend is running on `http://127.0.0.1:8000`
2. Test login to get JWT token
3. Test Items CRUD operations
4. Test Clients CRUD operations
5. Verify all API responses match expected format

