class GetServiceModel {
  int? id;
  int? storeId;
  int? resourceId;
  String? name;
  String? description;
  String? imageUrl;
  int? durationMinutes;
  int? bufferMinutes;
  int? minParty;
  int? maxParty;
  String? priceMode;
  int? price;
  int? depositAmount;
  bool? requirePayment;
  int? slotIntervalMinutes;
  int? leadTimeMinutes;
  int? bookingWindowDays;
  bool? isActive;
  int? sortOrder;
  List<ServiceOption>? options;
  List<ServiceHour>? hours;

  GetServiceModel(
      {this.id,
        this.storeId,
        this.resourceId,
        this.name,
        this.description,
        this.imageUrl,
        this.durationMinutes,
        this.bufferMinutes,
        this.minParty,
        this.maxParty,
        this.priceMode,
        this.price,
        this.depositAmount,
        this.requirePayment,
        this.slotIntervalMinutes,
        this.leadTimeMinutes,
        this.bookingWindowDays,
        this.isActive,
        this.sortOrder,
        this.options,
        this.hours,
      });

  GetServiceModel.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num?)?.toInt();
    storeId = (json['store_id'] as num?)?.toInt();
    resourceId = (json['resource_id'] as num?)?.toInt();
    name = json['name'];
    description = json['description'];
    imageUrl = json['image_url'];
    durationMinutes = (json['duration_minutes'] as num?)?.toInt();
    bufferMinutes = (json['buffer_minutes'] as num?)?.toInt();
    minParty = (json['min_party'] as num?)?.toInt();
    maxParty = (json['max_party'] as num?)?.toInt();
    priceMode = json['price_mode'];
    price = (json['price'] as num?)?.toInt();
    depositAmount = (json['deposit_amount'] as num?)?.toInt();
    requirePayment = json['require_payment'];
    slotIntervalMinutes = (json['slot_interval_minutes'] as num?)?.toInt();
    leadTimeMinutes = (json['lead_time_minutes'] as num?)?.toInt();
    bookingWindowDays = (json['booking_window_days'] as num?)?.toInt();
    isActive = json['is_active'];
    sortOrder = (json['sort_order'] as num?)?.toInt();
    options = json['options'] == null
        ? null
        : List<ServiceOption>.from(
        (json['options'] as List).map((v) => ServiceOption.fromJson(v)));
    hours = json['hours'] == null
        ? null
        : List<ServiceHour>.from(
        (json['hours'] as List).map((v) => ServiceHour.fromJson(v)));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['resource_id'] = resourceId;
    data['name'] = name;
    data['description'] = description;
    data['image_url'] = imageUrl;
    data['duration_minutes'] = durationMinutes;
    data['buffer_minutes'] = bufferMinutes;
    data['min_party'] = minParty;
    data['max_party'] = maxParty;
    data['price_mode'] = priceMode;
    data['price'] = price;
    data['deposit_amount'] = depositAmount;
    data['require_payment'] = requirePayment;
    data['slot_interval_minutes'] = slotIntervalMinutes;
    data['lead_time_minutes'] = leadTimeMinutes;
    data['booking_window_days'] = bookingWindowDays;
    data['is_active'] = isActive;
    data['sort_order'] = sortOrder;
    if (options != null) {
      data['options'] = options!.map((v) => v.toJson()).toList();
    }
    if (hours != null) {
      data['hours'] = hours!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceOption {
  int? id;
  String? name;
  int? priceDelta;
  String? priceMode;
  bool? isDefault;
  bool? isActive;
  int? sortOrder;

  ServiceOption({
    this.id,
    this.name,
    this.priceDelta,
    this.priceMode,
    this.isDefault,
    this.isActive,
    this.sortOrder,
  });

  ServiceOption.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num?)?.toInt();
    name = json['name'];
    priceDelta = (json['price_delta'] as num?)?.toInt();
    priceMode = json['price_mode'];
    isDefault = json['is_default'];
    isActive = json['is_active'];
    sortOrder = (json['sort_order'] as num?)?.toInt();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_delta': priceDelta,
      'price_mode': priceMode,
      'is_default': isDefault,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

class ServiceHour {
  int? dayOfWeek;
  String? startTime;
  String? endTime;

  ServiceHour({this.dayOfWeek, this.startTime, this.endTime});

  ServiceHour.fromJson(Map<String, dynamic> json) {
    dayOfWeek = (json['day_of_week'] as num?)?.toInt();
    startTime = json['start_time'];
    endTime = json['end_time'];
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}
