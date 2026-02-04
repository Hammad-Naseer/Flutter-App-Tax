import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/invoice_ledger_model.dart';

class InvoiceLedgerRepository {
  final ApiClient _api;
  InvoiceLedgerRepository(this._api);

  Future<InvoiceLedgerResponse> fetch({
    int page = 1,
    int? buyerId,
    int? invoiceId,
    String? entryType,
    String? startDate,
    String? endDate,
  }) async {
    final qp = <String, String>{'page': page.toString()};

    final prefs = await SharedPreferences.getInstance();
    final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id');
    if (busConfigId != null && busConfigId.isNotEmpty) {
      qp['bus_config_id'] = busConfigId;
    }

    if (buyerId != null) qp['buyer_id'] = buyerId.toString();
    if (invoiceId != null) qp['invoice_id'] = invoiceId.toString();
    if (entryType != null && entryType != 'all') qp['entry_type'] = entryType;
    if (startDate != null && startDate.isNotEmpty) qp['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) qp['end_date'] = endDate;

    final res = await _api.get(ApiEndpoints.invoiceLedger, queryParams: qp, requiresAuth: true);

    if (res['success'] == true) {
      return InvoiceLedgerResponse.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw Exception(res['message'] ?? 'Failed to load invoice ledger');
  }
}
