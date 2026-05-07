class GetHolidayResponseModel {
  String? date;
  int? storeId;
  String? name;
  int? id;

  GetHolidayResponseModel({this.date, this.storeId, this.name, this.id});

  GetHolidayResponseModel.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    storeId = json['store_id'];
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['store_id'] = storeId;
    data['name'] = name;
    data['id'] = id;
    return data;
  }
}