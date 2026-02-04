// ─────────────────────────────────────────────────────────────────────────────
// lib/features/more/controller/activity_logs_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/activity_log_model.dart';
import '../../../data/repositories/activity_logs_repository.dart';

class ActivityLogsController extends GetxController {
  final ActivityLogsRepository _repo;
  ActivityLogsController(this._repo);

  // UI state
  final RxList<ActivityLogModel> logs = <ActivityLogModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxSet<int> expanded = <int>{}.obs;
  final TextEditingController searchCtrl = TextEditingController();

  // Pagination
  int _page = 1;
  int _lastPage = 1;
  String _query = '';
  Timer? _debounce;

  // Local filtered view so search works even if backend does not filter
  List<ActivityLogModel> get filteredLogs {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return logs;
    return logs.where((log) {
      final desc = log.description.toLowerCase();
      final table = log.tableName.toLowerCase();
      final action = log.action.toLowerCase();
      final user = (log.userName ?? '').toLowerCase();
      return desc.contains(q) || table.contains(q) || action.contains(q) || user.contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetch(firstLoad: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> fetch({bool firstLoad = false}) async {
    if (firstLoad) {
      isLoading.value = true;
      _page = 1;
      logs.clear();
    }
    try {
      print('📋 Fetching activity logs - Page: $_page, Query: "$_query"');
      final res = await _repo.fetchLogs(page: _page, query: _query);
      print('📋 Activity logs response: $res');

      final items = (res['logs'] as List<ActivityLogModel>);
      _lastPage = (res['last_page'] as int?) ?? 1;

      print('📋 Fetched ${items.length} logs, Last page: $_lastPage');

      if (firstLoad) {
        logs.assignAll(items);
      } else {
        logs.addAll(items);
      }

      print('📋 Total logs in list: ${logs.length}');
    } catch (e, stack) {
      print('❌ Error fetching activity logs: $e');
      print('❌ Stack trace: $stack');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> reload() async {
    _page = 1;
    await fetch(firstLoad: true);
  }

  void loadMore() {
    if (isLoadingMore.value || _page >= _lastPage) return;
    isLoadingMore.value = true;
    _page += 1;
    fetch();
  }

  void onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = v.trim();
      _page = 1;
      fetch(firstLoad: true);
    });
  }

  void toggleExpand(int id) {
    if (expanded.contains(id)) {
      expanded.remove(id);
    } else {
      expanded.add(id);
    }
  }
}
