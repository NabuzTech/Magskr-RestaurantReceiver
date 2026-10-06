class GetReservationV2ByDateRange {
  int? id;
  int? storeId;
  dynamic userId;
  int? partySize;
  String? reservedFor;
  String? reservedUntil;
  int? durationMinutes;
  String? status;
  dynamic tableNumber;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  String? createdAt;

  GetReservationV2ByDateRange(
      {this.id,
      this.storeId,
      this.userId,
      this.partySize,
      this.reservedFor,
      this.reservedUntil,
      this.durationMinutes,
      this.status,
      this.tableNumber,
      this.customerName,
      this.customerPhone,
      this.customerEmail,
      this.note,
      this.createdAt});

  GetReservationV2ByDateRange.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    userId = json['user_id'];
    partySize = json['party_size'];
    reservedFor = json['reserved_for'];
    reservedUntil = json['reserved_until'];
    durationMinutes = json['duration_minutes'];
    status = json['status'];
    tableNumber = json['table_number'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['user_id'] = userId;
    data['party_size'] = partySize;
    data['reserved_for'] = reservedFor;
    data['reserved_until'] = reservedUntil;
    data['duration_minutes'] = durationMinutes;
    data['status'] = status;
    data['table_number'] = tableNumber;
    data['customer_name'] = customerName;
    data['customer_phone'] = customerPhone;
    data['customer_email'] = customerEmail;
    data['note'] = note;
    data['created_at'] = createdAt;
    return data;
  }
}
