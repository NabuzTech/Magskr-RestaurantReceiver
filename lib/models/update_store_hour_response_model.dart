class update_store_hours_response_model {
  int? id;
  int? dayOfWeek;
  String? openingTime;
  String? closingTime;
  int? storeId;
  String? name;

  update_store_hours_response_model(
      {this.id,
        this.dayOfWeek,
        this.openingTime,
        this.closingTime,
        this.storeId,
        this.name});

  update_store_hours_response_model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dayOfWeek = json['day_of_week'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
    storeId = json['store_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['day_of_week'] = this.dayOfWeek;
    data['opening_time'] = this.openingTime;
    data['closing_time'] = this.closingTime;
    data['store_id'] = this.storeId;
    data['name'] = this.name;
    return data;
  }
}