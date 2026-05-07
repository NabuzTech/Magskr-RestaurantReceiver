class GetAllStoreResponseModel {
  String? name;
  String? address;
  String? country;
  String? imageUrl;
  String? description;
  // List<Null>? phoneNumbers;
  int? numberOfTables;
  bool? isManualOverride;
  String? manualStatus;
  int? id;
  String? createdAt;
  // List<Null>? postcodes;
  List<StoreHours>? storeHours;
  // List<Null>? printers;
  // List<Null>? holidays;

  GetAllStoreResponseModel(
      {this.name,
        this.address,
        this.country,
        this.imageUrl,
        this.description,
        // this.phoneNumbers,
        this.numberOfTables,
        this.isManualOverride,
        this.manualStatus,
        this.id,
        this.createdAt,
       // this.postcodes,
        this.storeHours,
        //this.printers,
        //this.holidays
     });

  GetAllStoreResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    country = json['country'];
    imageUrl = json['image_url'];
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
        storeHours!.add(StoreHours.fromJson(v));
      });
    }
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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['address'] = address;
    data['country'] = country;
    data['image_url'] = imageUrl;
    data['description'] = description;
    // if (this.phoneNumbers != null) {
    //   data['phone_numbers'] =
    //       this.phoneNumbers!.map((v) => v.toJson()).toList();
    // }
    data['number_of_tables'] = numberOfTables;
    data['is_manual_override'] = isManualOverride;
    data['manual_status'] = manualStatus;
    data['id'] = id;
    data['created_at'] = createdAt;
    // if (this.postcodes != null) {
    //   data['postcodes'] = this.postcodes!.map((v) => v.toJson()).toList();
    // }
    if (storeHours != null) {
      data['store_hours'] = storeHours!.map((v) => v.toJson()).toList();
    }
    // if (this.printers != null) {
    //   data['printers'] = this.printers!.map((v) => v.toJson()).toList();
    // }
    // if (this.holidays != null) {
    //   data['holidays'] = this.holidays!.map((v) => v.toJson()).toList();
    // }
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['day_of_week'] = dayOfWeek;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    data['store_id'] = storeId;
    data['name'] = name;
    return data;
  }
}