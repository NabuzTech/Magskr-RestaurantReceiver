class getAddedtaxResponseModel {
  String? name;
  double? percentage; // Changed from int? to double?
  int? storeId;
  int? id;

  getAddedtaxResponseModel({this.name, this.percentage, this.storeId, this.id});

  getAddedtaxResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage']?.toDouble(); // Safely convert to double
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