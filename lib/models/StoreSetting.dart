class StoreSetting {
  bool? auto_accept_orders_remote;
  bool? auto_print_orders_remote;
  bool? auto_accept_orders_local;
  bool? auto_print_orders_local;
  bool? auto_accept_reservations;   // NEW
  double? stripe_service_fee;       // NEW
  bool? lieferung_enabled;          // NEW
  bool? abholung_enabled;
  bool? tisch_reservierung_enabled;
  bool? reservation_v2_enabled;
  int? id;
  int? store_id;
  String? msg;
  int? code;
  String? mess;

  StoreSetting({
    this.auto_accept_orders_remote,
    this.auto_print_orders_remote,
    this.auto_accept_orders_local,
    this.auto_print_orders_local,
    this.auto_accept_reservations,   // NEW
    this.stripe_service_fee,         // NEW
    this.lieferung_enabled,          // NEW
    this.abholung_enabled,
    this.tisch_reservierung_enabled,
    this.reservation_v2_enabled,
    this.id,
    this.store_id,
    this.msg,
    this.code,
    this.mess,
  });

  StoreSetting.withError({
    int? code,
    String? mess,
  })  : code = code,
        mess = mess;

  factory StoreSetting.fromJson(Map<String, dynamic> json) => StoreSetting(
    auto_accept_orders_remote: json["auto_accept_orders_remote"],
    auto_print_orders_remote: json["auto_print_orders_remote"],
    auto_accept_orders_local: json["auto_accept_orders_local"],
    auto_print_orders_local: json["auto_print_orders_local"],
    auto_accept_reservations: json["auto_accept_reservations"],  // NEW
    stripe_service_fee: (json["stripe_service_fee"] as num?)?.toDouble(),  // NEW
    lieferung_enabled: json["lieferung_enabled"],                // NEW
    abholung_enabled: json["abholung_enabled"],
    tisch_reservierung_enabled: json["tisch_reservierung_enabled"],
    reservation_v2_enabled: json["reservation_v2_enabled"] ?? false,
    id: json["id"],
    store_id: json["store_id"],
    msg: json["msg"],
  );

  Map<String, dynamic> toJson() => {
    "auto_accept_orders_remote": auto_accept_orders_remote,
    "auto_print_orders_remote": auto_print_orders_remote,
    "auto_accept_orders_local": auto_accept_orders_local,
    "auto_print_orders_local": auto_print_orders_local,
    "auto_accept_reservations": auto_accept_reservations,  // NEW
    "stripe_service_fee": stripe_service_fee,              // NEW
    "lieferung_enabled": lieferung_enabled,                // NEW
    "abholung_enabled": abholung_enabled,
    "tisch_reservierung_enabled": tisch_reservierung_enabled,
    "reservation_v2_enabled": reservation_v2_enabled,
    "id": id,
    "store_id": store_id,
    "msg": msg,
  };
}