class GetStoreTimingResponseModel {
  int? id;
  int? dayOfWeek;
  String? openingTime;
  String? closingTime;
  int? storeId;
  String? name;

  GetStoreTimingResponseModel(
      {this.id,
        this.dayOfWeek,
        this.openingTime,
        this.closingTime,
        this.storeId,
        this.name});

  GetStoreTimingResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dayOfWeek = json['day_of_week'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
    storeId = json['store_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['day_of_week'] = dayOfWeek;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    data['store_id'] = storeId;
    data['name'] = name;
    return data;
  }
}