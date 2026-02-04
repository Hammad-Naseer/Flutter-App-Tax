// ─────────────────────────────────────────────────────────────────────────────
// lib/features/audit_logs/presentation/audit_log_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/audit_log_model.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final AuditLogModel log;
  const AuditLogDetailScreen({super.key, required this.log});

  Color _statusColor(bool tampered) => tampered ? Colors.red : Colors.green;
  String _statusText(bool tampered) => tampered ? 'Tampered' : 'Safe';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Audit Log #${log.auditId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Text('Table: ${log.tableName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _kv('Row ID', (log.rowId ?? '-').toString()),
            _kv('Action', log.actionType),
            _kv('User', log.dbUser ?? '-'),
            _kv('IP', log.ipAddress ?? '-'),
            _kv('Device', log.deviceInfo ?? '-'),
            _kv('Changed At', log.changedAt?.toLocal().toString() ?? '-'),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(log.tampered).withOpacity(.12),
                  border: Border.all(color: _statusColor(log.tampered)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusText(log.tampered), style: TextStyle(color: _statusColor(log.tampered), fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _changesTable(log.changes),

            const SizedBox(height: 16),
            _expander('Old Data (JSON)', log.oldData),
            const SizedBox(height: 8),
            _expander('New Data (JSON)', log.newData),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text('$k:', style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  Widget _changesTable(Map<String, dynamic>? changes) {
    final rows = <TableRow>[];
    rows.add(const TableRow(children: [
      Padding(padding: EdgeInsets.all(8), child: Text('Field', style: TextStyle(fontWeight: FontWeight.bold))),
      Padding(padding: EdgeInsets.all(8), child: Text('Old Value', style: TextStyle(fontWeight: FontWeight.bold))),
      Padding(padding: EdgeInsets.all(8), child: Text('New Value', style: TextStyle(fontWeight: FontWeight.bold))),
    ]));
    if (changes != null && changes.isNotEmpty) {
      changes.forEach((key, value) {
        String oldV = '';
        String newV = '';
        if (value is Map<String, dynamic>) {
          oldV = '${value['old'] ?? ''}';
          newV = '${value['new'] ?? ''}';
        } else {
          newV = value.toString();
        }
        rows.add(TableRow(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(key)),
          Padding(padding: const EdgeInsets.all(8), child: Text(oldV)),
          Padding(padding: const EdgeInsets.all(8), child: Text(newV)),
        ]));
      });
    } else {
      rows.add(const TableRow(children: [
        Padding(padding: EdgeInsets.all(8), child: Text('-')),
        Padding(padding: EdgeInsets.all(8), child: Text('-')),
        Padding(padding: EdgeInsets.all(8), child: Text('-')),
      ]));
    }
    return Table(border: TableBorder.all(color: Colors.grey.shade300), columnWidths: const {
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(2),
    }, children: rows);
  }

  Widget _expander(String title, Map<String, dynamic>? json) {
    return Theme(
      data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _prettyJson(json),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return '{}';
    try {
      // Lightweight pretty printer
      final b = StringBuffer();
      b.writeln('{');
      final keys = map.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        final k = keys[i];
        final v = map[k];
        b.write('  \"$k\": ');
        b.write(v is String ? '\"$v\"' : '$v');
        if (i < keys.length - 1) b.writeln(',');
      }
      b.writeln('\n}');
      return b.toString();
    } catch (_) {
      return map.toString();
    }
  }
}
