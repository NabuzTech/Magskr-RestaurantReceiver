class GetTodayReservationV2OfStore {
  String? date;
  List<int>? storeIds;
  Summary? summary;
  List<Reservations>? reservations;

  GetTodayReservationV2OfStore(
      {this.date, this.storeIds, this.summary, this.reservations});

  GetTodayReservationV2OfStore.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    storeIds = json['store_ids']?.cast<int>();
    summary =
    json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    if (json['reservations'] != null) {
      reservations = <Reservations>[];
      json['reservations'].forEach((v) {
        reservations!.add(new Reservations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['store_ids'] = this.storeIds;
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    if (this.reservations != null) {
      data['reservations'] = this.reservations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Summary {
  int? total;
  int? pending;
  int? booked;
  int? cancelled;
  int? activeTotal;
  int? pendingCovers;
  int? bookedCovers;
  int? activeCovers;

  Summary(
      {this.total,
        this.pending,
        this.booked,
        this.cancelled,
        this.activeTotal,
        this.pendingCovers,
        this.bookedCovers,
        this.activeCovers});

  Summary.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    pending = json['pending'];
    booked = json['booked'];
    cancelled = json['cancelled'];
    activeTotal = json['active_total'];
    pendingCovers = json['pending_covers'];
    bookedCovers = json['booked_covers'];
    activeCovers = json['active_covers'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['pending'] = this.pending;
    data['booked'] = this.booked;
    data['cancelled'] = this.cancelled;
    data['active_total'] = this.activeTotal;
    data['pending_covers'] = this.pendingCovers;
    data['booked_covers'] = this.bookedCovers;
    data['active_covers'] = this.activeCovers;
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
