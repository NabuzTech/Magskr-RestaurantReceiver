class AddNewCategoryAvailabilityResponseModel {
  int? categoryId;
  int? dayOfWeek;
  String? startTime;
  String? endTime;
  String? label;
  bool? isActive;
  int? id;
  int? storeId;

  AddNewCategoryAvailabilityResponseModel(
      {this.categoryId,
        this.dayOfWeek,
        this.startTime,
        this.endTime,
        this.label,
        this.isActive,
        this.id,
        this.storeId});

  AddNewCategoryAvailabilityResponseModel.fromJson(Map<String, dynamic> json) {
    categoryId = json['category_id'];
    dayOfWeek = json['day_of_week'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    label = json['label'];
    isActive = json['isActive'];
    id = json['id'];
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = categoryId;
    data['day_of_week'] = dayOfWeek;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['label'] = label;
    data['isActive'] = isActive;
    data['id'] = id;
    data['store_id'] = storeId;
    return data;
  }
}