// ─────────────────────────────────────────────────────────────────────────────
// lib/features/audit_logs/controller/audit_logs_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/audit_log_model.dart';

class AuditLogsController extends GetxController {
  final _api = ApiClient();

  // State
  final logs = <AuditLogModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final query = ''.obs;

  // Pagination
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final perPage = 10.obs;
  final total = 0.obs;

  // Local filtered view so search works even if backend does not filter
  List<AuditLogModel> get filteredLogs {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return logs;
    return logs.where((log) {
      final table = log.tableName.toLowerCase();
      final action = log.actionType.toLowerCase();
      final user = (log.dbUser ?? '').toLowerCase();
      final rowId = (log.rowId?.toString() ?? '').toLowerCase();
      return table.contains(q) || action.contains(q) || user.contains(q) || rowId.contains(q);
    }).toList();
  }

  Future<void> refreshFirstPage() async {
    currentPage.value = 1;
    await fetchPage(page: 1, reset: true);
  }

  Future<void> fetchNextPage() async {
    if (isLoadingMore.value) return;
    if (currentPage.value >= lastPage.value) return;
    await fetchPage(page: currentPage.value + 1, reset: false);
  }

  Future<void> fetchPage({int page = 1, bool reset = false}) async {
    if (reset) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final res = await _api.get(
        ApiEndpoints.auditLogs,
        queryParams: {
          'page': page.toString(),
          // Use 'search' key so backend can filter audit logs by query
          if (query.value.isNotEmpty) 'search': query.value,
        },
      );

      final dataNode = res['data'];
      if (dataNode is Map<String, dynamic>) {
        final items = (dataNode['data'] as List<dynamic>? ?? [])
            .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
            .toList();

        currentPage.value = (dataNode['current_page'] as num?)?.toInt() ?? page;
        lastPage.value = (dataNode['last_page'] as num?)?.toInt() ?? page;
        perPage.value = (dataNode['per_page'] as num?)?.toInt() ?? items.length;
        total.value = (dataNode['total'] as num?)?.toInt() ?? items.length;

        if (reset) {
          logs.assignAll(items);
        } else {
          logs.addAll(items);
        }
      } else {
        throw NetworkException('Invalid response structure');
      }
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
