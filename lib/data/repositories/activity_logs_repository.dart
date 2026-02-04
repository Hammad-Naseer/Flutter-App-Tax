// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/activity_logs_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/activity_log_model.dart';

class ActivityLogsRepository {
  final ApiClient _api;
  ActivityLogsRepository(this._api);

  Future<Map<String, dynamic>> fetchLogs({int page = 1, String? query}) async {
    print('📋 Repository: Fetching activity logs - Page: $page, Query: "$query"');
    print('📋 Repository: API Endpoint: ${ApiEndpoints.activityLogs}');

    final res = await _api.get(
      ApiEndpoints.activityLogs,
      queryParams: {
        'page': page.toString(),
        if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
      },
      requiresAuth: true,
    );

    print('📋 Repository: API Response: $res');

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      print('📋 Repository: Data node: $data');

      final dataList = data['data'] as List;
      print('📋 Repository: Data list length: ${dataList.length}');

      final list = dataList
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList();

      print('📋 Repository: Parsed ${list.length} activity logs');

      return {
        'logs': list,
        'current_page': data['current_page'],
        'last_page': data['last_page'],
        'per_page': data['per_page'],
        'total': data['total'],
      };
    }

    print('❌ Repository: API call failed - ${res['message']}');
    throw Exception(res['message'] ?? 'Failed to fetch activity logs');
  }
}
