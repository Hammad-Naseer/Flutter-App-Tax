// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/client_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ClientModel {
  final int byrId;
  final String byrName;
  final int byrType; // 0 = unregistered, 1 = registered
  final String? byrIdType; // NTN or CNIC
  final String? byrNtnCnic;
  final String? byrAddress;
  final String? byrProvince;
  final String? byrAccountTitle;
  final String? byrAccountNumber;
  final String? byrRegNum;
  final String? byrEmail;
  final String? byrContactNum;
  final String? byrContactPerson;
  final String? byrIBAN;
  final String? byrAccBranchName;
  final String? byrAccBranchCode;
  final String? byrSwiftCode;
  final String? byrLogo;
  final String? byrLogoUrl;
  final String? hash;
  final bool? tampered;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientModel({
    required this.byrId,
    required this.byrName,
    required this.byrType,
    this.byrIdType,
    this.byrNtnCnic,
    this.byrAddress,
    this.byrProvince,
    this.byrAccountTitle,
    this.byrAccountNumber,
    this.byrRegNum,
    this.byrEmail,
    this.byrContactNum,
    this.byrContactPerson,
    this.byrIBAN,
    this.byrAccBranchName,
    this.byrAccBranchCode,
    this.byrSwiftCode,
    this.byrLogo,
    this.byrLogoUrl,
    this.hash,
    this.tampered,
    this.createdAt,
    this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String? _toString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is int || v is double || v is bool) return v.toString();
      return null; // Ignore Map, List, etc.
    }

    bool? _toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return null;
    }

    return ClientModel(
      byrId: _toInt(json['byr_id']),
      byrName: _toString(json['byr_name']) ?? '',
      byrType: _toInt(json['byr_type']),
      byrIdType: _toString(json['byr_id_type']),
      byrNtnCnic: _toString(json['byr_ntn_cnic']),
      byrEmail: _toString(json['byr_email']),
      byrAddress: _toString(json['byr_address']),
      byrProvince: _toString(json['byr_province']),
      byrAccountTitle: _toString(json['byr_account_title']),
      byrAccountNumber: _toString(json['byr_account_number']),
      byrRegNum: _toString(json['byr_reg_num']),
      byrContactNum: _toString(json['byr_contact_num']),
      byrContactPerson: _toString(json['byr_contact_person']),
      byrIBAN: _toString(json['byr_IBAN'] ?? json['byr_iban']),
      byrAccBranchName: _toString(json['byr_acc_branch_name']),
      byrAccBranchCode: _toString(json['byr_acc_branch_code']),
      byrSwiftCode: _toString(json['byr_swift_code'] ?? json['byr_swift'] ?? json['swift_code']),
      byrLogo: _toString(json['byr_logo']),
      byrLogoUrl: _toString(json['byr_logo_url']),
      hash: _toString(json['hash']),
      tampered: _toBool(json['tampered']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'byr_id': byrId,
      'byr_name': byrName,
      'byr_type': byrType,
      'byr_id_type': byrIdType,
      'byr_ntn_cnic': byrNtnCnic,
      'byr_email': byrEmail,
      'byr_address': byrAddress,
      'byr_province': byrProvince,
      'byr_account_title': byrAccountTitle,
      'byr_account_number': byrAccountNumber,
      'byr_reg_num': byrRegNum,
      'byr_contact_num': byrContactNum,
      'byr_contact_person': byrContactPerson,
      'byr_IBAN': byrIBAN,
      'byr_acc_branch_name': byrAccBranchName,
      'byr_acc_branch_code': byrAccBranchCode,
      'byr_swift_code': byrSwiftCode,
      'byr_logo': byrLogo,
      'byr_logo_url': byrLogoUrl,
      'hash': hash,
      'tampered': tampered,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get typeLabel => byrType == 1 ? 'Registered' : 'Unregistered';

  String get displayId => byrNtnCnic ?? 'N/A';
}
