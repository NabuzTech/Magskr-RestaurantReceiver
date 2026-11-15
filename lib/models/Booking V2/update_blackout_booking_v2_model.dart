class UpdateBlackoutsBookingV2Model {
  int? id;
  int? storeId;
  int? serviceId;
  String? name;
  int? dayOfWeek;
  String? startTime;
  String? endTime;
  bool? isActive;
  int? sortOrder;

  UpdateBlackoutsBookingV2Model(
      {this.id,
        this.storeId,
        this.serviceId,
        this.name,
        this.dayOfWeek,
        this.startTime,
        this.endTime,
        this.isActive,
        this.sortOrder});

  UpdateBlackoutsBookingV2Model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    serviceId = json['service_id'];
    name = json['name'];
    dayOfWeek = json['day_of_week'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    isActive = json['is_active'];
    sortOrder = json['sort_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['service_id'] = this.serviceId;
    data['name'] = this.name;
    data['day_of_week'] = this.dayOfWeek;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['is_active'] = this.isActive;
    data['sort_order'] = this.sortOrder;
    return data;
  }
}
