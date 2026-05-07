class orderHistoryResponseModel {
  int? userId;
  int? discountId;
  String? couponCode;
  String? voucherCode;
  String? note;
  int? orderType;
  int? orderStatus;
  int? approvalStatus;
  String? deliveryTime;
  int? storeId;
  bool? isActive;
  int? id;
  String? createdAt;
  int? orderNumber;
  User? user;
  List<Items>? items;
  Discount? discount;
  Invoice? invoice;
  Payment? payment;
  ShippingAddress? shippingAddress;
  String? billingAddress;
  List<TaxSummary>? taxSummary;
  List<BruttoNettoSummary>? bruttoNettoSummary;
  GuestShippingJson? guestShippingJson;

  orderHistoryResponseModel({
    this.userId,
    this.discountId,
    this.couponCode,
    this.voucherCode,
    this.note,
    this.orderType,
    this.orderStatus,
    this.approvalStatus,
    this.deliveryTime,
    this.storeId,
    this.isActive,
    this.id,
    this.createdAt,
    this.orderNumber,
    this.user,
    this.items,
    this.discount,
    this.invoice,
    this.payment,
    this.shippingAddress,
    this.billingAddress,
    this.taxSummary,
    this.bruttoNettoSummary,
    this.guestShippingJson,
  });

  orderHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'] as int?;
    discountId = json['discount_id'] as int?;
    couponCode = json['coupon_code'] as String?;
    voucherCode = json['voucher_code'] as String?;
    note = json['note'] as String?;
    orderType = json['order_type'] as int?;
    orderStatus = json['order_status'] as int?;
    approvalStatus = json['approval_status'] as int?;
    deliveryTime = json['delivery_time'] as String?;
    storeId = json['store_id'] as int?;
    isActive = json['isActive'] as bool?;
    id = json['id'] as int?;
    createdAt = json['created_at'] as String?;
    orderNumber = json['order_number'] as int?;
    user = json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null;
    if (json['items'] != null) {
      items = <Items>[];
      for (final v in json['items'] as List<dynamic>) {
        items!.add(Items.fromJson(v as Map<String, dynamic>));
      }
    }
    discount = json['discount'] != null ? Discount.fromJson(json['discount'] as Map<String, dynamic>) : null;
    invoice = json['invoice'] != null ? Invoice.fromJson(json['invoice'] as Map<String, dynamic>) : null;
    payment = json['payment'] != null ? Payment.fromJson(json['payment'] as Map<String, dynamic>) : null;
    shippingAddress = json['shipping_address'] != null
        ? ShippingAddress.fromJson(json['shipping_address'] as Map<String, dynamic>)
        : null;
    billingAddress = json['billing_address'] as String?;
    if (json['tax_summary'] != null) {
      taxSummary = <TaxSummary>[];
      for (final v in json['tax_summary'] as List<dynamic>) {
        taxSummary!.add(TaxSummary.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['brutto_netto_summary'] != null) {
      bruttoNettoSummary = <BruttoNettoSummary>[];
      for (final v in json['brutto_netto_summary'] as List<dynamic>) {
        bruttoNettoSummary!.add(BruttoNettoSummary.fromJson(v as Map<String, dynamic>));
      }
    }
    guestShippingJson = json['guest_shipping_json'] != null
        ? GuestShippingJson.fromJson(json['guest_shipping_json'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['discount_id'] = discountId;
    data['coupon_code'] = couponCode;
    data['voucher_code'] = voucherCode;
    data['note'] = note;
    data['order_type'] = orderType;
    data['order_status'] = orderStatus;
    data['approval_status'] = approvalStatus;
    data['delivery_time'] = deliveryTime;
    data['store_id'] = storeId;
    data['isActive'] = isActive;
    data['id'] = id;
    data['created_at'] = createdAt;
    data['order_number'] = orderNumber;
    data['user'] = user?.toJson();
    data['items'] = items?.map((v) => v.toJson()).toList();
    data['discount'] = discount?.toJson();
    data['invoice'] = invoice?.toJson();
    data['payment'] = payment?.toJson();
    data['shipping_address'] = shippingAddress?.toJson();
    data['billing_address'] = billingAddress;
    data['tax_summary'] = taxSummary?.map((v) => v.toJson()).toList();
    data['brutto_netto_summary'] = bruttoNettoSummary?.map((v) => v.toJson()).toList();
    data['guest_shipping_json'] = guestShippingJson?.toJson();
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
    username = json['username'] as String?;
    id = json['id'] as int?;
    storeId = json['store_id'] as int?;
    roleId = json['role_id'] as int?;
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'id': id,
      'store_id': storeId,
      'role_id': roleId,
    };
  }
}

class Items {
  int? productId;
  int? variantId;
  int? quantity;
  double? unitPrice;
  String? note;
  int? id;
  Variant? variant;
  String? productName;
  String? variantName;
  double? tax;
  List<Toppings>? toppings;

  Items({
    this.productId,
    this.variantId,
    this.quantity,
    this.unitPrice,
    this.note,
    this.id,
    this.variant,
    this.productName,
    this.variantName,
    this.tax,
    this.toppings,
  });

  Items.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'] as int?;
    variantId = json['variant_id'] as int?;
    quantity = json['quantity'] as int?;
    unitPrice = (json['unit_price'] as num?)?.toDouble();
    note = json['note'] as String?;
    id = json['id'] as int?;
    variant = json['variant'] != null
        ? Variant.fromJson(json['variant'] as Map<String, dynamic>)
        : null;
    productName = json['product_name'] as String?;
    variantName = json['variant_name'] as String?;
    tax = (json['tax'] as num?)?.toDouble();
    if (json['toppings'] != null) {
      toppings = <Toppings>[];
      for (final v in json['toppings'] as List<dynamic>) {
        toppings!.add(Toppings.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'note': note,
      'id': id,
      'variant': variant?.toJson(),
      'product_name': productName,
      'variant_name': variantName,
      'tax': tax,
      'toppings': toppings?.map((v) => v.toJson()).toList(),
    };
  }
}

class Variant {
  String? name;
  double? price;
  double? discountPrice;
  String? itemCode;
  String? imageUrl;
  String? description;
  int? id;
  double? qtyOnHand;

  Variant({
    this.name,
    this.price,
    this.discountPrice,
    this.itemCode,
    this.imageUrl,
    this.description,
    this.id,
    this.qtyOnHand,
  });

  Variant.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    price = (json['price'] as num?)?.toDouble();
    discountPrice = (json['discount_price'] as num?)?.toDouble();
    itemCode = json['item_code'] as String?;
    imageUrl = json['image_url'] as String?;
    description = json['description'] as String?;
    id = json['id'] as int?;
    qtyOnHand = (json['qty_on_hand'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'discount_price': discountPrice,
      'item_code': itemCode,
      'image_url': imageUrl,
      'description': description,
      'id': id,
      'qty_on_hand': qtyOnHand,
    };
  }
}

class Toppings {
  int? toppingId;
  int? quantity;
  double? price;
  String? name;

  Toppings({this.toppingId, this.quantity, this.price, this.name});

  Toppings.fromJson(Map<String, dynamic> json) {
    toppingId = json['topping_id'] as int?;
    quantity = json['quantity'] as int?;
    price = (json['price'] as num?)?.toDouble();
    name = json['name'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'topping_id': toppingId,
      'quantity': quantity,
      'price': price,
      'name': name,
    };
  }
}

class Discount {
  String? code;
  String? type;
  double? value;
  String? expiresAt;
  int? storeId;
  int? id;

  Discount({this.code, this.type, this.value, this.expiresAt, this.storeId, this.id});

  Discount.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String?;
    type = json['type'] as String?;
    value = (json['value'] as num?)?.toDouble();
    expiresAt = json['expires_at'] as String?;
    storeId = json['store_id'] as int?;
    id = json['id'] as int?;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'expires_at': expiresAt,
      'store_id': storeId,
      'id': id,
    };
  }
}

class Invoice {
  String? invoiceNumber;
  double? totalAmount;
  String? issuedAt;
  int? storeId;
  int? id;
  int? orderId;
  double? deliveryFee;
  double? discountAmount;

  Invoice({
    this.invoiceNumber,
    this.totalAmount,
    this.issuedAt,
    this.storeId,
    this.id,
    this.orderId,
    this.deliveryFee,
    this.discountAmount,
  });

  Invoice.fromJson(Map<String, dynamic> json) {
    invoiceNumber = json['invoice_number'] as String?;
    totalAmount = (json['total_amount'] as num?)?.toDouble();
    issuedAt = json['issued_at'] as String?;
    storeId = json['store_id'] as int?;
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
    deliveryFee = (json['delivery_fee'] as num?)?.toDouble();
    discountAmount = (json['discount_amount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'total_amount': totalAmount,
      'issued_at': issuedAt,
      'store_id': storeId,
      'id': id,
      'order_id': orderId,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
    };
  }
}

class Payment {
  String? paymentMethod;
  String? status;
  String? paidAt;
  double? amount;
  int? id;
  int? orderId;

  Payment({this.paymentMethod, this.status, this.paidAt, this.amount, this.id, this.orderId});

  Payment.fromJson(Map<String, dynamic> json) {
    paymentMethod = json['payment_method'] as String?;
    status = json['status'] as String?;
    paidAt = json['paid_at'] as String?;
    amount = (json['amount'] as num?)?.toDouble();
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'status': status,
      'paid_at': paidAt,
      'amount': amount,
      'id': id,
      'order_id': orderId,
    };
  }
}

class ShippingAddress {
  String? type;
  String? line1;
  String? city;
  String? zip;
  String? country;
  String? phone;
  String? customerName;
  int? id;
  int? userId;

  ShippingAddress({
    this.type,
    this.line1,
    this.city,
    this.zip,
    this.country,
    this.phone,
    this.customerName,
    this.id,
    this.userId,
  });

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    line1 = json['line1'] as String?;
    city = json['city'] as String?;
    zip = json['zip'] as String?;
    country = json['country'] as String?;
    phone = json['phone'] as String?;
    customerName = json['customer_name'] as String?;
    id = json['id'] as int?;
    userId = json['user_id'] as int?;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'line1': line1,
      'city': city,
      'zip': zip,
      'country': country,
      'phone': phone,
      'customer_name': customerName,
      'id': id,
      'user_id': userId,
    };
  }
}

