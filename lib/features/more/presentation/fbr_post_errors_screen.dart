import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/fbr_error_model.dart';
import '../controller/fbr_post_errors_controller.dart';
import 'fbr_post_errors_detail_screen.dart';

class FbrPostErrorsScreen extends StatelessWidget {
  const FbrPostErrorsScreen({super.key});

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'invalid':
      case 'failed':
        return Colors.red;
      case 'done':
      case 'success':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FbrPostErrorsController());
    c.refreshFirstPage();

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

    return Scaffold(
      appBar: AppBar(title: const Text('FBR Post Errors')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search errors... (type, code, message)',
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
            if (c.isLoading.value && c.errors.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.filteredErrors.isEmpty) {
              return const Center(child: Text('No FBR errors found'));
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
                  c.fetchNextPage();
                }
                return false;
              },
              child: ListView.separated(
                itemCount: c.filteredErrors.length + (c.isLoadingMore.value ? 1 : 0),
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  if (i >= c.filteredErrors.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final e = c.filteredErrors[i];
                  final statusColor = _statusColor(e.status);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: statusColor.withOpacity(.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text('ID #${e.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text((e.status ?? '').toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text((e.type ?? '').toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(e.error ?? '-', maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('Env', style: TextStyle(color: Colors.grey)),
                                    Text((e.fbrEnv ?? '-').toUpperCase()),
                                  ]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    const Text('Error Time', style: TextStyle(color: Colors.grey)),
                                    Text(fmtDate(e.errorTime)),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Get.to(() => FbrPostErrorsDetailScreen(error: e)),
                                icon: const Icon(Icons.remove_red_eye, size: 18),
                                label: const Text('View Details'),
                                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            )
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
      ]),
    );
  }
}
