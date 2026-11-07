import 'package:flutter/material.dart';

class RiskReason {
  final String? rule;
  final int? score;
  final String? detail;
  RiskReason({this.rule, this.score, this.detail});
  factory RiskReason.fromJson(Map<String, dynamic> j) =>
      RiskReason(rule: j['rule'], score: j['score'], detail: j['detail']);
  Map<String, dynamic> toJson() => {'rule': rule, 'score': score, 'detail': detail};
}

class Risk {
  final String? ipAddress, countryCode, country, city, level, alertStatus;
  final int? score, alertId;
  final List<RiskReason> reasons;

  Risk({
    this.ipAddress,
    this.countryCode,
    this.country,
    this.city,
    this.level,
    this.alertStatus,
    this.score,
    this.alertId,
    this.reasons = const [],
  });

  /// Nullable-safe parse: returns null when [j] is not a map.
  static Risk? maybe(dynamic j) {
    if (j is! Map) return null;
    return Risk(
      ipAddress: j['ip_address'],
      countryCode: j['country_code'],
      country: j['country'],
      city: j['city'],
      level: j['level'],
      alertStatus: j['alert_status'],
      score: j['score'],
      alertId: j['alert_id'],
      reasons: (j['reasons'] as List? ?? [])
          .map((x) => RiskReason.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ip_address': ipAddress,
        'country_code': countryCode,
        'country': country,
        'city': city,
        'level': level,
        'alert_status': alertStatus,
        'score': score,
        'alert_id': alertId,
        'reasons': reasons.map((e) => e.toJson()).toList(),
      };

  /// "city, country" or null when both unknown.
  String? get location {
    final p = [city, country].where((e) => e != null && e.isNotEmpty);
    return p.isEmpty ? null : p.join(', ');
  }

  // Colours come from server `level`, never from `score`.
  Color get color { // background
    switch (level) {
      case 'red':
        return const Color(0xFFFFEBEE);
      case 'yellow':
        return const Color(0xFFFFF4DC);
      case 'green':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFF1F1F1);
    }
  }

  Color get accent { // text / icon / border
    switch (level) {
      case 'red':
        return const Color(0xFFD32F2F);
      case 'yellow':
        return const Color(0xFFB7791F);
      case 'green':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  String get labelKey =>
      level == 'red' ? 'risk_high' : level == 'yellow' ? 'risk_suspicious' : 'risk_normal';
}
