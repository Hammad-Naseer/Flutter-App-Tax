// ─────────────────────────────────────────────────────────────────────────────
// lib/features/audit_logs/presentation/audit_logs_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import '../../../core/utils/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../audit_logs/controller/audit_logs_controller.dart';
import '../../../data/models/audit_log_model.dart';
import 'audit_log_detail_screen.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  Color _actionColor(String a) {
    switch (a.toUpperCase()) {
      case 'INSERT':
        return Colors.green;
      case 'UPDATE':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AuditLogsController());
    c.refreshFirstPage();

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search audit logs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Live local filtering as user types
              onChanged: (v) {
                c.query.value = v.trim();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.logs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.filteredLogs.isEmpty) {
                return const Center(child: Text('No audit logs found'));
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
                    c.fetchNextPage();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: c.filteredLogs.length + (c.isLoadingMore.value ? 1 : 0),
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i >= c.filteredLogs.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final log = c.filteredLogs[i];
                    final tampered = log.tampered;
                    final statusBg = tampered ? Colors.red.shade100 : Colors.green.shade100;
                    final statusFg = tampered ? Colors.red.shade800 : Colors.green.shade800;
                    String fmtDate(DateTime? d) {
                      if (d == null) return '-';
                      final dt = d.toLocal();
                      final dd = dt.day.toString().padLeft(2, '0');
                      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                      final mm = months[dt.month - 1];
                      final yyyy = dt.year;
                      final hh = ((dt.hour % 12) == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
                      final min = dt.minute.toString().padLeft(2, '0');
                      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                      return '$dd-$mm-$yyyy $hh:$min $ampm';
                    }

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tampered ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _actionColor(log.actionType).withOpacity(.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      'Sr #${i + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      tampered ? 'Tampered' : 'Done',
                                      style: TextStyle(color: statusFg, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(log.tableName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text('Row ID: ${log.rowId ?? '-'}', style: const TextStyle(color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _actionColor(log.actionType).withOpacity(.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      log.actionType.toUpperCase(),
                                      style: TextStyle(color: _actionColor(log.actionType), fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('User', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          Text(
                                            log.dbUser ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Changed At', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          Text(
                                            fmtDate(log.changedAt),
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(fontSize: 13),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => Get.to(() => AuditLogDetailScreen(log: log)),
                                  icon: const Icon(Icons.remove_red_eye, size: 18),
                                  label: const Text('View Details'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
