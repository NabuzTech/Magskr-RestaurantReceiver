class EditReservationDetailsResponseModel {
  int? storeId;
  int? userId;
  int? guestCount;
  String? reservedFor;
  String? reservedUntil;
  String? status;
  int? tableNumber;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  bool? isActive;
  int? id;
  String? createdAt;
  int? user;

  EditReservationDetailsResponseModel(
      {this.storeId,
        this.userId,
        this.guestCount,
        this.reservedFor,
        this.reservedUntil,
        this.status,
        this.tableNumber,
        this.customerName,
        this.customerPhone,
        this.customerEmail,
        this.note,
        this.isActive,
        this.id,
        this.createdAt,
        this.user});

  EditReservationDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    userId = json['user_id'];
    guestCount = json['guest_count'];
    reservedFor = json['reserved_for'];
    reservedUntil = json['reserved_until'];
    status = json['status'];
    tableNumber = json['table_number'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
    isActive = json['isActive'];
    id = json['id'];
    createdAt = json['created_at'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['user_id'] = userId;
    data['guest_count'] = guestCount;
    data['reserved_for'] = reservedFor;
    data['reserved_until'] = reservedUntil;
    data['status'] = status;
    data['table_number'] = tableNumber;
    data['customer_name'] = customerName;
    data['customer_phone'] = customerPhone;
    data['customer_email'] = customerEmail;
    data['note'] = note;
    data['isActive'] = isActive;
    data['id'] = id;
    data['created_at'] = createdAt;
    data['user'] = user;
    return data;
  }
}