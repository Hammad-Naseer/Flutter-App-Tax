// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/service_item_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ServiceItemModel {
  final int itemId;
  final String itemDescription;
  final String? itemHsCode;
  final double itemPrice;
  final String? itemTaxRate;
  final String? itemUom; // Unit of Measurement
  final String? hash;
  final bool? tampered;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceItemModel({
    required this.itemId,
    required this.itemDescription,
    this.itemHsCode,
    required this.itemPrice,
    this.itemTaxRate,
    this.itemUom,
    this.hash,
    this.tampered,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    double _parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    return ServiceItemModel(
      itemId: _parseInt(json['item_id']),
      itemDescription: json['item_description'] ?? '',
      itemHsCode: json['item_hs_code'],
      itemPrice: _parseDouble(json['item_price']),
      itemTaxRate: json['item_tax_rate'],
      itemUom: json['item_uom'],
      hash: json['hash'],
      tampered: json['tampered'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_description': itemDescription,
      'item_hs_code': itemHsCode,
      'item_price': itemPrice,
      'item_tax_rate': itemTaxRate,
      'item_uom': itemUom,
      'hash': hash,
      'tampered': tampered,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedPrice => 'PKR ${itemPrice.toStringAsFixed(2)}';
}
