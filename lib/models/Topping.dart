class Topping {
  int? toppingId;
  int? quantity;
  double? price;
  String? name;

  Topping({
    this.toppingId,
    this.quantity,
    this.price,
    this.name,
  });

  factory Topping.fromJson(Map<String, dynamic> json) => Topping(
    toppingId: json["topping_id"],
    quantity: json["quantity"],
    price: (json["price"] as num?)?.toDouble(),
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "topping_id": toppingId,
    "quantity": quantity,
    "price": price,
    "name": name,
  };
}
