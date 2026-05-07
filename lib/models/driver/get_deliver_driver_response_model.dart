class GetSpecificStoreDeliveryDriverResponseModel {
  GetSpecificStoreDeliveryDriverResponseModel({
    required this.userId,
    required this.storeId,
    required this.id,
    required this.isActive,
  });

  final int? userId;
  final int? storeId;
  final int? id;
  final bool? isActive;

  factory GetSpecificStoreDeliveryDriverResponseModel.fromJson(Map<String, dynamic> json){
    return GetSpecificStoreDeliveryDriverResponseModel(
      userId: json["user_id"],
      storeId: json["store_id"],
      id: json["id"],
      isActive: json["is_active"],
    );
  }

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "store_id": storeId,
    "id": id,
    "is_active": isActive,
  };

}
