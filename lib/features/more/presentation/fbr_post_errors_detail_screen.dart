// ─────────────────────────────────────────────────────────────────────────────
// lib/features/more/presentation/fbr_post_errors_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/fbr_error_model.dart';

class FbrPostErrorsDetailScreen extends StatelessWidget {
  final FbrPostErrorModel error;
  const FbrPostErrorsDetailScreen({super.key, required this.error});

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

  @override
  Widget build(BuildContext context) {
    final status = (error.status ?? '').toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text('Error #${error.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kv('Type', (error.type ?? '-').toUpperCase()),
          _kv('Status', status),
          _kv('Error Code', error.errorCode ?? '-'),
          _kv('Status Code', error.statusCode?.toString() ?? '-'),
          _kv('Environment', (error.fbrEnv ?? '-').toUpperCase()),
          _kv('Error Time', fmtDate(error.errorTime)),
          const SizedBox(height: 12),
          const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(error.error ?? '-'),
          const SizedBox(height: 16),
          if (error.invoiceStatuses.isNotEmpty) ...[
            const Text('Invoice Statuses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...error.invoiceStatuses.map((s) => _statusTile(s)).toList(),
            const SizedBox(height: 16),
          ],
          if (error.rawResponse != null) ...[
            const Text('Raw Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text(error.rawResponse.toString()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(FbrInvoiceStatusModel s) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Item SNo: ${s.itemSNo ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(s.status ?? '-', style: const TextStyle(color: Colors.red)),
          ]),
          const SizedBox(height: 6),
          Text(s.error ?? '-'),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Error Code: ', style: TextStyle(color: Colors.grey)),
            Text(s.errorCode ?? '-')
          ]),
          if ((s.invoiceNo ?? '').isNotEmpty) Row(children: [
            const Text('Invoice No: ', style: TextStyle(color: Colors.grey)),
            Text(s.invoiceNo ?? '-')
          ]),
        ]),
      ),
    );
  }
}
