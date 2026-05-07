import 'Topping.dart';

class Variant {
  String? name;
  double? price;
  String? itemCode;
  String? imageUrl;
  String? description;
  int? id;

  Variant({
    this.name,
    this.price,
    this.itemCode,
    this.imageUrl,
    this.description,
    this.id,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
    name: json["name"],
    price: (json["price"] as num?)?.toDouble(),
    itemCode: json["item_code"],
    imageUrl: json["image_url"],
    description: json["description"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "price": price,
    "item_code": itemCode,
    "image_url": imageUrl,
    "description": description,
    "id": id,
  };
}

class OrderItem {
  int? productId;
  int? variantId;
  int? quantity;
  double? unitPrice;
  String? note;
  int? id;
  Variant? variant;
  String? productName;
  String? variantName;
  List<Topping>? toppings;

  OrderItem({
    this.productId,
    this.variantId,
    this.quantity,
    this.unitPrice,
    this.note,
    this.id,
    this.variant,
    this.productName,
    this.variantName,
    this.toppings,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json["product_id"],
    variantId: json["variant_id"],
    quantity: json["quantity"],
    unitPrice: (json["unit_price"] as num?)?.toDouble(),
    note: json["note"],
    id: json["id"],
    variant:
    json["variant"] != null ? Variant.fromJson(json["variant"]) : null,
    productName: json["product_name"],
    variantName: json["variant_name"],
    toppings: json["toppings"] != null
        ? List<Topping>.from(
        json["toppings"].map((x) => Topping.fromJson(x)))
        : [],
  );

  Map<String, dynamic> toJson() => {
    "product_id": productId,
    "variant_id": variantId,
    "quantity": quantity,
    "unit_price": unitPrice,
    "note": note,
    "id": id,
    "variant": variant?.toJson(),
    "product_name": productName,
    "variant_name": variantName,
    "toppings": toppings?.map((x) => x.toJson()).toList(),
  };
}

