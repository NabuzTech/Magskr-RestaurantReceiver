  class GetDeliveryTimeStore {
  int? id;
  int? dayOfWeek;
  String? startTime;
  String? endTime;
  int? storeId;
  String? name;

  GetDeliveryTimeStore(
      {this.id,
        this.dayOfWeek,
        this.startTime,
        this.endTime,
        this.storeId,
        this.name});

  GetDeliveryTimeStore.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dayOfWeek = json['day_of_week'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    storeId = json['store_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['day_of_week'] = dayOfWeek;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['store_id'] = storeId;
    data['name'] = name;
    return data;
  }
}