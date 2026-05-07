class ShippingAddress {
  String? code;
  String? type;
  double? value;
  DateTime? expiresAt;
  int? storeId;
  int? id;

  String? city;
  String? country;
  String? line1;
  String? phone;
  int? userId;
  String? zip;
  String? customer_name;

  ShippingAddress({
    this.code,
    this.type,
    this.value,
    this.expiresAt,
    this.storeId,
    this.id,
    this.city,
    this.country,
    this.line1,
    this.phone,
    this.userId,
    this.zip,
    this.customer_name,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        code: json["code"],
        type: json["type"],
        value: (json["value"] as num?)?.toDouble(),
        expiresAt: DateTime.tryParse(json["expires_at"] ?? ''),
        storeId: json["store_id"],
        id: json["id"],
        city: json["city"],
        country: json["country"],
        line1: json["line1"],
        phone: json["phone"],
        userId: json["user_id"],
        zip: json["zip"],
        customer_name: json["customer_name"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "type": type,
        "value": value,
        "expires_at": expiresAt?.toIso8601String(),
        "store_id": storeId,
        "id": id,
        "city": city,
        "country": country,
        "line1": line1,
        "phone": phone,
        "user_id": userId,
        "zip": zip,
        "customer_name": customer_name,
      };
}
