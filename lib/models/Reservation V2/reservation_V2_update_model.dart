class ReservationV2UpdateModel {
  int? id;
  int? storeId;
  Null? userId;
  int? partySize;
  String? reservedFor;
  String? reservedUntil;
  int? durationMinutes;
  String? status;
  Null? tableNumber;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  String? createdAt;

  ReservationV2UpdateModel(
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

  ReservationV2UpdateModel.fromJson(Map<String, dynamic> json) {
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['user_id'] = this.userId;
    data['party_size'] = this.partySize;
    data['reserved_for'] = this.reservedFor;
    data['reserved_until'] = this.reservedUntil;
    data['duration_minutes'] = this.durationMinutes;
    data['status'] = this.status;
    data['table_number'] = this.tableNumber;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_email'] = this.customerEmail;
    data['note'] = this.note;
    data['created_at'] = this.createdAt;
    return data;
  }
}
