class get_item_allergy_link_response_model {
  int? productId;
  String? productName;
  int? allergyItemId;
  String? allergyName;

  get_item_allergy_link_response_model(
      {this.productId, this.productName, this.allergyItemId, this.allergyName});

  get_item_allergy_link_response_model.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    allergyItemId = json['allergy_item_id'];
    allergyName = json['allergy_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['allergy_item_id'] = allergyItemId;
    data['allergy_name'] = allergyName;
    return data;
  }
}