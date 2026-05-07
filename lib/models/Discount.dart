class Discount {
  String? code;
  String? type;
  double? value;
  DateTime? expiresAt;
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

  factory Discount.fromJson(Map<String, dynamic> json) => Discount(
    code: json["code"],
    type: json["type"],
    value: (json["value"] as num?)?.toDouble(),
    expiresAt: DateTime.tryParse(json["expires_at"]),
    storeId: json["store_id"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "type": type,
    "value": value,
    "expires_at": expiresAt?.toIso8601String(),
    "store_id": storeId,
    "id": id,
  };
}
