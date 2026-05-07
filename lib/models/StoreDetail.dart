class StoreDetail {
  String? name;
  String? address;
  String? country;
  String? imageUrl;
  String? description;
  int? numberOfTables;
  bool? isManualOverride;
  String? manualStatus;
  int? id;
  String? createdAt;
  int? code;
  String? mess;

  StoreDetail({
    this.name,
    this.address,
    this.country,
    this.imageUrl,
    this.description,
    this.numberOfTables,
    this.isManualOverride,
    this.manualStatus,
    this.id,
    this.createdAt,
  });
  StoreDetail.withError({
    int? code,
    String? mess,
  })  : code = code,
        mess = mess;

  factory StoreDetail.fromJson(Map<String, dynamic> json)
  {
  return StoreDetail(
  name: json["name"],
  address: json["address"],
  country: json["country"],
  imageUrl: json["image_url"],
  description: json["description"],
  numberOfTables: json["number_of_tables"],
  isManualOverride: json["is_manual_override"],
  manualStatus: json["manual_status"],
  id: json["id"],
  createdAt: json["created_at"],
  );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "address": address,
        "country": country,
        "image_url": imageUrl,
        "description": description,
        "number_of_tables": numberOfTables,
        "is_manual_override": isManualOverride,
        "manual_status": manualStatus,
        "id": id,
        "created_at": createdAt,
      };
}
