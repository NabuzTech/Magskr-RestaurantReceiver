class StoreOwnersStoreResponseModel {
  String? name;
  String? address;
  String? country;
  String? imageUrl;
  String? bannerUrl;
  String? description;
 // List<Null>? phoneNumbers;
  int? numberOfTables;
  bool? isManualOverride;
  String? manualStatus;
  bool? useDistanceDelivery;
  int? id;
  String? createdAt;
  //List<Null>? postcodes;
  List<StoreHours>? storeHours;
  // List<Null>? deliveryTimePlans;
  // List<Null>? collectionTimePlans;
  // List<Null>? printers;
  // List<Null>? holidays;
  double? stripeServiceFee;
  bool? lieferungEnabled;

  StoreOwnersStoreResponseModel(
      {this.name,
        this.address,
        this.country,
        this.imageUrl,
        this.bannerUrl,
        this.description,
        //this.phoneNumbers,
        this.numberOfTables,
        this.isManualOverride,
        this.manualStatus,
        this.useDistanceDelivery,
        this.id,
        this.createdAt,
       // this.postcodes,
        this.storeHours,
      //  this.deliveryTimePlans,
      //  this.collectionTimePlans,
      //  this.printers,
       // this.holidays,
        this.stripeServiceFee,
        this.lieferungEnabled});

  StoreOwnersStoreResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    country = json['country'];
    imageUrl = json['image_url'];
    bannerUrl = json['banner_url'];
    description = json['description'];
    // if (json['phone_numbers'] != null) {
    //   phoneNumbers = <Null>[];
    //   json['phone_numbers'].forEach((v) {
    //     phoneNumbers!.add(new Null.fromJson(v));
    //   });
    // }
    numberOfTables = json['number_of_tables'];
    isManualOverride = json['is_manual_override'];
    manualStatus = json['manual_status'];
    useDistanceDelivery = json['use_distance_delivery'];
    id = json['id'];
    createdAt = json['created_at'];
    // if (json['postcodes'] != null) {
    //   postcodes = <Null>[];
    //   json['postcodes'].forEach((v) {
    //     postcodes!.add(new Null.fromJson(v));
    //   });
    // }
    if (json['store_hours'] != null) {
      storeHours = <StoreHours>[];
      json['store_hours'].forEach((v) {
        storeHours!.add(new StoreHours.fromJson(v));
      });
    }
    // if (json['delivery_time_plans'] != null) {
    //   deliveryTimePlans = <Null>[];
    //   json['delivery_time_plans'].forEach((v) {
    //     deliveryTimePlans!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['collection_time_plans'] != null) {
    //   collectionTimePlans = <Null>[];
    //   json['collection_time_plans'].forEach((v) {
    //     collectionTimePlans!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['printers'] != null) {
    //   printers = <Null>[];
    //   json['printers'].forEach((v) {
    //     printers!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['holidays'] != null) {
    //   holidays = <Null>[];
    //   json['holidays'].forEach((v) {
    //     holidays!.add(new Null.fromJson(v));
    //   });
    // }
    stripeServiceFee = json['stripe_service_fee'];
    lieferungEnabled = json['lieferung_enabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['address'] = this.address;
    data['country'] = this.country;
    data['image_url'] = this.imageUrl;
    data['banner_url'] = this.bannerUrl;
    data['description'] = this.description;
    // if (this.phoneNumbers != null) {
    //   data['phone_numbers'] =
    //       this.phoneNumbers!.map((v) => v.toJson()).toList();
    // }
    data['number_of_tables'] = this.numberOfTables;
    data['is_manual_override'] = this.isManualOverride;
    data['manual_status'] = this.manualStatus;
    data['use_distance_delivery'] = this.useDistanceDelivery;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    // if (this.postcodes != null) {
    //   data['postcodes'] = this.postcodes!.map((v) => v.toJson()).toList();
    // }
    if (this.storeHours != null) {
      data['store_hours'] = this.storeHours!.map((v) => v.toJson()).toList();
    }
    // if (this.deliveryTimePlans != null) {
    //   data['delivery_time_plans'] =
    //       this.deliveryTimePlans!.map((v) => v.toJson()).toList();
    // }
    // if (this.collectionTimePlans != null) {
    //   data['collection_time_plans'] =
    //       this.collectionTimePlans!.map((v) => v.toJson()).toList();
    // }
    // if (this.printers != null) {
    //   data['printers'] = this.printers!.map((v) => v.toJson()).toList();
    // }
    // if (this.holidays != null) {
    //   data['holidays'] = this.holidays!.map((v) => v.toJson()).toList();
    // }
    data['stripe_service_fee'] = this.stripeServiceFee;
    data['lieferung_enabled'] = this.lieferungEnabled;
    return data;
  }
}

class StoreHours {
  int? id;
  int? dayOfWeek;
  String? openingTime;
  String? closingTime;
  int? storeId;
  String? name;

  StoreHours(
      {this.id,
        this.dayOfWeek,
        this.openingTime,
        this.closingTime,
        this.storeId,
        this.name});

  StoreHours.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dayOfWeek = json['day_of_week'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
    storeId = json['store_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['day_of_week'] = this.dayOfWeek;
    data['opening_time'] = this.openingTime;
    data['closing_time'] = this.closingTime;
    data['store_id'] = this.storeId;
    data['name'] = this.name;
    return data;
  }
}
