// ─────────────────────────────────────────────────────────────────────────────
// lib/features/more/controller/fbr_post_errors_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/fbr_error_model.dart';

class FbrPostErrorsController extends GetxController {
  final _api = Get.put(ApiClient(), permanent: true);

  // State
  final errors = <FbrPostErrorModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final query = ''.obs;

  // Pagination
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final perPage = 10.obs;
  final total = 0.obs;

  // Local filtered view so search works even if backend does not filter
  List<FbrPostErrorModel> get filteredErrors {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return errors;
    return errors.where((e) {
      final type = (e.type ?? '').toLowerCase();
      final code = (e.errorCode ?? '').toLowerCase();
      final msg = (e.error ?? '').toLowerCase();
      final status = (e.status ?? '').toLowerCase();
      return type.contains(q) || code.contains(q) || msg.contains(q) || status.contains(q);
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
        ApiEndpoints.fbrErrors,
        queryParams: {
          'page': page.toString(),
          // Use 'search' key so backend can filter FBR errors by query
          if (query.value.isNotEmpty) 'search': query.value,
        },
      );

      final dataNode = res['data'];
      if (dataNode is Map<String, dynamic>) {
        final items = (dataNode['data'] as List<dynamic>? ?? [])
            .map((e) => FbrPostErrorModel.fromJson(e as Map<String, dynamic>))
            .toList();

        currentPage.value = (dataNode['current_page'] as num?)?.toInt() ?? page;
        lastPage.value = (dataNode['last_page'] as num?)?.toInt() ?? page;
        perPage.value = (dataNode['per_page'] as num?)?.toInt() ?? items.length;
        total.value = (dataNode['total'] as num?)?.toInt() ?? items.length;

        if (reset) {
          errors.assignAll(items);
        } else {
          errors.addAll(items);
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
