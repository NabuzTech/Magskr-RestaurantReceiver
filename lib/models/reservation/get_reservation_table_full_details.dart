class GetOrderDetailsResponseModel {
  int? storeId;
  int? userId;
  int? guestCount;
  String? reservedFor;
  String? reservedUntil;
  String? status;
  dynamic tableNumber;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  bool? isActive;
  int? id;
  String? createdAt;
  User? user;

  GetOrderDetailsResponseModel(
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

  GetOrderDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    storeId = (json['store_id'] as num?)?.toInt();
    userId = (json['user_id'] as num?)?.toInt();
    guestCount = (json['guest_count'] as num?)?.toInt();
    reservedFor = json['reserved_for']?.toString();
    reservedUntil = json['reserved_until']?.toString();
    status = json['status']?.toString();
    tableNumber = json['table_number'];
    customerName = json['customer_name']?.toString();
    customerPhone = json['customer_phone']?.toString();
    customerEmail = json['customer_email']?.toString();
    note = json['note']?.toString();
    isActive = json['isActive'] is bool
        ? json['isActive']
        : json['isActive']?.toString() == 'true';
    id = (json['id'] as num?)?.toInt();
    createdAt = json['created_at']?.toString();
    user = json['user'] != null && json['user'] is Map<String, dynamic>
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
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
    if (user != null) data['user'] = user!.toJson();
    return data;
  }
}

class User {
  String? username;
  int? id;
  dynamic storeId;
  int? roleId;

  User({this.username, this.id, this.storeId, this.roleId});

  User.fromJson(Map<String, dynamic> json) {
    username = json['username']?.toString();
    id = (json['id'] as num?)?.toInt();
    storeId = json['store_id'];
    roleId = (json['role_id'] as num?)?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['username'] = username;
    data['id'] = id;
    data['store_id'] = storeId;
    data['role_id'] = roleId;
    return data;
  }
}