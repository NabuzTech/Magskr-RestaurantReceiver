class AddDeliveryZoneResponseModel {
  int? minDistance;
  int? maxDistance;
  int? minimumOrderAmount;
  int? deliveryFee;
  int? deliveryTime;
  bool? isActive;
  int? id;
  int? storeId;
  String? createdAt;

  AddDeliveryZoneResponseModel(
      {this.minDistance,
        this.maxDistance,
        this.minimumOrderAmount,
        this.deliveryFee,
        this.deliveryTime,
        this.isActive,
        this.id,
        this.storeId,
        this.createdAt});

  AddDeliveryZoneResponseModel.fromJson(Map<String, dynamic> json) {
    minDistance = _toInt(json['min_distance']);
    maxDistance = _toInt(json['max_distance']);
    minimumOrderAmount = _toInt(json['minimum_order_amount']);
    deliveryFee = _toInt(json['delivery_fee']);
    deliveryTime = _toInt(json['delivery_time']);
    isActive = json['is_active'];
    id = _toInt(json['id']);
    storeId = _toInt(json['store_id']);
    createdAt = json['created_at']?.toString();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min_distance'] = minDistance;
    data['max_distance'] = maxDistance;
    data['minimum_order_amount'] = minimumOrderAmount;
    data['delivery_fee'] = deliveryFee;
    data['delivery_time'] = deliveryTime;
    data['is_active'] = isActive;
    data['id'] = id;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    return data;
  }
}