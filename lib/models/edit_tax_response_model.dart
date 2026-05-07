class editTaxResponseModel {
  String? name;
  double? percentage;
  int? storeId;
  int? id;

  editTaxResponseModel({this.name, this.percentage, this.storeId, this.id});

  editTaxResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage']?.toDouble();
    storeId = json['store_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['percentage'] = percentage;
    data['store_id'] = storeId;
    data['id'] = id;
    return data;
  }
}