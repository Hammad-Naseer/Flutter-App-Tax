class AuditLogModel {
  final int auditId;
  final String tableName;
  final int? rowId;
  final String actionType;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? rowHashOld;
  final String? rowHashNew;
  final String? dbUser;
  final DateTime? changedAt;
  final String? ipAddress;
  final String? deviceInfo;
  final bool tampered;
  final Map<String, dynamic>? changes;

  AuditLogModel({
    required this.auditId,
    required this.tableName,
    required this.actionType,
    this.rowId,
    this.oldData,
    this.newData,
    this.rowHashOld,
    this.rowHashNew,
    this.dbUser,
    this.changedAt,
    this.ipAddress,
    this.deviceInfo,
    this.tampered = false,
    this.changes,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }

    return AuditLogModel(
      auditId: json['audit_id'] is int ? json['audit_id'] : int.tryParse('${json['audit_id']}') ?? 0,
      tableName: json['table_name']?.toString() ?? '-',
      rowId: json['row_id'] is int ? json['row_id'] : int.tryParse('${json['row_id']}'),
      actionType: json['action_type']?.toString() ?? '-',
      oldData: json['old_data'] is Map<String, dynamic> ? (json['old_data'] as Map<String, dynamic>) : null,
      newData: json['new_data'] is Map<String, dynamic> ? (json['new_data'] as Map<String, dynamic>) : null,
      rowHashOld: json['row_hash_old']?.toString(),
      rowHashNew: json['row_hash_new']?.toString(),
      dbUser: json['db_user']?.toString(),
      changedAt: _parseDate(json['changed_at']),
      ipAddress: json['ip_address']?.toString(),
      deviceInfo: json['device_info']?.toString(),
      tampered: json['tampered'] == true,
      changes: json['changes'] is Map<String, dynamic> ? (json['changes'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'audit_id': auditId,
        'table_name': tableName,
        'row_id': rowId,
        'action_type': actionType,
        'old_data': oldData,
        'new_data': newData,
        'row_hash_old': rowHashOld,
        'row_hash_new': rowHashNew,
        'db_user': dbUser,
        'changed_at': changedAt?.toIso8601String(),
        'ip_address': ipAddress,
        'device_info': deviceInfo,
        'tampered': tampered,
        'changes': changes,
      };
}
