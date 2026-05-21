class AllOrderAdminResponseModel {
  String? source;
  String? couponId;
  String? couponCode;
  int? userId;
  int? discountId;
  String? note;
  int? orderType;
  int? orderStatus;
  int? approvalStatus;
  String? deliveryTime;
  int? storeId;
  bool? isActive;
  int? id;
  String? createdAt;
  String? storeName;
  int? orderNumber;
  User? user;
  List<Items>? items;
  Discount? discount;
  Invoice? invoice;
  Payment? payment;
  ShippingAddress? shippingAddress;
  ShippingAddress? billingAddress;
  List<TaxSummary>? taxSummary;
  List<BruttoNettoSummary>? bruttoNettoSummary;
  GuestShippingJson? guestShippingJson;
  String? cancelReason;

  AllOrderAdminResponseModel(
      {this.source,
        this.couponId,
        this.couponCode,
        this.userId,
        this.discountId,
        this.note,
        this.orderType,
        this.orderStatus,
        this.approvalStatus,
        this.deliveryTime,
        this.storeId,
        this.isActive,
        this.id,
        this.createdAt,
        this.storeName,
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
        this.cancelReason});

  AllOrderAdminResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      source = json['source'];
      couponId = json['coupon_id'];
      couponCode = json['coupon_code'];
      userId = json['user_id'] as int?;
      discountId = json['discount_id'] as int?;
      note = json['note'] as String?;
      orderType = json['order_type'] as int?;
      orderStatus = json['order_status'] as int?;
      approvalStatus = json['approval_status'] as int?;
      deliveryTime = json['delivery_time'] as String?;
      storeId = json['store_id'] as int?;
      isActive = json['isActive'] as bool?;
      id = json['id'] as int?;
      createdAt = json['created_at'] as String?;
      storeName = json['store_name'];
      orderNumber = json['order_number'] as int?;
      user = json['user'] != null ? User.fromJson(json['user']) : null;

      if (json['items'] != null && json['items'] is List) {
        items = <Items>[];
        for (var v in (json['items'] as List)) {
          try {
            items!.add(Items.fromJson(v));
          } catch (e) {
            print("Error parsing item: $e");
          }
        }
      }

      discount = json['discount'] != null && json['discount'] is Map
          ? Discount.fromJson(json['discount'])
          : null;

      invoice = json['invoice'] != null && json['invoice'] is Map
          ? Invoice.fromJson(json['invoice'])
          : null;

      payment = json['payment'] != null && json['payment'] is Map
          ? Payment.fromJson(json['payment'])
          : null;

      shippingAddress = json['shipping_address'] != null && json['shipping_address'] is Map
          ? ShippingAddress.fromJson(json['shipping_address'])
          : null;

      billingAddress = json['billing_address'] != null && json['billing_address'] is Map
          ? ShippingAddress.fromJson(json['billing_address'])
          : null;

      if (json['tax_summary'] != null && json['tax_summary'] is List) {
        taxSummary = <TaxSummary>[];
        for (var v in (json['tax_summary'] as List)) {
          try {
            taxSummary!.add(TaxSummary.fromJson(v));
          } catch (e) {
            print("Error parsing tax summary: $e");
          }
        }
      }

      if (json['brutto_netto_summary'] != null && json['brutto_netto_summary'] is List) {
        bruttoNettoSummary = <BruttoNettoSummary>[];
        for (var v in (json['brutto_netto_summary'] as List)) {
          try {
            bruttoNettoSummary!.add(BruttoNettoSummary.fromJson(v));
          } catch (e) {
            print("Error parsing brutto netto summary: $e");
          }
        }
      }

      guestShippingJson = json['guest_shipping_json'] != null && json['guest_shipping_json'] is Map
          ? GuestShippingJson.fromJson(json['guest_shipping_json'])
          : null;

      cancelReason = json['cancel_reason'] as String?;

    } catch (e) {
      print("Error in AllOrderAdminResponseModel.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['source'] = source;
    data['coupon_id'] = couponId;
    data['coupon_code'] = couponCode;
    data['user_id'] = userId;
    data['discount_id'] = discountId;
    data['note'] = note;
    data['order_type'] = orderType;
    data['order_status'] = orderStatus;
    data['approval_status'] = approvalStatus;
    data['delivery_time'] = deliveryTime;
    data['store_id'] = storeId;
    data['isActive'] = isActive;
    data['id'] = id;
    data['created_at'] = createdAt;
    data['store_name'] = storeName;
    data['order_number'] = orderNumber;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (invoice != null) {
      data['invoice'] = invoice!.toJson();
    }
    if (payment != null) {
      data['payment'] = payment!.toJson();
    }
    if (shippingAddress != null) {
      data['shipping_address'] = shippingAddress!.toJson();
    }
    if (billingAddress != null) {
      data['billing_address'] = billingAddress!.toJson();
    }
    if (taxSummary != null) {
      data['tax_summary'] = taxSummary!.map((v) => v.toJson()).toList();
    }
    if (bruttoNettoSummary != null) {
      data['brutto_netto_summary'] =
          bruttoNettoSummary!.map((v) => v.toJson()).toList();
    }
    if (guestShippingJson != null) {
      data['guest_shipping_json'] = guestShippingJson!.toJson();
    }
    data['cancel_reason'] = cancelReason;
    return data;
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

  Items(
      {this.productId,
        this.variantId,
        this.quantity,
        this.unitPrice,
        this.note,
        this.id,
        this.variant,
        this.productName,
        this.variantName,
        this.tax,
        this.toppings
      });

  Items.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'] as int?;
    variantId = json['variant_id'];  // Already nullable
    quantity = json['quantity'] as int?;
    unitPrice = json['unit_price'] != null ? (json['unit_price'] as num).toDouble() : null;
    note = json['note'] as String?;
    id = json['id'] as int?;
    variant = json['variant'] != null && json['variant'] is Map
        ? Variant.fromJson(json['variant'])
        : null;
    productName = json['product_name'] as String?;
    variantName = json['variant_name'] as String?;
    tax = json['tax'] != null ? (json['tax'] as num).toDouble() : null;
    if (json['toppings'] != null) {
      toppings = <Toppings>[];
      json['toppings'].forEach((v) {
        toppings!.add(Toppings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['variant_id'] = variantId;
    data['quantity'] = quantity;
    data['unit_price'] = unitPrice;
    data['note'] = note;
    data['id'] = id;
    if (variant != null) {
      data['variant'] = variant!.toJson();
    }
    data['product_name'] = productName;
    data['variant_name'] = variantName;
    data['tax'] = tax;
    if (toppings != null) {
      data['toppings'] = toppings!.map((v) => v.toJson()).toList();
    }
    return data;
  }

}

class Discount {
  String? code;
  String? type;
  double? value;
  String? expiresAt;
  int? storeId;
  int? id;

  Discount(
      {this.code,
        this.type,
        this.value,
        this.expiresAt,
        this.storeId,
        this.id});

  Discount.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String?;
    type = json['type'] as String?;
    value = json['value'] != null ? (json['value'] as num).toDouble() : null;  // ✅
    expiresAt = json['expires_at'] as String?;
    storeId = json['store_id'] as int?;  // ✅ Make nullable
    id = json['id'] as int?;  // ✅ Make nullable
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['type'] = type;
    data['value'] = value;
    data['expires_at'] = expiresAt;
    data['store_id'] = storeId;
    data['id'] = id;
    return data;
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

  Invoice(
      {this.invoiceNumber,
        this.totalAmount,
        this.issuedAt,
        this.storeId,
        this.id,
        this.orderId,
        this.deliveryFee,
        this.discountAmount});

  Invoice.fromJson(Map<String, dynamic> json) {
    invoiceNumber = json['invoice_number'] as String?;
    totalAmount = json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : null;
    issuedAt = json['issued_at'] as String?;
    storeId = json['store_id'] as int?;
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
    deliveryFee = json['delivery_fee'] != null ? (json['delivery_fee'] as num).toDouble() : null;
    discountAmount = json['discount_amount'] != null ? (json['discount_amount'] as num).toDouble() : null;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['invoice_number'] = invoiceNumber;
    data['total_amount'] = totalAmount;
    data['issued_at'] = issuedAt;
    data['store_id'] = storeId;
    data['id'] = id;
    data['order_id'] = orderId;
    data['delivery_fee'] = deliveryFee;
    data['discount_amount'] = discountAmount;
    return data;
  }
}

class Payment {
  String? paymentMethod;
  String? status;
  String? paidAt;
  double? amount;
  int? id;
  int? orderId;

  Payment(
      {this.paymentMethod,
        this.status,
        this.paidAt,
        this.amount,
        this.id,
        this.orderId});

  Payment.fromJson(Map<String, dynamic> json) {
    paymentMethod = json['payment_method'] as String?;
    status = json['status'] as String?;
    paidAt = json['paid_at'] as String?;
    amount = json['amount'] != null ? (json['amount'] as num).toDouble() : null;
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['payment_method'] = paymentMethod;
    data['status'] = status;
    data['paid_at'] = paidAt;
    data['amount'] = amount;
    data['id'] = id;
    data['order_id'] = orderId;
    return data;
  }
}

class TaxSummary {
  double? taxRate;
  double? taxAmount;

  TaxSummary({this.taxRate, this.taxAmount});

  TaxSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();  // ✅ Changed
    taxAmount = (json['tax_amount'] as num?)?.toDouble();  // ✅ Changed
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tax_rate'] = taxRate;
    data['tax_amount'] = taxAmount;
    return data;
  }
}

class BruttoNettoSummary {
  double? taxRate;
  double? brutto;
  double? netto;
  double? taxAmount;

  BruttoNettoSummary({this.taxRate, this.brutto, this.netto, this.taxAmount});

  BruttoNettoSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();  // ✅ Changed
    brutto = (json['brutto'] as num?)?.toDouble();  // ✅ Changed
    netto = (json['netto'] as num?)?.toDouble();  // ✅ Changed
    taxAmount = (json['tax_amount'] as num?)?.toDouble();  // ✅ Changed
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tax_rate'] = taxRate;
    data['brutto'] = brutto;
    data['netto'] = netto;
    data['tax_amount'] = taxAmount;
    return data;
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

  GuestShippingJson(
      {this.zip,
        this.city,
        this.type,
        this.email,
        this.line1,
        this.phone,
        this.country,
        this.customerName});

  GuestShippingJson.fromJson(Map<String, dynamic> json) {
    zip = json['zip'];
    city = json['city'];
    type = json['type'];
    email = json['email'];
    line1 = json['line1'];
    phone = json['phone'];
    country = json['country'];
    customerName = json['customer_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zip'] = zip;
    data['city'] = city;
    data['type'] = type;
    data['email'] = email;
    data['line1'] = line1;
    data['phone'] = phone;
    data['country'] = country;
    data['customer_name'] = customerName;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = username;
    data['id'] = id;
    data['store_id'] = storeId;
    data['role_id'] = roleId;
    return data;
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
    type = json['type'];
    line1 = json['line1'];
    city = json['city'];
    zip = json['zip'];
    country = json['country'];
    phone = json['phone'];
    customerName = json['customer_name'];
    id = json['id'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['line1'] = line1;
    data['city'] = city;
    data['zip'] = zip;
    data['country'] = country;
    data['phone'] = phone;
    data['customer_name'] = customerName;
    data['id'] = id;
    data['user_id'] = userId;
    return data;
  }
}

class Toppings {
  int? toppingId;
  int? quantity;
  double? price;  // ✅ Changed from int? to double?
  String? name;

  Toppings({this.toppingId, this.quantity, this.price, this.name});

  Toppings.fromJson(Map<String, dynamic> json) {
    toppingId = json['topping_id'];
    quantity = json['quantity'];
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;  // ✅ Changed
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['topping_id'] = toppingId;
    data['quantity'] = quantity;
    data['price'] = price;
    data['name'] = name;
    return data;
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
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;
    discountPrice = json['discount_price'] != null ? (json['discount_price'] as num).toDouble() : null;
    itemCode = json['item_code'] as String?;
    imageUrl = json['image_url'] as String?;
    description = json['description'] as String?;
    id = json['id'] as int?;
    qtyOnHand = json['qty_on_hand'] != null ? (json['qty_on_hand'] as num).toDouble() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['price'] = price;
    data['discount_price'] = discountPrice;
    data['item_code'] = itemCode;
    data['image_url'] = imageUrl;
    data['description'] = description;
    data['id'] = id;
    data['qty_on_hand'] = qtyOnHand;
    return data;
  }
}