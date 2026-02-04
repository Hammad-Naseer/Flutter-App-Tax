import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/client_ledger_model.dart';

class ClientLedgerRepository {
  final ApiClient _api;
  ClientLedgerRepository(this._api);

  Future<ClientLedgerResponse> fetch({
    int page = 1,
    int? buyerId,
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
    if (startDate != null && startDate.isNotEmpty) qp['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) qp['end_date'] = endDate;

    final res = await _api.get(ApiEndpoints.clientLedger, queryParams: qp, requiresAuth: true);

    if (res['success'] == true) {
      return ClientLedgerResponse.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw Exception(res['message'] ?? 'Failed to load client ledger');
  }
}
