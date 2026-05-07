class GetCustomerOrderDetails {
  String? source;
  int? userId;
  int? discountId;
  String? couponCode;
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
  dynamic billingAddress;  // Changed from Null? to dynamic
  List<TaxSummary>? taxSummary;
  List<BruttoNettoSummary>? bruttoNettoSummary;
  GuestShippingJson? guestShippingJson;

  GetCustomerOrderDetails(
      {
        this.source,
        this.userId,
        this.discountId,
        this.couponCode,
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
        this.guestShippingJson});

  GetCustomerOrderDetails.fromJson(Map<String, dynamic> json) {
    source = json['source'];
    userId = json['user_id'];
    discountId = json['discount_id'];
    couponCode = json['coupon_code'];
    note = json['note'];
    orderType = json['order_type'];
    orderStatus = json['order_status'];
    approvalStatus = json['approval_status'];
    deliveryTime = json['delivery_time'];
    storeId = json['store_id'];
    isActive = json['isActive'];
    id = json['id'];
    createdAt = json['created_at'];
    orderNumber = json['order_number'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(new Items.fromJson(v));
      });
    }
    discount = json['discount'] != null
        ? new Discount.fromJson(json['discount'])
        : null;
    invoice =
    json['invoice'] != null ? new Invoice.fromJson(json['invoice']) : null;
    payment =
    json['payment'] != null ? new Payment.fromJson(json['payment']) : null;
    shippingAddress = json['shipping_address'] != null
        ? ShippingAddress.fromJson(json['shipping_address']) : null;
    billingAddress = json['billing_address'];
    if (json['tax_summary'] != null) {
      taxSummary = <TaxSummary>[];
      json['tax_summary'].forEach((v) {
        taxSummary!.add(TaxSummary.fromJson(v));
      });
    }
    if (json['brutto_netto_summary'] != null) {
      bruttoNettoSummary = <BruttoNettoSummary>[];
      json['brutto_netto_summary'].forEach((v) {
        bruttoNettoSummary!.add(BruttoNettoSummary.fromJson(v));
      });
    }
    guestShippingJson = json['guest_shipping_json'] != null
        ? GuestShippingJson.fromJson(json['guest_shipping_json'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['source'] = this.source;
    data['user_id'] = this.userId;
    data['discount_id'] = this.discountId;
    data['coupon_code'] = this.couponCode;
    data['note'] = this.note;
    data['order_type'] = this.orderType;
    data['order_status'] = this.orderStatus;
    data['approval_status'] = this.approvalStatus;
    data['delivery_time'] = this.deliveryTime;
    data['store_id'] = this.storeId;
    data['isActive'] = this.isActive;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['order_number'] = this.orderNumber;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    if (this.discount != null) {
      data['discount'] = this.discount!.toJson();
    }
    if (this.invoice != null) {
      data['invoice'] = this.invoice!.toJson();
    }
    if (this.payment != null) {
      data['payment'] = this.payment!.toJson();
    }
    if (shippingAddress != null) {
      data['shipping_address'] = shippingAddress!.toJson();
    }
    data['billing_address'] = billingAddress;
    if (taxSummary != null) {
      data['tax_summary'] = taxSummary!.map((v) => v.toJson()).toList();
    }
    if (bruttoNettoSummary != null) {
      data['brutto_netto_summary'] = bruttoNettoSummary!.map((v) => v.toJson()).toList();
    }
    if (guestShippingJson != null) {
      data['guest_shipping_json'] = guestShippingJson!.toJson();
    }
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
    username = json['username'];
    id = json['id'];
    storeId = json['store_id'];
    roleId = json['role_id'];
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
        this.toppings});

  Items.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    variantId = json['variant_id'];
    quantity = json['quantity'];
    unitPrice = json['unit_price'];
    note = json['note'];
    id = json['id'];
    variant =
    json['variant'] != null ? new Variant.fromJson(json['variant']) : null;
    productName = json['product_name'];
    variantName = json['variant_name'];
    tax = json['tax'];
    if (json['toppings'] != null) {
      toppings = <Toppings>[];
      json['toppings'].forEach((v) {
        toppings!.add(new Toppings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['variant_id'] = this.variantId;
    data['quantity'] = this.quantity;
    data['unit_price'] = this.unitPrice;
    data['note'] = this.note;
    data['id'] = this.id;
    if (this.variant != null) {
      data['variant'] = this.variant!.toJson();
    }
    data['product_name'] = this.productName;
    data['variant_name'] = this.variantName;
    data['tax'] = this.tax;
    if (this.toppings != null) {
      data['toppings'] = this.toppings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Variant {
  String? name;
  double? price;
  double? discountPrice;
  int? itemCode;
  String? imageUrl;
  String? description;
  int? id;
  double? qtyOnHand;


  Variant(
      {this.name,
        this.price,
        this.discountPrice,
        this.itemCode,
        this.imageUrl,
        this.description,
        this.id,
        this.qtyOnHand,
        });

  Variant.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price'];
    discountPrice = json['discount_price'];
    itemCode = json['item_code'];
    imageUrl = json['image_url'];
    description = json['description'];
    id = json['id'];
    qtyOnHand = json['qty_on_hand'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['price'] = this.price;
    data['discount_price'] = this.discountPrice;
    data['item_code'] = this.itemCode;
    data['image_url'] = this.imageUrl;
    data['description'] = this.description;
    data['id'] = this.id;
    data['qty_on_hand'] = this.qtyOnHand;

    return data;
  }
}

class Toppings {
  int? toppingId;
  int? quantity;
  double? price;
  String? name;

  Toppings({this.toppingId, this.quantity, this.price, this.name});

  Toppings.fromJson(Map<String, dynamic> json) {
    toppingId = json['topping_id'];
    quantity = json['quantity'];
    price = json['price'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['topping_id'] = this.toppingId;
    data['quantity'] = this.quantity;
    data['price'] = this.price;
    data['name'] = this.name;
    return data;
  }
}

class Discount {
  String? code;
  String? type;
  double? value;  // Changed from int? to double?
  String? expiresAt;
  int? storeId;
  int? id;

  Discount({
    this.code,
    this.type,
    this.value,
    this.expiresAt,
    this.storeId,
    this.id,
  });

  Discount.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    type = json['type'];
    value = json['value']?.toDouble();  // Handle both int and double
    expiresAt = json['expires_at'];
    storeId = json['store_id'];
    id = json['id'];
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
  double? totalAmount;  // Changed from int? to double?
  String? issuedAt;
  int? storeId;
  int? id;
  int? orderId;
  double? deliveryFee;  // Changed from int? to double?
  double? discountAmount;  // Changed from int? to double?

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
    invoiceNumber = json['invoice_number'];
    totalAmount = json['total_amount']?.toDouble();  // Handle both int and double
    issuedAt = json['issued_at'];
    storeId = json['store_id'];
    id = json['id'];
    orderId = json['order_id'];
    deliveryFee = json['delivery_fee']?.toDouble();  // Handle both int and double
    discountAmount = json['discount_amount']?.toDouble();  // Handle both int and double
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
  double? amount;  // Changed from int? to double?
  int? id;
  int? orderId;

  Payment({
    this.paymentMethod,
    this.status,
    this.paidAt,
    this.amount,
    this.id,
    this.orderId,
  });

  Payment.fromJson(Map<String, dynamic> json) {
    paymentMethod = json['payment_method'];
    status = json['status'];
    paidAt = json['paid_at'];
    amount = json['amount']?.toDouble();  // Handle both int and double
    id = json['id'];
    orderId = json['order_id'];
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

class TaxSummary {
  double? taxRate;  // Changed from int? to double?
  double? taxAmount;

  TaxSummary({this.taxRate, this.taxAmount});

  TaxSummary.fromJson(Map<String, dynamic> json) {
    taxRate = json['tax_rate']?.toDouble();  // Handle both int and double
    taxAmount = json['tax_amount']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tax_rate'] = taxRate;
    data['tax_amount'] = taxAmount;
    return data;
  }
}

class BruttoNettoSummary {
  double? taxRate;  // Changed from int? to double?
  double? brutto;   // Changed from int? to double?
  double? netto;
  double? taxAmount;

  BruttoNettoSummary({this.taxRate, this.brutto, this.netto, this.taxAmount});

  BruttoNettoSummary.fromJson(Map<String, dynamic> json) {
    taxRate = json['tax_rate']?.toDouble();
    brutto = json['brutto']?.toDouble();
    netto = json['netto']?.toDouble();
    taxAmount = json['tax_amount']?.toDouble();
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