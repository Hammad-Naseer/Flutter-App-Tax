class ReceiptVoucherModel {
  final int paymentId;
  final String paymentNo;
  final int? buyerId;
  final int? invoiceId;
  final String paymentDate; // YYYY-MM-DD
  final String paymentAmount; // keep as string to match API
  final String paymentMethod; // cash / bank_transfer / cheque
  final String? referenceNo;
  final String? bankName;
  final String? bankNameTransfer;
  final String? chequeNo;
  final String? chequeDate;
  final String? notes;
  final String? receivedByName;
  final String? buyerName;

  ReceiptVoucherModel({
    required this.paymentId,
    required this.paymentNo,
    this.buyerId,
    this.invoiceId,
    required this.paymentDate,
    required this.paymentAmount,
    required this.paymentMethod,
    this.referenceNo,
    this.bankName,
    this.bankNameTransfer,
    this.chequeNo,
    this.chequeDate,
    this.notes,
    this.receivedByName,
    this.buyerName,
  });

  factory ReceiptVoucherModel.fromJson(Map<String, dynamic> json) {
    final receivedBy = json['received_by'] as Map<String, dynamic>?;
    final buyer = json['buyer'] as Map<String, dynamic>?;
    return ReceiptVoucherModel(
      paymentId: (json['payment_id'] as num).toInt(),
      paymentNo: (json['payment_no'] ?? '').toString(),
      buyerId: (json['buyer_id'] as num?)?.toInt(),
      invoiceId: (json['invoice_id'] as num?)?.toInt(),
      paymentDate: (json['payment_date'] ?? '').toString(),
      paymentAmount: (json['payment_amount'] ?? '0.00').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      referenceNo: json['reference_no']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankNameTransfer: json['bank_name_transfer']?.toString(),
      chequeNo: json['cheque_no']?.toString(),
      chequeDate: json['cheque_date']?.toString(),
      notes: json['notes']?.toString(),
      receivedByName: receivedBy != null ? receivedBy['name']?.toString() : null,
      buyerName: buyer != null ? buyer['byr_name']?.toString() : null,
    );
  }
}
