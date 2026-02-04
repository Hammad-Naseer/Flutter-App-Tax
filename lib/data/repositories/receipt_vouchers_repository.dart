import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/receipt_voucher_model.dart';

class ReceiptVouchersRepository {
  final ApiClient _api;
  ReceiptVouchersRepository(this._api);

  Future<Map<String, dynamic>> fetch({
    int page = 1,
    int? buyerId,
    String? startDate,
    String? endDate,
    String? method, // cash, bank_transfer, cheque or null
  }) async {
    final qp = <String, String>{'page': page.toString()};

    // Include bus_config_id if available (consistent with other repositories)
    final prefs = await SharedPreferences.getInstance();
    final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id');
    if (busConfigId != null && busConfigId.isNotEmpty) {
      qp['bus_config_id'] = busConfigId;
    }

    if (buyerId != null) qp['buyer_id'] = buyerId.toString();
    if (startDate != null && startDate.isNotEmpty) qp['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) qp['end_date'] = endDate;
    if (method != null && method.isNotEmpty && method.toLowerCase() != 'all') qp['method'] = method;

    final res = await _api.get(ApiEndpoints.receiptVouchers, queryParams: qp, requiresAuth: true);

    if (res['success'] == true) {
      final root = res['data'] as Map<String, dynamic>;
      final list = (root['data'] as List<dynamic>? ?? [])
          .map((e) => ReceiptVoucherModel.fromJson(e as Map<String, dynamic>))
          .toList();

      int _toInt(dynamic v) {
        if (v is int) return v;
        if (v is String) return int.tryParse(v) ?? 0;
        if (v is num) return v.toInt();
        return 0;
      }

      return {
        'list': list,
        'current_page': _toInt(root['current_page']),
        'last_page': _toInt(root['last_page']),
        'per_page': _toInt(root['per_page']),
        'total': _toInt(root['total']),
      };
    }
    throw Exception(res['message'] ?? 'Failed to load receipt vouchers');
  }

  // ───── Fetch by ID (Full Details) ─────
  Future<Map<String, dynamic>> fetchById(int paymentId) async {
    final qp = <String, String>{'payment_id': paymentId.toString()};
    
    final prefs = await SharedPreferences.getInstance();
    final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id');
    if (busConfigId != null && busConfigId.isNotEmpty) {
      qp['bus_config_id'] = busConfigId;
    }

    final res = await _api.get(ApiEndpoints.receiptVouchersShow, queryParams: qp, requiresAuth: true);
    if (res['success'] == true) {
      return res['data'] as Map<String, dynamic>;
    }
    throw Exception(res['message'] ?? 'Failed to load receipt voucher details');
  }

  // ───── Buyer Balance ─────
  Future<Map<String, dynamic>> buyerBalance({required int buyerId}) async {
    final prefs = await SharedPreferences.getInstance();
    final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '1';
    final qp = <String, dynamic>{'buyer_id': buyerId.toString()};
    if (busConfigId.isNotEmpty) {
      qp['bus_config_id'] = busConfigId;
    }
    try {
      // Try GET first
      final res = await _api.get(ApiEndpoints.receiptVouchersBuyerBalance, queryParams: qp, requiresAuth: true);
      // Shape A: { success:true, data:{...} }
      if (res['success'] == true && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      // Shape B: direct payload { total_balance: ..., invoices: [...] }
      if (res is Map<String, dynamic> && res.containsKey('total_balance')) {
        return res as Map<String, dynamic>;
      }
    } catch (_) {
      // fall through to POST
    }

    // Some backends require POST form-data for this endpoint
    final fields = <String, dynamic>{'buyer_id': buyerId.toString()};
    if (busConfigId.isNotEmpty) {
      fields['bus_config_id'] = busConfigId;
    }
    final resPost = await _api.postFormData(
      ApiEndpoints.receiptVouchersBuyerBalance,
      fields: fields,
      requiresAuth: true,
    );
    // Shape A
    if (resPost['success'] == true && resPost['data'] is Map<String, dynamic>) {
      return resPost['data'] as Map<String, dynamic>;
    }
    // Shape B (direct)
    if (resPost is Map<String, dynamic> && resPost.containsKey('total_balance')) {
      return resPost as Map<String, dynamic>;
    }
    throw Exception((resPost['message'] ?? 'Failed to load buyer balance').toString());
  }

  // ───── Store Receipt Voucher ─────
  Future<Map<String, dynamic>> store({
    required int buyerId,
    required String paymentAmount,
    required String paymentDate, // YYYY-MM-DD
    required String paymentMethod, // cash | bank_transfer | cheque
    String? bankName,
    String? referenceNo,
    String? chequeNo,
    String? chequeDate, // YYYY-MM-DD
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'buyer_id': buyerId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName,
      if (referenceNo != null && referenceNo.isNotEmpty) 'reference_no': referenceNo,
      if (chequeNo != null && chequeNo.isNotEmpty) 'cheque_no': chequeNo,
      if (chequeDate != null && chequeDate.isNotEmpty) 'cheque_date': chequeDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final res = await _api.post(ApiEndpoints.receiptVouchersStore, body: body, requiresAuth: true);
    if (res['success'] == true) return res;
    throw Exception(res['message'] ?? 'Failed to create receipt voucher');
  }
}
