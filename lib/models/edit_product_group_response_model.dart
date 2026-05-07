class EditProductGroupResponseModel {
  int? id;
  int? productId;
  int? toppingGroupId;

  EditProductGroupResponseModel({this.id, this.productId, this.toppingGroupId});

  EditProductGroupResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    toppingGroupId = json['topping_group_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['topping_group_id'] = toppingGroupId;
    return data;
  }
}