class EditStoreToppingsResponseModel {
  String? name;
  String? description;
  double? price;
  int? storeId;
  int? id;
  bool? isActive;

  EditStoreToppingsResponseModel(
      {this.name,
        this.description,
        this.price,
        this.storeId,
        this.id,
        this.isActive});

  EditStoreToppingsResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    price = json['price'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['store_id'] = storeId;
    data['id'] = id;
    data['isActive'] = isActive;
    return data;
  }
}