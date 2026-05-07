class AddStorePostCodesResponseModel {
  String? postcode;
  double? minimumOrderAmount;
  double? deliveryFee;
  int? deliveryTime;
  int? id;
  int? storeId;

  AddStorePostCodesResponseModel(
      {this.postcode,
        this.minimumOrderAmount,
        this.deliveryFee,
        this.deliveryTime,
        this.id,
        this.storeId});

  AddStorePostCodesResponseModel.fromJson(Map<String, dynamic> json) {
    postcode = json['postcode'];
    minimumOrderAmount = json['minimum_order_amount'];
    deliveryFee = json['delivery_fee'];
    deliveryTime = json['delivery_time'];
    id = json['id'];
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['postcode'] = postcode;
    data['minimum_order_amount'] = minimumOrderAmount;
    data['delivery_fee'] = deliveryFee;
    data['delivery_time'] = deliveryTime;
    data['id'] = id;
    data['store_id'] = storeId;
    return data;
  }
}