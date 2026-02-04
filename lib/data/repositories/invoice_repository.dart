// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/invoice_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final ApiClient _apiClient;

  InvoiceRepository(this._apiClient);

  // ───── Fetch All Invoices (Paginated) ─────
  Future<Map<String, dynamic>> fetchInvoices({int page = 1, int? buyerId}) async {
    try {
      final qp = {'page': page.toString()};
      if (buyerId != null) qp['buyer_id'] = buyerId.toString();

      final response = await _apiClient.get(
        ApiEndpoints.invoicesList,
        queryParams: qp,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final invoicesList = (data['data'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();

        int _toInt(dynamic v) {
          if (v is int) return v;
          if (v is String) return int.tryParse(v) ?? 0;
          return 0;
        }

        return {
          'invoices': invoicesList,
          'current_page': _toInt(data['current_page']),
          'last_page': _toInt(data['last_page']),
          'per_page': _toInt(data['per_page']),
          'total': _toInt(data['total']),
        };
      }
      throw Exception(response['message'] ?? 'Failed to fetch invoices');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Fetch Invoices by Buyer (for selects/dropdowns) ─────
  Future<List<InvoiceModel>> fetchInvoicesByBuyer({required int buyerId}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.invoicesByBuyer,
        queryParams: {'buyer_id': buyerId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List invoicesJson = [];
        if (data is Map && data.containsKey('invoices')) {
          invoicesJson = data['invoices'] as List;
        } else if (data is List) {
          invoicesJson = data;
        } else if (response.containsKey('invoices')) {
          invoicesJson = response['invoices'] as List;
        }
        
        return invoicesJson.map((json) => InvoiceModel.fromJson(json)).toList();
      }
      throw Exception(response['message'] ?? 'Failed to fetch buyer invoices');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchInvoicesFiltered({
    int page = 1,
    String? invoiceType,
    String? dateFrom,
    String? dateTo,
    int? isPostedToFbr,
  }) async {
    try {
      final fields = <String, dynamic>{
        'page': page.toString(),
      };
      if (invoiceType != null && invoiceType.isNotEmpty) {
        fields['invoice_type'] = invoiceType;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        fields['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        fields['date_to'] = dateTo;
      }
      if (isPostedToFbr != null) {
        fields['is_posted_to_fbr'] = isPostedToFbr.toString();
      }

      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesFilter,
        fields: fields,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final invoicesList = (data['data'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();

        int _toInt(dynamic v) {
          if (v is int) return v;
          if (v is String) return int.tryParse(v) ?? 0;
          return 0;
        }

        return {
          'invoices': invoicesList,
          'current_page': _toInt(data['current_page']),
          'last_page': _toInt(data['last_page']),
          'per_page': _toInt(data['per_page']),
          'total': _toInt(data['total']),
        };
      }
      throw Exception(response['message'] ?? 'Failed to filter invoices');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Fetch data for Create Invoice form ─────
  Future<Map<String, dynamic>> fetchInvoiceCreateData({int? busConfigId, int? tenantId}) async {
    try {
      final fields = <String, dynamic>{
        if (busConfigId != null) 'bus_config_id': busConfigId.toString(),
        if (tenantId != null) 'tenant_id': tenantId.toString(),
      };

      print('📝 Repository: Fetching invoice create data');
      print('📝 Repository: Endpoint: ${ApiEndpoints.invoicesCreate}');
      print('📝 Repository: Fields: $fields');

      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesCreate,
        fields: fields,
        requiresAuth: true,
      );

      print('📝 Repository: API Response received');
      print('📝 Repository: Success: ${response['success']}');
      print('📝 Repository: Response keys: ${response.keys.toList()}');

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        print('📝 Repository: Data keys: ${data.keys.toList()}');
        print('📝 Repository: Scenarios present: ${data.containsKey('scenarios')}');

        List? scenarios;
        List<dynamic>? selectedScenarioIds;

        if (data.containsKey('scenarios')) {
          scenarios = data['scenarios'] as List?;
          if (scenarios != null) {
            print('📝 Repository: Scenarios count from /invoices/create: ${scenarios.length}');
          } else {
            print('⚠️ Repository: Scenarios is null');
          }

          // Some backends may also send selectedScenarios with /invoices/create
          if (data.containsKey('selectedScenarios')) {
            selectedScenarioIds = (data['selectedScenarios'] as List?)?.toList();
            print('📝 Repository: selectedScenarios from /invoices/create: ${selectedScenarioIds?.length ?? 0}');
          }
        } else {
          print('⚠️ Repository: No scenarios key in /invoices/create response');
        }

        // ✅ Always fall back to company configuration for selectedScenarios (and scenarios if missing)
        if (scenarios == null || selectedScenarioIds == null || selectedScenarioIds.isEmpty) {
          print('📝 Repository: Loading scenarios/selectedScenarios from /company/fetch-configuration');
          try {
            final configResponse = await _apiClient.postFormData(
              ApiEndpoints.companyFetchConfiguration,
              fields: {'bus_config_id': busConfigId?.toString() ?? '1'},
              requiresAuth: true,
            );

            print('📝 Repository: Config API response received');
            final hasSuccess = configResponse.containsKey('success');
            final isSuccess = hasSuccess ? (configResponse['success'] == true) : configResponse.containsKey('data');

            if (isSuccess) {
              final configData = (configResponse['data'] ?? {}) as Map<String, dynamic>;

              // If /invoices/create did not return scenarios, use config.scenarios
              if (scenarios == null && configData.containsKey('scenarios')) {
                scenarios = configData['scenarios'] as List?;
                print('✅ Repository: Scenarios loaded from config: ${scenarios?.length ?? 0}');
              }

              // Always take selectedScenarios from config if present
              if (configData.containsKey('selectedScenarios')) {
                selectedScenarioIds = (configData['selectedScenarios'] as List?)?.toList();
                print('✅ Repository: selectedScenarios from config: ${selectedScenarioIds?.length ?? 0}');
              }
            }
          } catch (e) {
            print('❌ Repository: Failed to fetch scenarios/selectedScenarios from config: $e');
          }
        }

        // Mark configured scenarios as selected so UI can auto-select them
        if (scenarios != null && selectedScenarioIds != null && selectedScenarioIds.isNotEmpty) {
          final idSet = selectedScenarioIds.map((e) {
            if (e is int) return e;
            if (e is String) return int.tryParse(e) ?? -1;
            return -1;
          }).where((id) => id > 0).toSet();

          for (final s in scenarios) {
            if (s is Map<String, dynamic>) {
              final rawId = s['scenario_id'];
              int id;
              if (rawId is int) {
                id = rawId;
              } else if (rawId is String) {
                id = int.tryParse(rawId) ?? -1;
              } else {
                id = -1;
              }

              if (idSet.contains(id)) {
                s['selected'] = true;
              }
            }
          }
          print('✅ Repository: Marked ${idSet.length} selected scenarios based on selectedScenarios');
        }

        return {
          'seller': data['seller'],
          'buyers': data['buyers'],
          'items': data['items'],
          'scenarios': scenarios, // ✅ Scenarios from either endpoint with selected flag
        };
      }

      print('❌ Repository: API returned success=false');
      print('❌ Repository: Message: ${response['message']}');
      throw Exception(response['message'] ?? 'Failed to load invoice create data');
    } catch (e) {
      print('❌ Repository: Exception: $e');
      rethrow;
    }
  }

  // ───── Create Draft Invoice ─────
  Future<InvoiceModel> createInvoice({
    required int busConfigId,
    int? tenantId,
  }) async {
    try {
      final fields = <String, dynamic>{
        'bus_config_id': busConfigId.toString(),
        if (tenantId != null) 'tenant_id': tenantId.toString(),
      };

      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesCreate,
        fields: fields,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return InvoiceModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to create invoice');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Fetch Invoice for Edit ─────
  Future<Map<String, dynamic>> fetchInvoiceForEdit({
    required int invoiceId,
    int? tenantId,
  }) async {
    try {
      final fields = <String, dynamic>{
        'invoice_id': invoiceId.toString(),
        if (tenantId != null) 'tenant_id': tenantId.toString(),
      };

      print('📝 Repository: Fetching invoice for edit');
      print('📝 Repository: Endpoint: ${ApiEndpoints.invoicesEdit}');
      print('📝 Repository: Fields: $fields');

      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesEdit,
        fields: fields,
        requiresAuth: true,
      );

      print('📝 Repository: API Response received');
      print('📝 Repository: Success: ${response['success']}');
      print('📝 Repository: Message: ${response['message']}');
      print('📝 Repository: Response keys: ${response.keys.toList()}');

      // ✅ Check if response has 'success' field OR has 'data' field (some APIs don't send success field)
      final hasSuccess = response.containsKey('success');
      final isSuccess = hasSuccess ? (response['success'] == true) : response.containsKey('data');

      if (isSuccess) {
        // API shape:
        // {
        //   "data": { ...invoice fields..., "buyer": {...}, "seller": {...}, "details": [...] },
        //   "buyers": [ ... ],
        //   "items": [ ... ],
        //   "scenarios": [ ... ] (optional)
        // }

        final invoiceJson = (response['data'] ?? {}) as Map<String, dynamic>;
        final buyers = response['buyers'];
        final items = response['items'];
        final scenarios = response['scenarios'];

        print('✅ Repository: Invoice data parsed successfully');
        print('📋 Repository: Invoice ID: ${invoiceJson['invoice_id']}');
        print('📋 Repository: QR Code URL: ${invoiceJson['qr_code_url']}');
        print('📋 Repository: QR Code (relative): ${invoiceJson['qr_code']}');
        print('📋 Repository: Buyers count: ${(buyers as List?)?.length ?? 0}');
        print('📋 Repository: Items count: ${(items as List?)?.length ?? 0}');
        print('📋 Repository: Scenarios count: ${(scenarios as List?)?.length ?? 0}');

        return {
          'invoice': InvoiceModel.fromJson(invoiceJson),
          'buyers': buyers,
          'items': items,
          'seller': invoiceJson['seller'],
          'scenarios': scenarios, // may be null if API doesn't send it
        };
      }

      print('❌ Repository: API returned success=false or missing data');
      print('❌ Repository: Error message: ${response['message']}');
      throw Exception(response['message'] ?? 'Failed to fetch invoice');
    } catch (e) {
      print('❌ Repository: Exception caught: $e');
      rethrow;
    }
  }

  // ───── Update Invoice ─────
  Future<InvoiceModel> updateInvoice({
    required int invoiceId,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    required int buyerId,
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final fields = <String, dynamic>{
        'invoice_id': invoiceId.toString(),
        'invoice_date': invoiceDate,
        'due_date': dueDate,
        'scenario_id': scenarioId,
        'buyer_id': buyerId.toString(),
        if (notes != null) 'notes': notes,
      };

      // Add details as array
      for (int i = 0; i < details.length; i++) {
        final detail = details[i];
        fields['details[$i][item_id]'] = detail['item_id'].toString();
        fields['details[$i][quantity]'] = detail['quantity'].toString();
        if (detail['invoice_detail_id'] != null) {
          fields['details[$i][invoice_detail_id]'] =
              detail['invoice_detail_id'].toString();
        }
      }

      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesUpdate,
        fields: fields,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return InvoiceModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to update invoice');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Delete Invoice ─────
  Future<bool> deleteInvoice(int invoiceId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesDelete,
        fields: {'invoice_id': invoiceId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to delete invoice');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Post Invoice to FBR ─────
  Future<InvoiceModel> postToFBR(int invoiceId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.invoicesPostToFBR,
        fields: {'invoice_id': invoiceId.toString()},
        requiresAuth: true,
        requiresXOck: true,
      );

      if (response['success'] == true) {
        return InvoiceModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to post invoice to FBR');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Save Draft Invoice ─────
  Future<InvoiceModel> saveDraftInvoice({
    required int busConfigId,
    required String invoiceType,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    String? invoiceRefNo,
    required int sellerId,
    required int buyerId,
    required String buyerRegistrationType,
    required String sellerNTNCNIC,
    required String sellerBusinessName,
    required String sellerProvince,
    required String sellerAddress,
    required String buyerNTNCNIC,
    required String buyerProvince,
    required String buyerBusinessName,
    required String buyerAddress,
    required double totalAmountExcludingTax,
    required double totalAmountIncludingTax,
    required double totalSalesTax,
    required double totalFurtherTax,
    required double totalExtraTax,
    required double totalFedTax,
    required double totalDiscount,
    required double shippingCharges,
    required double otherCharges,
    required double discountAmount,
    required String paymentStatus,
    String? notes,
    required int invoiceStatus,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final body = {
        'bus_config_id': busConfigId,
        'invoice_created_from_web_api': 2,
        'invoiceType': invoiceType,
        'invoiceDate': invoiceDate,
        'due_date': dueDate,
        'scenarioId': scenarioId,
        if (invoiceRefNo != null) 'invoiceRefNo': invoiceRefNo,
        'seller_id': sellerId,
        'byr_id': buyerId,
        'buyerRegistrationType': buyerRegistrationType,
        'sellerNTNCNIC': sellerNTNCNIC,
        'sellerBusinessName': sellerBusinessName,
        'sellerProvince': sellerProvince,
        'sellerAddress': sellerAddress,
        'buyerNTNCNIC': buyerNTNCNIC,
        'buyerProvince': buyerProvince,
        'buyerBusinessName': buyerBusinessName,
        'buyerAddress': buyerAddress,
        'totalAmountExcludingTax': totalAmountExcludingTax,
        'totalAmountIncludingTax': totalAmountIncludingTax,
        'totalSalesTax': totalSalesTax,
        'totalfurtherTax': totalFurtherTax,
        'totalextraTax': totalExtraTax,
        'totalFedTax': totalFedTax,
        'totalDiscount': totalDiscount,
        'shipping_charges': shippingCharges,
        'other_charges': otherCharges,
        'discount_amount': discountAmount,
        'payment_status': paymentStatus,
        if (notes != null) 'notes': notes,
        'invoice_status': invoiceStatus,
        'items': items,
      };

      final response = await _apiClient.post(
        ApiEndpoints.invoicesSaveDraft,
        body: body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return InvoiceModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to save draft invoice');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Save or Post Invoice (Unified Endpoint) ─────
  Future<InvoiceModel> saveOrPostInvoice({
    int? invoiceId, // ✅ For edit mode
    required int busConfigId,
    required bool postNow, // ✅ false = draft, true = post to FBR
    required String invoiceStatus, // ✅ "draft" or "posted"
    required String invoiceType,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    String? invoiceRefNo,
    required int sellerId,
    required int buyerId,
    required String buyerRegistrationType,
    required String sellerNTNCNIC,
    required String sellerBusinessName,
    required String sellerProvince,
    required String sellerAddress,
    required String buyerNTNCNIC,
    required String buyerProvince,
    required String buyerBusinessName,
    required String buyerAddress,
    required double totalAmountExcludingTax,
    required double totalAmountIncludingTax,
    required double totalSalesTax,
    required double totalFurtherTax,
    required double totalExtraTax,
    required double totalFedTax,
    required double totalDiscount, 
    required double shippingCharges,
    required double otherCharges,
    required double discountAmount,
    required double grandTotal,
    required double paidAmount,
    required double balanceDue,
    required String paymentMethod,
    String? bankName,
    String? chequeNo,
    String? chequeDate,
    required String paymentStatus,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final body = {
        if (invoiceId != null) 'invoice_id': invoiceId, // ✅ For edit mode
        'bus_config_id': busConfigId,
        'invoice_created_from_web_api': 2,
        'post_now': postNow,
        'invoice_status': invoiceStatus,
        'invoiceType': invoiceType,
        'invoiceDate': invoiceDate,
        'due_date': dueDate,
        'scenarioId': scenarioId,
        'invoiceRefNo': invoiceRefNo ?? '',
        'seller_id': sellerId,
        'byr_id': buyerId,
        'buyerRegistrationType': buyerRegistrationType,
        'sellerNTNCNIC': sellerNTNCNIC,
        'sellerBusinessName': sellerBusinessName,
        'sellerProvince': sellerProvince,
        'sellerAddress': sellerAddress,
        'buyerNTNCNIC': buyerNTNCNIC,
        'buyerProvince': buyerProvince,
        'buyerBusinessName': buyerBusinessName,
        'buyerAddress': buyerAddress,
        'totalAmountExcludingTax': totalAmountExcludingTax,
        'totalSalesTax': totalSalesTax,
        'SalesTaxApplicable': totalSalesTax > 0,
        'totalfurtherTax': totalFurtherTax,
        'totalextraTax': totalExtraTax,
        'totalFedTax': totalFedTax,
        'totalDiscount': totalDiscount,
        'totalAmountIncludingTax': totalAmountIncludingTax,
        'shipping_charges': shippingCharges,
        'other_charges': otherCharges,
        'discount_amount': discountAmount,
        'grand_total': grandTotal,
        'paid_amount': paidAmount,
        'balance_due': balanceDue,
        'payment_method': paymentMethod,
        if (bankName != null) 'bank_name': bankName,
        if (chequeNo != null) 'cheque_no': chequeNo,
        if (chequeDate != null) 'cheque_date': chequeDate,
        'payment_status': paymentStatus,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'items': items,
      };

      // 🔍 Debug: Log payload before sending to API
      print('📤 [saveOrPostInvoice] postNow=$postNow, invoiceId=$invoiceId');
      print('📤 [saveOrPostInvoice] Endpoint: '+ApiEndpoints.invoicesSaveOrPost);
      print('📤 [saveOrPostInvoice] Payload:');
      body.forEach((key, value) {
        if (key == 'items') {
          print('   - items: (len=${items.length}) -> $items');
        } else {
          print('   - $key: $value');
        }
      });

      final response = await _apiClient.post(
        ApiEndpoints.invoicesSaveOrPost,
        body: body,
        requiresAuth: true,
        requiresXOck: true,
      );

      // 🔍 Debug: Log basic response info
      print('📥 [saveOrPostInvoice] Response success=${response['success']}');
      if (response.containsKey('message')) {
        print('📥 [saveOrPostInvoice] Message: ${response['message']}');
      }

      if (response['success'] == true) {
        final data = response['data'];
        // API returns { "invoice": {...}, "message": "..." }
        if (data is Map<String, dynamic> && data.containsKey('invoice')) {
          return InvoiceModel.fromJson(data['invoice']);
        }
        return InvoiceModel.fromJson(data);
      }
      throw Exception(response['message'] ?? 'Failed to save/post invoice');
    } catch (e) {
      rethrow;
    }
  }
}
