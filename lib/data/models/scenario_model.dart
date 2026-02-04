// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/scenario_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ScenarioModel {
  final String scenarioCode;
  final String scenarioDescription;
  final String saleType;
  final bool selected;

  ScenarioModel({
    required this.scenarioCode,
    required this.scenarioDescription,
    required this.saleType,
    this.selected = false,
  });

  factory ScenarioModel.fromJson(Map<String, dynamic> json) {
    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    }

    return ScenarioModel(
      scenarioCode: json['scenario_code'] ?? '',
      scenarioDescription: json['scenario_description'] ?? '',
      saleType: json['sale_type'] ?? '',
      selected: _toBool(json['selected']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario_code': scenarioCode,
      'scenario_description': scenarioDescription,
      'sale_type': saleType,
      'selected': selected,
    };
  }

  ScenarioModel copyWith({
    String? scenarioCode,
    String? scenarioDescription,
    String? saleType,
    bool? selected,
  }) {
    return ScenarioModel(
      scenarioCode: scenarioCode ?? this.scenarioCode,
      scenarioDescription: scenarioDescription ?? this.scenarioDescription,
      saleType: saleType ?? this.saleType,
      selected: selected ?? this.selected,
    );
  }
}

