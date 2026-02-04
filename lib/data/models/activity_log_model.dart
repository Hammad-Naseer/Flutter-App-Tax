// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/activity_log_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ActivityLogModel {
  final int id;
  final int? userId;
  final String? userName;
  final String? ipAddress;
  final String? deviceId;
  final String action; // add/update/delete
  final String tableName; // items, buyers, invoices
  final String description;
  final String? recordId;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? data; // may contain old/new or flat data
  final Map<String, dynamic>? diff; // key -> {old, new}

  ActivityLogModel({
    required this.id,
    required this.action,
    required this.tableName,
    required this.description,
    this.userId,
    this.userName,
    this.ipAddress,
    this.deviceId,
    this.recordId,
    this.createdAt,
    this.updatedAt,
    this.data,
    this.diff,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user_name']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      deviceId: json['device_id']?.toString(),
      action: json['action']?.toString() ?? '-',
      tableName: json['table_name']?.toString() ?? '-',
      description: json['description']?.toString() ?? '-',
      recordId: json['record_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      data: json['data'] is Map<String, dynamic> ? (json['data'] as Map<String, dynamic>) : null,
      diff: json['diff'] is Map<String, dynamic> ? (json['diff'] as Map<String, dynamic>) : null,
    );
  }
}
