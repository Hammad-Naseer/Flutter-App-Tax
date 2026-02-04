// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/fbr_error_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class FbrInvoiceStatusModel {
  final String? error;
  final String? status;
  final String? itemSNo;
  final String? errorCode;
  final String? invoiceNo;
  final String? statusCode;

  FbrInvoiceStatusModel({
    this.error,
    this.status,
    this.itemSNo,
    this.errorCode,
    this.invoiceNo,
    this.statusCode,
  });

  factory FbrInvoiceStatusModel.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) => v?.toString();
    return FbrInvoiceStatusModel(
      error: s(json['error']),
      status: s(json['status']),
      itemSNo: s(json['itemSNo']),
      errorCode: s(json['errorCode']),
      invoiceNo: s(json['invoiceNo']),
      statusCode: s(json['statusCode']),
    );
  }
}

class FbrPostErrorModel {
  final int id;
  final String? type; // validation/posting
  final int? statusCode; // can be null
  final String? status; // Invalid/failed
  final String? errorCode; // e.g. 0099
  final String? error; // message
  final List<FbrInvoiceStatusModel> invoiceStatuses;
  final Map<String, dynamic>? rawResponse;
  final String? fbrEnv; // sandbox/production
  final DateTime? errorTime;

  FbrPostErrorModel({
    required this.id,
    this.type,
    this.statusCode,
    this.status,
    this.errorCode,
    this.error,
    required this.invoiceStatuses,
    this.rawResponse,
    this.fbrEnv,
    this.errorTime,
  });

  factory FbrPostErrorModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is double) return v.toInt();
      return null;
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final statuses = <FbrInvoiceStatusModel>[];
    final rawStatuses = json['invoice_statuses'];
    if (rawStatuses is List) {
      for (final s in rawStatuses) {
        if (s is Map<String, dynamic>) {
          statuses.add(FbrInvoiceStatusModel.fromJson(s));
        }
      }
    }

    final rawResp = json['raw_response'];
    Map<String, dynamic>? raw;
    if (rawResp is Map<String, dynamic>) raw = rawResp;

    return FbrPostErrorModel(
      id: toInt(json['id']) ?? 0,
      type: json['type']?.toString(),
      statusCode: toInt(json['status_code']),
      status: json['status']?.toString(),
      errorCode: json['error_code']?.toString(),
      error: json['error']?.toString(),
      invoiceStatuses: statuses,
      rawResponse: raw,
      fbrEnv: json['fbr_env']?.toString(),
      errorTime: toDate(json['error_time']),
    );
  }
}
