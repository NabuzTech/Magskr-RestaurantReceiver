class TodayReceivedBookingResponseModel {
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
  User? user;

  TodayReceivedBookingResponseModel(
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

  TodayReceivedBookingResponseModel.fromJson(Map<String, dynamic> json) {
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
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['user_id'] = this.userId;
    data['guest_count'] = this.guestCount;
    data['reserved_for'] = this.reservedFor;
    data['reserved_until'] = this.reservedUntil;
    data['status'] = this.status;
    data['table_number'] = this.tableNumber;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_email'] = this.customerEmail;
    data['note'] = this.note;
    data['isActive'] = this.isActive;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class User {
  String? username;
  int? id;
  int? storeId;
  int? roleId;

  User({this.username, this.id, this.storeId, this.roleId});

  User.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    id = json['id'];
    storeId = json['store_id'];
    roleId = json['role_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['role_id'] = this.roleId;
    return data;
  }
}