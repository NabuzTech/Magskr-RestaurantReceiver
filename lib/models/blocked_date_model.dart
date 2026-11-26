/// A row of `booking-blocked-dates`. Dates stay "yyyy-MM-dd" strings so no
/// timezone conversion can shift the day. Both ends are inclusive.
class BlockedDateModel {
  final int? id;
  final int? serviceId;
  final String? name;
  final String startDate;
  final String endDate;
  final String appliesTo; // all | reservation | booking
  final bool isActive;

  BlockedDateModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        serviceId = json['service_id'],
        name = json['name'],
        startDate = json['start_date'] ?? '',
        endDate = json['end_date'] ?? json['start_date'] ?? '',
        appliesTo = json['applies_to'] ?? 'all',
        isActive = json['is_active'] ?? true;
}

/// Create/update body. `end_date` is always sent (a range can be shrunk back to
/// one day), and `service_id` is forced to null for table reservations because
/// the API rejects that combination.
Map<String, dynamic> blockedDateBody({
  required int storeId,
  required String name,
  required DateTime start,
  DateTime? end,
  required String appliesTo,
  int? serviceId,
  required bool isActive,
}) {
  String iso(DateTime d) => d.toIso8601String().substring(0, 10);
  return {
    'store_id': storeId,
    'name': name.trim(),
    'start_date': iso(start),
    'end_date': iso(end ?? start),
    'applies_to': appliesTo,
    'service_id': appliesTo == 'reservation' ? null : serviceId,
    'is_active': isActive,
  };
}
