import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/activity_log_model.dart';
import '../controller/activity_logs_controller.dart';
import '../../navigation/nav_controller.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ActivityLogsController>();
    final navCtrl = Get.find<NavController>();
    // Ensure More tab is highlighted
    navCtrl.currentIndex.value = 3;

    // Ensure data is loaded if controller already existed without data
    if (ctrl.logs.isEmpty && !ctrl.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.fetch(firstLoad: true);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Logs', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(ctx).maybePop(),
          ),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: ctrl.searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                onChanged: (v) => ctrl.onSearchChanged(v),
              ),
            ),
            Expanded(
              child: ctrl.isLoading.value && ctrl.logs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => ctrl.reload(),
                      child: ctrl.filteredLogs.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                              children: const [
                                Center(
                                  child: Text(
                                    'No activity logs found',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (sn) {
                                if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 200) {
                                  ctrl.loadMore();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: ctrl.filteredLogs.length + (ctrl.isLoadingMore.value ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= ctrl.filteredLogs.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final log = ctrl.filteredLogs[index];
                                  final expanded = ctrl.expanded.contains(log.id);
                                  return _logCard(log, expanded: expanded, onToggle: () => ctrl.toggleExpand(log.id));
                                },
                              ),
                            ),
                    ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: navCtrl.currentIndex.value,
        onTap: navCtrl.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      )),
    );
  }

  Widget _logCard(ActivityLogModel log, {required bool expanded, required VoidCallback onToggle}) {
    Color typeColor(String t) {
      switch (t.toLowerCase()) {
        case 'add':
          return Colors.green;
        case 'update':
          return Colors.blue;
        case 'delete':
          return Colors.red;
        default:
          return AppColors.textSecondary;
      }
    }

    final color = typeColor(log.action);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggle,
        child: IntrinsicHeight(
          child: Row(children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _chip(log.action.capitalizeFirst ?? log.action, color),
                      const SizedBox(width: 8),
                      _chip(_mapTable(log.tableName), AppColors.textSecondary),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      log.description,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    if (log.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _fmtDateTime(log.createdAt!),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    if (expanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: _kv('User', log.userName ?? '-')),
                              Expanded(child: _kv('IP Address', log.ipAddress ?? '-')),
                            ]),
                            const SizedBox(height: 6),
                            _kv('Device', log.deviceId ?? 'unknown'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (log.diff != null && log.diff!.isNotEmpty) _diffBox(log.diff!),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  String _mapTable(String t) {
    switch (t) {
      case 'items':
        return 'Items';
      case 'buyers':
        return 'Clients';
      case 'invoices':
        return 'Invoices';
      default:
        return t.capitalizeFirst ?? t;
    }
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _diffBox(Map<String, dynamic> diff) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Changed Data', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...diff.entries.map((e) {
            final key = e.key;
            final val = e.value;
            String oldV = '-';
            String newV = '-';
            if (val is Map) {
              oldV = val['old']?.toString() ?? '-';
              newV = val['new']?.toString() ?? '-';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Text(oldV, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_right_alt, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(newV, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700))),
                  ]),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  String _fmtDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${_pad(dt.day)}-${_mon(dt.month)}-${dt.year} ${_pad(dt.hour)}:${_pad(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
  String _mon(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}
