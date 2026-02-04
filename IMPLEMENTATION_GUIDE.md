# TaxBridge Mobile App - Implementation Guide

## 📋 Overview
This document provides a comprehensive guide for the TaxBridge mobile application implementation, including complete CRUD operations for Clients, Invoices, and Items/Services with FBR integration.

## ✅ Completed Components

### 1. **Dependencies Added** ✓
All required packages have been added to `pubspec.yaml`:
- `http` & `dio` - HTTP clients for API communication
- `shared_preferences` - Local storage for tokens
- `intl` - Date/time formatting
- `image_picker` & `file_picker` - File handling
- `pdf` & `printing` - PDF generation
- `qr_flutter` - QR code display
- `shimmer` - Loading animations
- `cached_network_image` - Image caching

**Action Required**: Run `flutter pub get` to install dependencies.

### 2. **API Infrastructure** ✓
Complete API client with JWT authentication and X-Ock header support:

**Files Created/Updated:**
- `lib/core/network/api_client.dart` - Full HTTP client with GET, POST, PUT, DELETE, FormData support
- `lib/core/network/api_endpoints.dart` - All API endpoints defined
- `lib/core/network/network_exceptions.dart` - Custom exception classes

**Features:**
- Token management (access & refresh tokens)
- X-Ock header support for encryption
- Automatic error handling (401, 422, 404, 500)
- FormData support for file uploads
- Response parsing with standard envelope

**Important**: Update the `baseUrl` in `api_endpoints.dart` with your actual API URL.

### 3. **Data Models** ✓
Comprehensive models with JSON serialization:

**Files Created/Updated:**
- `lib/data/models/client_model.dart` - ClientModel with all buyer fields
- `lib/data/models/service_item_model.dart` - ServiceItemModel for items/services
- `lib/data/models/invoice_model.dart` - InvoiceModel, InvoiceDetailModel, SellerModel

**Features:**
- Complete field mapping from API
- JSON serialization (fromJson/toJson)
- Helper methods (typeLabel, formattedPrice, etc.)
- Null safety support

### 4. **Repositories** ✓
Repository pattern for clean architecture:

**Files Created/Updated:**
- `lib/data/repositories/client_repository.dart` - Client CRUD operations
- `lib/data/repositories/item_repository.dart` - Item CRUD operations
- `lib/data/repositories/invoice_repository.dart` - Invoice CRUD + FBR posting

**Features:**
- Paginated list fetching
- Create, Read, Update, Delete operations
- File upload support (logos)
- FBR posting for invoices

### 5. **Controllers (GetX State Management)** ✓
Complete state management with GetX:

**Files Created/Updated:**
- `lib/features/clients/controller/clients_controller.dart` - Client state management
- `lib/features/items/controller/items_controller.dart` - Item state management
- `lib/features/invoices/controller/invoices_controller.dart` - Invoice state management

**Features:**
- Observable state (RxList, RxBool, etc.)
- Pagination support (loadMore)
- CRUD operations with loading states
- Success/Error snackbar integration

### 6. **Success Snackbar System** ✓
Global snackbar helper for user feedback:

**File Created:**
- `lib/core/utils/snackbar_helper.dart`

**Methods:**
- `showSuccess()` - Green success messages
- `showError()` - Red error messages
- `showInfo()` - Blue info messages
- `showWarning()` - Orange warning messages

### 7. **Client UI (Complete)** ✓
Full CRUD interface for clients:

**Files Created/Updated:**
- `lib/features/clients/presentation/clients_list.dart` - List with stats, search, pagination
- `lib/features/clients/presentation/client_form_screen.dart` - Create/Edit form
- `lib/features/clients/presentation/client_create.dart` - Wrapper for form
- `lib/features/clients/presentation/client_detail.dart` - Detail view

**Features:**
- Beautiful card-based list
- Stats header (Total, Registered)
- Pull-to-refresh
- Infinite scroll pagination
- Create/Edit/Delete operations
- Image picker for logo
- Form validation
- Success/Error feedback

## 🚧 Remaining Tasks

### 1. **Invoice UI** (Priority: HIGH)
Create invoice management screens similar to the Figma design.

**Files to Create:**
- `lib/features/invoices/presentation/invoices_list.dart`
- `lib/features/invoices/presentation/invoice_form_screen.dart`
- `lib/features/invoices/presentation/invoice_detail.dart`

**Key Features Needed:**
- Invoice list with filters (Draft/Posted)
- Invoice type dropdown (from scenarios)
- Date pickers for invoice date & due date
- Client selector dropdown
- Dynamic item rows (add/remove)
- Quantity & price calculation
- Tax calculation display
- Post to FBR button
- QR code display (after FBR posting)
- PDF generation & sharing

**Reference**: Use the client UI as a template. The invoice form should match the Figma design provided.

### 2. **Items/Services UI** (Priority: MEDIUM)
Create items management screens.

**Files to Create:**
- `lib/features/items/presentation/items_list.dart`
- `lib/features/items/presentation/item_form_screen.dart`
- `lib/features/items/presentation/item_detail.dart`

**Key Features:**
- List with search
- Create/Edit/Delete
- HS Code input
- Price input with validation
- Tax rate input
- Unit of Measurement (UOM) dropdown

