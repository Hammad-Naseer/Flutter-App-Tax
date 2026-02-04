class InvoiceLedgerEntry {
  final int entryId;
  final int invoiceId;
  final String entryType;
  final String buyerPaidAmount;
  final String debit;
  final String credit;
  final String balanceAfter;
  final String description;
  final Map<String, dynamic>? metadata;
  final int createdBy;
  final String createdAt;
  final String updatedAt;
  final InvoiceSummary? invoice;

  InvoiceLedgerEntry({
    required this.entryId,
    required this.invoiceId,
    required this.entryType,
    required this.buyerPaidAmount,
    required this.debit,
    required this.credit,
    required this.balanceAfter,
    required this.description,
    this.metadata,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.invoice,
  });

  factory InvoiceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return InvoiceLedgerEntry(
      entryId: (json['entry_id'] as num).toInt(),
      invoiceId: (json['invoice_id'] as num).toInt(),
      entryType: (json['entry_type'] ?? '').toString(),
      buyerPaidAmount: (json['buyer_paid_amount'] ?? '0.00').toString(),
      debit: (json['debit'] ?? '0.00').toString(),
      credit: (json['credit'] ?? '0.00').toString(),
      balanceAfter: (json['balance_after'] ?? '0.00').toString(),
      description: (json['description'] ?? '').toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: (json['created_by'] as num? ?? 0).toInt(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      invoice: json['invoice'] != null ? InvoiceSummary.fromJson(json['invoice']) : null,
    );
  }
}

class InvoiceSummary {
  final int invoiceId;
  final String invoiceNo;
  final String? invoiceDate;
  final String? fbrInvoiceNumber;
  final String? grandTotal;
  final String? responseStatus;

  InvoiceSummary({
    required this.invoiceId,
    required this.invoiceNo,
    this.invoiceDate,
    this.fbrInvoiceNumber,
    this.grandTotal,
    this.responseStatus,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      invoiceId: (json['invoice_id'] as num).toInt(),
      invoiceNo: (json['invoice_no'] ?? '').toString(),
      invoiceDate: (json['invoice_date'] ?? '').toString(),
      fbrInvoiceNumber: json['fbr_invoice_number']?.toString(),
      grandTotal: json['grand_total']?.toString(),
      responseStatus: json['response_status']?.toString(),
    );
  }
}

class InvoiceLedgerResponse {
  final List<InvoiceLedgerEntry> entries;
  final int currentPage;
  final int lastPage;
  final int total;

  InvoiceLedgerResponse({
    required this.entries,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory InvoiceLedgerResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return InvoiceLedgerResponse(
      entries: list.map((e) => InvoiceLedgerEntry.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: (json['current_page'] as num? ?? 1).toInt(),
      lastPage: (json['last_page'] as num? ?? 1).toInt(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}
