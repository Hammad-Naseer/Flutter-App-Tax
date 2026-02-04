import 'client_model.dart';

class ClientLedgerEntry {
  final int ledgerId;
  final int buyerId;
  final String totalInvoiced;
  final String totalPaid;
  final String invBalAmount;
  final String totalBalance;
  final String totalOverdue;
  final int overdueInvoiceCount;
  final String? lastPaymentDate;
  final String createdAt;
  final ClientModel? buyer;

  ClientLedgerEntry({
    required this.ledgerId,
    required this.buyerId,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.invBalAmount,
    required this.totalBalance,
    required this.totalOverdue,
    required this.overdueInvoiceCount,
    this.lastPaymentDate,
    required this.createdAt,
    this.buyer,
  });

  factory ClientLedgerEntry.fromJson(Map<String, dynamic> json) {
    return ClientLedgerEntry(
      ledgerId: (json['ledger_id'] as num).toInt(),
      buyerId: (json['buyer_id'] as num).toInt(),
      totalInvoiced: (json['total_invoiced'] ?? '0.00').toString(),
      totalPaid: (json['total_paid'] ?? '0.00').toString(),
      invBalAmount: (json['inv_bal_amount'] ?? '0.00').toString(),
      totalBalance: (json['total_balance'] ?? '0.00').toString(),
      totalOverdue: (json['total_overdue'] ?? '0.00').toString(),
      overdueInvoiceCount: (json['overdue_invoice_count'] as num? ?? 0).toInt(),
      lastPaymentDate: json['last_payment_date']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      buyer: json['buyer'] != null ? ClientModel.fromJson(json['buyer']) : null,
    );
  }
}

class ClientLedgerResponse {
  final List<ClientLedgerEntry> entries;
  final int currentPage;
  final int lastPage;
  final int total;
  final String totalInvoiced;
  final String totalPaid;
  final String totalBalance;

  ClientLedgerResponse({
    required this.entries,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalBalance,
  });

  factory ClientLedgerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    return ClientLedgerResponse(
      entries: data.map((e) => ClientLedgerEntry.fromJson(e)).toList(),
      currentPage: (json['current_page'] as num? ?? 1).toInt(),
      lastPage: (json['last_page'] as num? ?? 1).toInt(),
      total: (json['total'] as num? ?? 0).toInt(),
      totalInvoiced: (json['total_invoiced'] ?? '0.00').toString(),
      totalPaid: (json['total_paid'] ?? '0.00').toString(),
      totalBalance: (json['total_balance'] ?? '0.00').toString(),
    );
  }
}
