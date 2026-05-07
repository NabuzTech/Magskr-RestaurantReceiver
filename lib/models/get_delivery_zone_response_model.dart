class GetDeliveryZoneResponseModel {
  double? minDistance;
  double? maxDistance;
  double? minimumOrderAmount;
  double? deliveryFee;
  double? deliveryTime;
  bool? isActive;
  int? id;
  int? storeId;
  String? createdAt;

  GetDeliveryZoneResponseModel(
      {this.minDistance,
        this.maxDistance,
        this.minimumOrderAmount,
        this.deliveryFee,
        this.deliveryTime,
        this.isActive,
        this.id,
        this.storeId,
        this.createdAt});

  GetDeliveryZoneResponseModel.fromJson(Map<String, dynamic> json) {
    minDistance = _toDouble(json['min_distance']);
    maxDistance = _toDouble(json['max_distance']);
    minimumOrderAmount = _toDouble(json['minimum_order_amount']);
    deliveryFee = _toDouble(json['delivery_fee']);
    deliveryTime = _toDouble(json['delivery_time']);
    isActive = json['is_active'];
    id = _toInt(json['id']);
    storeId = _toInt(json['store_id']);
    createdAt = json['created_at']?.toString();
  }

  /// Safely converts num (int or double) from JSON to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely converts num (int or double) from JSON to int
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