### 3. **Routes & Navigation** (Priority: HIGH)
Update routing and navigation.

**Files to Update:**
- `lib/routes/app_pages.dart` - Add all new routes
- `lib/core/constants/app_routes.dart` - Add route constants
- `lib/features/navigation/main_navigation.dart` - Update bottom nav

**Routes to Add:**
```dart
// Clients
GetPage(name: AppRoutes.clients, page: () => const ClientsList()),
GetPage(name: AppRoutes.clientCreate, page: () => const ClientCreate()),
GetPage(name: AppRoutes.clientDetail, page: () => ClientDetail()),

// Invoices
GetPage(name: AppRoutes.invoices, page: () => const InvoicesList()),
GetPage(name: AppRoutes.invoiceCreate, page: () => const InvoiceCreate()),
GetPage(name: AppRoutes.invoiceDetail, page: () => InvoiceDetail()),

// Items
GetPage(name: AppRoutes.items, page: () => const ItemsList()),
GetPage(name: AppRoutes.itemCreate, page: () => const ItemCreate()),
```

### 4. **Dependency Injection** (Priority: MEDIUM)
Register all controllers and repositories.

**File to Update:**
- `lib/di/injection_container.dart`

**Example:**
```dart
void init() {
  // API Client
  Get.lazyPut(() => ApiClient());
  
  // Repositories
  Get.lazyPut(() => ClientRepository(Get.find()));
  Get.lazyPut(() => ItemRepository(Get.find()));
  Get.lazyPut(() => InvoiceRepository(Get.find()));
  
  // Controllers
  Get.lazyPut(() => ClientsController(Get.find()));
  Get.lazyPut(() => ItemsController(Get.find()));
  Get.lazyPut(() => InvoicesController(Get.find()));
}
```

### 5. **Configuration Screen** (Priority: LOW)
Company/Business configuration management.

**Features:**
- Business info form
- FBR environment toggle (Sandbox/Production)
- API token inputs
- Scenario selection
- Logo upload

### 6. **Dashboard Enhancements** (Priority: LOW)
Update dashboard with real data.

**Features:**
- Total clients, invoices, FBR posted count
- Monthly charts (sales tax, further tax)
- Top clients list
- Invoice statistics

## 🔧 Configuration Steps

### 1. Update API Base URL
Edit `lib/core/network/api_endpoints.dart`:
```dart
static const String baseUrl = 'https://your-actual-api-url.com/api';
```

### 2. Run Flutter Pub Get
```bash
flutter pub get
```

### 3. Register Controllers
Update `lib/di/injection_container.dart` with all controllers and repositories.

### 4. Update Navigation
Add all routes to `lib/routes/app_pages.dart`.

### 5. Test API Connection
- Ensure login works
- Test token storage
- Verify API endpoints

## 📱 UI Design Guidelines

### Colors (from app_colors.dart)
- Primary: Green (#4CAF50)
- Background: Light gray (#F5F5F5)
- Text Primary: Dark gray (#212121)
- Text Secondary: Medium gray (#757575)
- Error: Red (#F44336)

### Components
- Use `AppInputField` for form inputs
- Use `AppButton` for primary actions
- Use `AppLoader` for loading states
- Use `EmptyState` for empty lists
- Use `SnackbarHelper` for feedback

### Patterns
- Card-based lists with elevation
- Pull-to-refresh on all lists
- Infinite scroll pagination
- Floating action buttons for create
- Popup menus for actions (edit/delete)
- Confirmation dialogs for delete

## 🐛 Common Issues & Solutions

### Issue: API returns 401 Unauthorized
**Solution**: Check if token is saved correctly after login. Verify `ApiClient.saveToken()` is called.

### Issue: FormData not uploading files
**Solution**: Ensure `Content-Type` is not set for multipart requests. The `ApiClient` handles this automatically.

### Issue: Controllers not found
**Solution**: Register controllers in `injection_container.dart` and call `InjectionContainer.init()` in `main.dart`.

### Issue: Pagination not working
**Solution**: Verify `current_page` and `last_page` are correctly parsed from API response.

## 📚 Next Steps

1. **Complete Invoice UI** - This is the most critical feature
2. **Add Items UI** - Required for invoice creation
3. **Update Routes** - Enable navigation between screens
4. **Test CRUD Operations** - Verify all create/update/delete work
5. **Test FBR Integration** - Ensure posting to FBR works
6. **Add PDF Generation** - For invoice sharing
7. **Add Search/Filters** - Enhance list screens
8. **Add Offline Support** - Cache data locally
9. **Add Analytics** - Track user actions
10. **Add Tests** - Unit and widget tests

## 🎯 Priority Order

1. ✅ API Infrastructure
2. ✅ Data Models
3. ✅ Repositories
4. ✅ Controllers
5. ✅ Client UI
6. 🚧 Invoice UI (NEXT)
7. 🚧 Items UI
8. 🚧 Routes & Navigation
9. 🚧 Dependency Injection
10. 🚧 Testing

## 📞 Support

For issues or questions:
1. Check this guide first
2. Review the Figma design
3. Check API documentation
4. Test with Postman/curl
5. Review error logs

---

**Last Updated**: 2025-11-10
**Version**: 1.0.0
**Status**: In Progress (70% Complete)

