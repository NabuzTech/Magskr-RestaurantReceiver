//
// class Store {
//   String? name;
//   String? address;
//   String? country;
//   bool? isManualOverride;
//   String? manualStatus;
//   int? code;
//   String? mess;
//
//
//   Store({
//     this.name,
//     this.address,
//     this.country,
//     this.isManualOverride,
//     this.manualStatus,
//   });
//
//
//   Store.withError({
//     int? code,
//     String? mess,
//   })  : code = code,
//         mess = mess;
//
//   factory Store.fromJson(Map<String, dynamic> json) => Store(
//     name: json["name"],
//     address: json["address"],
//     country: json["country"],
//     isManualOverride : json['is_manual_override'],
//     manualStatus : json['manual_status'],
//   );
//   Map<String, dynamic> toJson() => {
//     "name": name,
//     "address": address,
//     "country": country,
//     "is_manual_override":isManualOverride,
//     "manual_status":manualStatus,
//
//   };
//
//
// }
class Store {
  String? name;
  String? address;
  String? country;
  bool? isManualOverride;
  String? manualStatus;
  int? code;
  String? mess;

  // 🔽 New fields added
  String? imageUrl;
  String? bannerUrl;
  String? description;
  List<dynamic>? phoneNumbers;
  int? numberOfTables;
  bool? useDistanceDelivery;
  int? id;
  String? createdAt;
  List<dynamic>? postcodes;
  List<StoreHour>? storeHours;
  List<DeliveryTimePlan>? deliveryTimePlans;
  List<dynamic>? collectionTimePlans;
  List<Printer>? printers;
  List<Holiday>? holidays;
  double? stripeServiceFee;
  bool? lieferungEnabled;

  Store({
    this.name,
    this.address,
    this.country,
    this.isManualOverride,
    this.manualStatus,

    // new
    this.imageUrl,
    this.bannerUrl,
    this.description,
    this.phoneNumbers,
    this.numberOfTables,
    this.useDistanceDelivery,
    this.id,
    this.createdAt,
    this.postcodes,
    this.storeHours,
    this.deliveryTimePlans,
    this.collectionTimePlans,
    this.printers,
    this.holidays,
    this.stripeServiceFee,
    this.lieferungEnabled,
  });

  Store.withError({
    int? code,
    String? mess,
  })  : code = code,
        mess = mess;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    name: json["name"],
    address: json["address"],
    country: json["country"],
    isManualOverride: json['is_manual_override'],
    manualStatus: json['manual_status'],

    // new
    imageUrl: json["image_url"],
    bannerUrl: json["banner_url"],
    description: json["description"],
    phoneNumbers: json["phone_numbers"],
    numberOfTables: json["number_of_tables"],
    useDistanceDelivery: json["use_distance_delivery"],
    id: json["id"],
    createdAt: json["created_at"],
    postcodes: json["postcodes"],
    storeHours: json["store_hours"] == null
        ? []
        : List<StoreHour>.from(
        json["store_hours"].map((x) => StoreHour.fromJson(x))),
    deliveryTimePlans: json["delivery_time_plans"] == null
        ? []
        : List<DeliveryTimePlan>.from(json["delivery_time_plans"]
        .map((x) => DeliveryTimePlan.fromJson(x))),
    collectionTimePlans: json["collection_time_plans"],
    printers: json["printers"] == null
        ? []
        : List<Printer>.from(
        json["printers"].map((x) => Printer.fromJson(x))),
    holidays: json["holidays"] == null
        ? []
        : List<Holiday>.from(
        json["holidays"].map((x) => Holiday.fromJson(x))),
    stripeServiceFee: (json["stripe_service_fee"] != null)
        ? (json["stripe_service_fee"] as num).toDouble()
        : null,
    lieferungEnabled: json["lieferung_enabled"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "address": address,
    "country": country,
    "is_manual_override": isManualOverride,
    "manual_status": manualStatus,

    // new
    "image_url": imageUrl,
    "banner_url": bannerUrl,
    "description": description,
    "phone_numbers": phoneNumbers,
    "number_of_tables": numberOfTables,
    "use_distance_delivery": useDistanceDelivery,
    "id": id,
    "created_at": createdAt,
    "postcodes": postcodes,
    "store_hours": storeHours?.map((x) => x.toJson()).toList(),
    "delivery_time_plans":
    deliveryTimePlans?.map((x) => x.toJson()).toList(),
    "collection_time_plans": collectionTimePlans,
    "printers": printers?.map((x) => x.toJson()).toList(),
    "holidays": holidays?.map((x) => x.toJson()).toList(),
    "stripe_service_fee": stripeServiceFee,
    "lieferung_enabled": lieferungEnabled,
  };
}

// 🔽 Sub Models

class StoreHour {
  int? id;
  int? dayOfWeek;
  String? openingTime;
  String? closingTime;
  int? storeId;
  String? name;

  StoreHour({
    this.id,
    this.dayOfWeek,
    this.openingTime,
    this.closingTime,
    this.storeId,
    this.name,
  });

  factory StoreHour.fromJson(Map<String, dynamic> json) => StoreHour(
    id: json["id"],
    dayOfWeek: json["day_of_week"],
    openingTime: json["opening_time"],
    closingTime: json["closing_time"],
    storeId: json["store_id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "day_of_week": dayOfWeek,
    "opening_time": openingTime,
    "closing_time": closingTime,
    "store_id": storeId,
    "name": name,
  };
}

class DeliveryTimePlan {
  int? id;
  int? dayOfWeek;
  String? startTime;
  String? endTime;
  int? storeId;
  String? name;

  DeliveryTimePlan({
    this.id,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.storeId,
    this.name,
  });

  factory DeliveryTimePlan.fromJson(Map<String, dynamic> json) =>
      DeliveryTimePlan(
        id: json["id"],
        dayOfWeek: json["day_of_week"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        storeId: json["store_id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "day_of_week": dayOfWeek,
    "start_time": startTime,
    "end_time": endTime,
    "store_id": storeId,
    "name": name,
  };
}

class Printer {
  String? name;
  String? ipAddress;
  int? storeId;
  bool? isActive;
  int? type;
  dynamic categoryId;
  bool? isRemote;
  int? id;

  Printer({
    this.name,
    this.ipAddress,
    this.storeId,
    this.isActive,
    this.type,
    this.categoryId,
    this.isRemote,
    this.id,
  });

  factory Printer.fromJson(Map<String, dynamic> json) => Printer(
    name: json["name"],
    ipAddress: json["ip_address"],
    storeId: json["store_id"],
    isActive: json["isActive"],
    type: json["type"],
    categoryId: json["category_id"],
    isRemote: json["isRemote"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "ip_address": ipAddress,
    "store_id": storeId,
    "isActive": isActive,
    "type": type,
    "category_id": categoryId,
    "isRemote": isRemote,
    "id": id,
  };
}

class Holiday {
  String? date;
  int? storeId;
  String? name;
  int? id;

  Holiday({
    this.date,
    this.storeId,
    this.name,
    this.id,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    date: json["date"],
    storeId: json["store_id"],
    name: json["name"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "date": date,
    "store_id": storeId,
    "name": name,
    "id": id,
  };
}