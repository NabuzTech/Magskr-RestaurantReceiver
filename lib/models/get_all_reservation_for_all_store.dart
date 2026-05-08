class GetAllReservationForAllStoreInSuperAdmin {
  String? date;
  int? total;
  List<Stores>? stores;

  GetAllReservationForAllStoreInSuperAdmin(
      {this.date, this.total, this.stores});

  GetAllReservationForAllStoreInSuperAdmin.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    total = json['total'];
    if (json['stores'] != null) {
      stores = <Stores>[];
      json['stores'].forEach((v) {
        stores!.add(new Stores.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['total'] = this.total;
    if (this.stores != null) {
      data['stores'] = this.stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Stores {
  int? storeId;
  String? storeName;
  int? total;
  int? booked;
  int? pending;
  int? cancelled;
  List<Reservations>? reservations;

  Stores(
      {this.storeId,
        this.storeName,
        this.total,
        this.booked,
        this.pending,
        this.cancelled,
        this.reservations});

  Stores.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    total = json['total'];
    booked = json['booked'];
    pending = json['pending'];
    cancelled = json['cancelled'];
    if (json['reservations'] != null) {
      reservations = <Reservations>[];
      json['reservations'].forEach((v) {
        reservations!.add(new Reservations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['total'] = this.total;
    data['booked'] = this.booked;
    data['pending'] = this.pending;
    data['cancelled'] = this.cancelled;
    if (this.reservations != null) {
      data['reservations'] = this.reservations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reservations {
  int? id;
  String? status;
  int? guestCount;
  String? reservedFor;
  String? createdAt;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;

  Reservations(
      {this.id,
        this.status,
        this.guestCount,
        this.reservedFor,
        this.createdAt,
        this.customerName,
        this.customerPhone,
        this.customerEmail,
        this.note});

  Reservations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    guestCount = json['guest_count'];
    reservedFor = json['reserved_for'];
    createdAt = json['created_at'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['status'] = this.status;
    data['guest_count'] = this.guestCount;
    data['reserved_for'] = this.reservedFor;
    data['created_at'] = this.createdAt;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_email'] = this.customerEmail;
    data['note'] = this.note;
    return data;
  }
}