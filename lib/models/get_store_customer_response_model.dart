class GetStoreCustomerResponseModel {
  int? total;
  int? limit;
  int? offset;
  Filters? filters;
  List<Customers>? customers;

  GetStoreCustomerResponseModel(
      {this.total, this.limit, this.offset, this.filters, this.customers});

  GetStoreCustomerResponseModel.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    limit = json['limit'];
    offset = json['offset'];
    filters =
    json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    if (json['customers'] != null) {
      customers = <Customers>[];
      json['customers'].forEach((v) {
        customers!.add(Customers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['limit'] = limit;
    data['offset'] = offset;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    if (customers != null) {
      data['customers'] = customers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Filters {
  String? customerType;
  bool? hasOrders;
  bool? hasReservations;

  Filters({this.customerType, this.hasOrders, this.hasReservations});

  Filters.fromJson(Map<String, dynamic> json) {
    customerType = json['customer_type'];
    hasOrders = json['has_orders'];
    hasReservations = json['has_reservations'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['customer_type'] = customerType;
    data['has_orders'] = hasOrders;
    data['has_reservations'] = hasReservations;
    return data;
  }
}

class Customers {
  int? id;
  int? storeId;
  int? userId;
  String? customerName;
  String? email;
  String? phone;
  String? customerType;
  String? firstOrderDate;
  String? lastOrderDate;
  int? totalOrders;
  String? firstReservationDate;
  String? lastReservationDate;
  int? totalReservations;
  String? createdAt;
  String? updatedAt;
  List<Orders>? orders;
  List<Reservations>? reservations;

  Customers(
      {this.id,
        this.storeId,
        this.userId,
        this.customerName,
        this.email,
        this.phone,
        this.customerType,
        this.firstOrderDate,
        this.lastOrderDate,
        this.totalOrders,
        this.firstReservationDate,
        this.lastReservationDate,
        this.totalReservations,
        this.createdAt,
        this.updatedAt,
        this.orders,
        this.reservations});

  Customers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    userId = json['user_id'];
    customerName = json['customer_name'];
    email = json['email'];
    phone = json['phone'];
    customerType = json['customer_type'];
    firstOrderDate = json['first_order_date'];
    lastOrderDate = json['last_order_date'];
    totalOrders = json['total_orders'];
    firstReservationDate = json['first_reservation_date'];
    lastReservationDate = json['last_reservation_date'];
    totalReservations = json['total_reservations'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['orders'] != null) {
      orders = <Orders>[];
      json['orders'].forEach((v) {
        orders!.add(Orders.fromJson(v));
      });
    }
    if (json['reservations'] != null) {
      reservations = <Reservations>[];
      json['reservations'].forEach((v) {
        reservations!.add(Reservations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['user_id'] = userId;
    data['customer_name'] = customerName;
    data['email'] = email;
    data['phone'] = phone;
    data['customer_type'] = customerType;
    data['first_order_date'] = firstOrderDate;
    data['last_order_date'] = lastOrderDate;
    data['total_orders'] = totalOrders;
    data['first_reservation_date'] = firstReservationDate;
    data['last_reservation_date'] = lastReservationDate;
    data['total_reservations'] = totalReservations;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (orders != null) {
      data['orders'] = orders!.map((v) => v.toJson()).toList();
    }
    if (reservations != null) {
      data['reservations'] = reservations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Orders {
  int? orderId;
  int? orderNumber;
  String? orderDate;

  Orders({this.orderId, this.orderNumber, this.orderDate});

  Orders.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    orderNumber = json['order_number'];
    orderDate = json['order_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['order_number'] = orderNumber;
    data['order_date'] = orderDate;
    return data;
  }
}

class Reservations {
  int? reservationId;
  String? reservationDate;
  String? createdAt;
  int? guestCount;
  int? tableNumber;

  Reservations(
      {this.reservationId,
        this.reservationDate,
        this.createdAt,
        this.guestCount,
        this.tableNumber});

  Reservations.fromJson(Map<String, dynamic> json) {
    reservationId = json['reservation_id'];
    reservationDate = json['reservation_date'];
    createdAt = json['created_at'];
    guestCount = json['guest_count'];
    tableNumber = json['table_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reservation_id'] = reservationId;
    data['reservation_date'] = reservationDate;
    data['created_at'] = createdAt;
    data['guest_count'] = guestCount;
    data['table_number'] = tableNumber;
    return data;
  }
}