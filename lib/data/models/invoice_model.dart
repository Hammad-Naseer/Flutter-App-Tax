// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/invoice_model.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'client_model.dart';
import 'service_item_model.dart';

class InvoiceModel {
  final int invoiceId;
  final String? invoiceNo;
  final String? invoiceType;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final String? scenarioId;
  final int? sellerId;
  final int? buyerId;
  final String? fbrInvoiceNumber;
  final String? qrCode;
  final int? isPostedToFbr; // 0 = draft, 1 = posted
  final int? invoiceStatus;
  final double? totalAmountExcludingTax;
  final double? totalSalesTax;
  final double? totalFurtherTax;
  final double? totalExtraTax;
  final double? totalAmount;
  final String? notes;
  final List<InvoiceDetailModel>? details;
  final ClientModel? buyer;
  final SellerModel? seller;
  final double? shippingCharges;
  final double? otherCharges;
  final double? discountAmount;
  final double? grandTotal;
  final double? paidAmount;
  final double? balanceDue;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? bankName;
  final String? chequeNo;
  final DateTime? chequeDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceModel({
    required this.invoiceId,
    this.invoiceNo,
    this.invoiceType,
    this.invoiceDate,
    this.dueDate,
    this.scenarioId,
    this.sellerId,
    this.buyerId,
    this.fbrInvoiceNumber,
    this.qrCode,
    this.isPostedToFbr,
    this.invoiceStatus,
    this.totalAmountExcludingTax,
    this.totalSalesTax,
    this.totalFurtherTax,
    this.totalExtraTax,
    this.totalAmount,
    this.notes,
    this.details,
    this.buyer,
    this.seller,
    this.shippingCharges,
    this.otherCharges,
    this.discountAmount,
    this.grandTotal,
    this.paidAmount,
    this.balanceDue,
    this.paymentMethod,
    this.paymentStatus,
    this.bankName,
    this.chequeNo,
    this.chequeDate,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final result = InvoiceModel(
      invoiceId: json['invoice_id'] ?? 0,
      invoiceNo: json['invoice_no'],
      invoiceType: json['invoice_type'],
      invoiceDate: json['invoice_date'] != null
          ? DateTime.tryParse(json['invoice_date'])
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      scenarioId: json['scenario_id']?.toString(),
      sellerId: json['seller_id'],
      buyerId: json['buyer_id'],
      fbrInvoiceNumber: json['fbr_invoice_number'],
      // ✅ Prefer full S3 URL from qr_code_url when present, otherwise fall back to qr_code (relative path)
      qrCode: _parseQrCode(json),
      isPostedToFbr: json['is_posted_to_fbr'],
      invoiceStatus: json['invoice_status'],
      totalAmountExcludingTax: _parseDouble(json['totalAmountExcludingTax']),
      totalSalesTax: _parseDouble(json['totalSalesTax']),
      totalFurtherTax: _parseDouble(json['totalfurtherTax']),
      totalExtraTax: _parseDouble(json['totalextraTax']),
      totalAmount: _parseDouble(json['totalAmountIncludingTax'] ?? json['grand_total']),
      notes: json['notes'],
      details: json['details'] != null
          ? (json['details'] as List)
              .map((d) => InvoiceDetailModel.fromJson(d))
              .toList()
          : null,
      buyer:
          json['buyer'] != null ? ClientModel.fromJson(json['buyer']) : null,
      seller:
          json['seller'] != null ? SellerModel.fromJson(json['seller']) : null,
      shippingCharges: _parseDouble(json['shipping_charges']),
      otherCharges: _parseDouble(json['other_charges']),
      discountAmount: _parseDouble(json['discount_amount']),
      grandTotal: _parseDouble(json['grand_total'] ?? json['totalAmountIncludingTax']),
      paidAmount: _parseDouble(json['paid_amount'] ?? json['payment_amount']),
      balanceDue: _parseDouble(json['balance_due']),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status']?.toString(),
      bankName: json['bank_name'],
      chequeNo: json['cheque_no'],
      chequeDate: json['cheque_date'] != null ? DateTime.tryParse(json['cheque_date']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
    
    // Debug logging for payment fields
    print('🔍 InvoiceModel.fromJson - Payment fields from API:');
    print('   paid_amount: ${json['paid_amount']}');
    print('   payment_amount (fallback): ${json['payment_amount']}');
    print('   payment_method: ${json['payment_method']}');
    print('   payment_status: ${json['payment_status']}');
    print('   bank_name: ${json['bank_name']}');
    print('   cheque_no: ${json['cheque_no']}');
    print('   cheque_date: ${json['cheque_date']}');
    print('   raw JSON: $json');
    
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'invoice_no': invoiceNo,
      'invoice_type': invoiceType,
      'invoice_date': invoiceDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'scenario_id': scenarioId,
      'seller_id': sellerId,
      'buyer_id': buyerId,
      'fbr_invoice_number': fbrInvoiceNumber,
      'qr_code': qrCode,
      'is_posted_to_fbr': isPostedToFbr,
      'invoice_status': invoiceStatus,
      'totalAmountExcludingTax': totalAmountExcludingTax,
      'totalSalesTax': totalSalesTax,
      'totalFurtherTax': totalFurtherTax,
      'totalExtraTax': totalExtraTax,
      'totalAmount': totalAmount,
      'notes': notes,
      'details': details?.map((d) => d.toJson()).toList(),
      'buyer': buyer?.toJson(),
      'seller': seller?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shipping_charges': shippingCharges,
      'other_charges': otherCharges,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'bank_name': bankName,
      'cheque_no': chequeNo,
      'cheque_date': chequeDate?.toIso8601String(),
    };
  }

  String get statusLabel {
    if (isPostedToFbr == 1) return 'Posted to FBR';
    return 'Draft';
  }

  String get formattedTotal => 'PKR ${(totalAmount ?? 0).toStringAsFixed(2)}';

  // ✅ Helper method to parse QR code from API response
  static String? _parseQrCode(Map<String, dynamic> json) {
    // Check for qr_code_url first (full S3 URL with auth tokens)
    if (json['qr_code_url'] != null && json['qr_code_url'].toString().isNotEmpty) {
      final qrCodeUrl = json['qr_code_url'].toString();
      print('✅ InvoiceModel: Using qr_code_url (full URL): $qrCodeUrl');
      return qrCodeUrl;
    }

    // Fall back to qr_code (relative path)
    if (json['qr_code'] != null && json['qr_code'].toString().isNotEmpty) {
      final qrCode = json['qr_code'].toString();
      print('✅ InvoiceModel: Using qr_code (relative path): $qrCode');
      return qrCode;
    }

    print('⚠️ InvoiceModel: No QR code found in API response');
    return null;
  }
}


// ───── Invoice Detail Model ─────
class InvoiceDetailModel {
  final int? invoiceDetailId;
  final int? invoiceId;
  final int? itemId;
  final int? quantity;
  final double? totalValue;
  final double? salesTaxApplicable;
  final double? furtherTaxApplicable;
  final double? extraTaxApplicable;
  final double? furtherTaxPercent;
  final double? extraTaxPercent;
  final double? fedPercent;
  final double? discount;
  final ServiceItemModel? item;

  InvoiceDetailModel({
    this.invoiceDetailId,
    this.invoiceId,
    this.itemId,
    this.quantity,
    this.totalValue,
    this.salesTaxApplicable,
    this.furtherTaxApplicable,
    this.extraTaxApplicable,
    this.furtherTaxPercent,
    this.extraTaxPercent,
    this.fedPercent,
    this.discount,
    this.item,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // --- Base amounts ---
    // ✅ CRITICAL: We need the Tax-Exclusive amount as the base for all calculations.
    // The API might send different field combinations:
    // - valueSalesExcludingST: Always the excluding-tax amount (preferred)
    // - total_value: Could be excluding OR including tax depending on API version
    // - totalValues: Usually the including-tax amount
    
    double salesTax = _parseDouble(json['sales_tax_applicable'] ?? json['SalesTaxApplicable']);
    double valueSalesExcludingST = _parseDouble(json['valueSalesExcludingST']);
    double totalValue = _parseDouble(json['total_value']);
    double totalValues = _parseDouble(json['totalValues']);

    print('🔍 InvoiceDetailModel parsing:');
    print('   valueSalesExcludingST: $valueSalesExcludingST');
    print('   total_value: $totalValue');
    print('   totalValues: $totalValues');
    print('   salesTax: $salesTax');

    double totalValExcl = 0;
    
    // Priority 1: Use valueSalesExcludingST if available (most reliable)
    if (valueSalesExcludingST > 0) {
      totalValExcl = valueSalesExcludingST;
      print('   ✅ Using valueSalesExcludingST: $totalValExcl');
    }
    // Priority 2: If total_value exists and totalValues also exists, check if they differ
    else if (totalValue > 0 && totalValues > 0) {
      // If totalValues = totalValue + salesTax, then totalValue is excluding tax
      final expectedInclusive = totalValue + salesTax;
      if ((totalValues - expectedInclusive).abs() < 0.01) {
        totalValExcl = totalValue;
        print('   ✅ Using total_value (verified as excluding): $totalValExcl');
      } else {
        // Otherwise, derive excluding from totalValues
        totalValExcl = totalValues - salesTax;
        print('   ⚠️ Deriving from totalValues - salesTax: $totalValExcl');
      }
    }
    // Priority 3: If only total_value exists, check if it includes tax
    else if (totalValue > 0) {
      // Assume total_value might be inclusive, so subtract sales tax
      if (salesTax > 0 && totalValue > salesTax) {
        totalValExcl = totalValue - salesTax;
        print('   ⚠️ Assuming total_value is inclusive, subtracting tax: $totalValExcl');
      } else {
        totalValExcl = totalValue;
        print('   ⚠️ Using total_value as-is: $totalValExcl');
      }
    }
    // Priority 4: Fall back to totalValues - salesTax
    else if (totalValues > 0) {
      totalValExcl = (totalValues > salesTax) ? (totalValues - salesTax) : totalValues;
      print('   ⚠️ Using totalValues - salesTax: $totalValExcl');
    }

    // API may use camelCase for item fields when saving, but snake_case when reading
    final furtherTaxAmt = _parseDouble(
      json['further_tax_applicable'] ?? json['further_tax'] ?? json['furtherTax'],
    );
    final extraTaxAmt = _parseDouble(
      json['extra_tax_applicable'] ?? json['extra_tax'] ?? json['extraTax'],
    );

    // FED is usually stored as payable amount per line item
    final fedPayableAmt = _parseDouble(json['fedPayable'] ?? json['fed_payable']);
    final discountAmt = _parseDouble(json['discount']);

    double _derivePercent(double amount) {
      if (totalValExcl <= 0) return 0.0;
      // Derive percentage from the amount and the EXCLUSIVE base
      return (amount * 100.0) / totalValExcl;
    }

    return InvoiceDetailModel(
      invoiceDetailId: json['invoice_detail_id'],
      invoiceId: json['invoice_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
      totalValue: totalValExcl, // Store excluding tax amount
      salesTaxApplicable: salesTax,
      furtherTaxApplicable: furtherTaxAmt,
      extraTaxApplicable: extraTaxAmt,
      furtherTaxPercent: _derivePercent(furtherTaxAmt),
      extraTaxPercent: _derivePercent(extraTaxAmt),
      fedPercent: _derivePercent(fedPayableAmt),
      discount: discountAmt,
      item: json['item'] != null
          ? ServiceItemModel.fromJson(json['item'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_detail_id': invoiceDetailId,
      'invoice_id': invoiceId,
      'item_id': itemId,
      'quantity': quantity,
      'total_value': totalValue,
      'sales_tax_applicable': salesTaxApplicable,
      'further_tax_applicable': furtherTaxApplicable,
      'extra_tax_applicable': extraTaxApplicable,
      'discount': discount,
      'item': item?.toJson(),
    };
  }
}

// ───── Seller Model ─────
class SellerModel {
  final int? busConfigId;
  final String? busName;
  final String? busNtnCnic;
  final String? busAddress;
  final String? busProvince;
  final String? busLogo;
  final String? busAccountTitle;
  final String? busAccountNumber;
  final String? busRegNum;
  final String? busContactNum;
  final String? busContactPerson;
  final String? busIBAN;
  final String? busAccBranchName;
  final String? busAccBranchCode;
  final String? busSwiftCode;

  SellerModel({
    this.busConfigId,
    this.busName,
    this.busNtnCnic,
    this.busAddress,
    this.busProvince,
    this.busLogo,
    this.busAccountTitle,
    this.busAccountNumber,
    this.busRegNum,
    this.busContactNum,
    this.busContactPerson,
    this.busIBAN,
    this.busAccBranchName,
    this.busAccBranchCode,
    this.busSwiftCode,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      busConfigId: json['bus_config_id'],
      busName: json['bus_name'],
      busNtnCnic: json['bus_ntn_cnic'],
      busAddress: json['bus_address'],
      busProvince: json['bus_province'],
      busLogo: json['bus_logo'],
      busAccountTitle: json['bus_account_title'],
      busAccountNumber: json['bus_account_number'],
      busRegNum: json['bus_reg_num'],
      busContactNum: json['bus_contact_num'],
      busContactPerson: json['bus_contact_person'],
      busIBAN: json['bus_IBAN'] ?? json['bus_iban'],
      busAccBranchName: json['bus_acc_branch_name'],
      busAccBranchCode: json['bus_acc_branch_code'],
      busSwiftCode: json['bus_swift_code'] ?? json['bus_swift'] ?? json['swift_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_config_id': busConfigId,
      'bus_name': busName,
      'bus_ntn_cnic': busNtnCnic,
      'bus_address': busAddress,
      'bus_province': busProvince,
      'bus_logo': busLogo,
      'bus_account_title': busAccountTitle,
      'bus_account_number': busAccountNumber,
      'bus_reg_num': busRegNum,
      'bus_contact_num': busContactNum,
      'bus_contact_person': busContactPerson,
      'bus_IBAN': busIBAN,
      'bus_acc_branch_name': busAccBranchName,
      'bus_acc_branch_code': busAccBranchCode,
      'bus_swift_code': busSwiftCode,
    };
  }
}
