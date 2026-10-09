class GetAllReservationV2 {
  String? fromDate;
  List<int>? storeIds;
  int? total;
  int? limit;
  int? offset;
  bool? hasMore;
  List<Reservations>? reservations;

  GetAllReservationV2(
      {this.fromDate,
      this.storeIds,
      this.total,
      this.limit,
      this.offset,
      this.hasMore,
      this.reservations});

  GetAllReservationV2.fromJson(Map<String, dynamic> json) {
    fromDate = json['from_date'];
    storeIds = (json['store_ids'] as List?)?.cast<int>();
    total = json['total'];
    limit = json['limit'];
    offset = json['offset'];
    hasMore = json['has_more'];
    if (json['reservations'] != null) {
      reservations = <Reservations>[];
      json['reservations'].forEach((v) {
        reservations!.add(new Reservations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['from_date'] = this.fromDate;
    data['store_ids'] = this.storeIds;
    data['total'] = this.total;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    data['has_more'] = this.hasMore;
    if (this.reservations != null) {
      data['reservations'] = this.reservations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reservations {
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

  Reservations(
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

  Reservations.fromJson(Map<String, dynamic> json) {
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
