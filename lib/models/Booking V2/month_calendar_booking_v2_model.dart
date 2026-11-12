class MonthCalendarBookingV2Model {
  int? id;
  int? storeId;
  int? userId;
  int? serviceId;
  int? resourceId;
  String? reference;
  String? startAt;
  String? endAt;
  String? blockedUntil;
  int? durationMinutes;
  int? partySize;
  int? units;
  String? status;
  String? paymentStatus;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  Map<String, dynamic>? formData;
  List<Map<String, dynamic>>? selectedOptions;
  double? priceTotal;
  double? depositAmount;
  String? currency;
  String? createdAt;

  MonthCalendarBookingV2Model.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num?)?.toInt();
    storeId = (json['store_id'] as num?)?.toInt();
    userId = (json['user_id'] as num?)?.toInt();
    serviceId = (json['service_id'] as num?)?.toInt();
    resourceId = (json['resource_id'] as num?)?.toInt();
    reference = json['reference'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    blockedUntil = json['blocked_until'];
    durationMinutes = (json['duration_minutes'] as num?)?.toInt();
    partySize = (json['party_size'] as num?)?.toInt();
    units = (json['units'] as num?)?.toInt();
    status = json['status'];
    paymentStatus = json['payment_status'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
    formData = json['form_data'] is Map
        ? Map<String, dynamic>.from(json['form_data'])
        : null;
    selectedOptions = json['selected_options'] is List
        ? (json['selected_options'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : null;
    priceTotal = (json['price_total'] as num?)?.toDouble();
    depositAmount = (json['deposit_amount'] as num?)?.toDouble();
    currency = json['currency'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'user_id': userId,
        'service_id': serviceId,
        'resource_id': resourceId,
        'reference': reference,
        'start_at': startAt,
        'end_at': endAt,
        'blocked_until': blockedUntil,
        'duration_minutes': durationMinutes,
        'party_size': partySize,
        'units': units,
        'status': status,
        'payment_status': paymentStatus,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'note': note,
        'form_data': formData,
        'selected_options': selectedOptions,
        'price_total': priceTotal,
        'deposit_amount': depositAmount,
        'currency': currency,
        'created_at': createdAt,
      };
}