class TaxSummary {
  double? taxRate;
  double? taxAmount;

  TaxSummary({this.taxRate, this.taxAmount});

  TaxSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();
    taxAmount = (json['tax_amount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
    };
  }
}

class BruttoNettoSummary {
  double? taxRate;
  double? brutto;
  double? netto;
  double? taxAmount;

  BruttoNettoSummary({this.taxRate, this.brutto, this.netto, this.taxAmount});

  BruttoNettoSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();
    brutto = (json['brutto'] as num?)?.toDouble();
    netto = (json['netto'] as num?)?.toDouble();
    taxAmount = (json['tax_amount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_rate': taxRate,
      'brutto': brutto,
      'netto': netto,
      'tax_amount': taxAmount,
    };
  }
}

class GuestShippingJson {
  String? zip;
  String? city;
  String? type;
  String? email;
  String? line1;
  String? phone;
  String? country;
  String? customerName;

  GuestShippingJson({
    this.zip,
    this.city,
    this.type,
    this.email,
    this.line1,
    this.phone,
    this.country,
    this.customerName,
  });

  GuestShippingJson.fromJson(Map<String, dynamic> json) {
    zip = json['zip'] as String?;
    city = json['city'] as String?;
    type = json['type'] as String?;
    email = json['email'] as String?;
    line1 = json['line1'] as String?;
    phone = json['phone'] as String?;
    country = json['country'] as String?;
    customerName = json['customer_name'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'zip': zip,
      'city': city,
      'type': type,
      'email': email,
      'line1': line1,
      'phone': phone,
      'country': country,
      'customer_name': customerName,
    };
  }
}