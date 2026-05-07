class EditToppingsGroupResponseModel {
  String? name;
  int? minSelect;
  int? maxSelect;
  bool? isRequired;
  int? storeId;
  int? id;
  bool? isActive;

  EditToppingsGroupResponseModel(
      {this.name,
        this.minSelect,
        this.maxSelect,
        this.isRequired,
        this.storeId,
        this.id,
        this.isActive});

  EditToppingsGroupResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    minSelect = json['min_select'];
    maxSelect = json['max_select'];
    isRequired = json['is_required'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['min_select'] = minSelect;
    data['max_select'] = maxSelect;
    data['is_required'] = isRequired;
    data['store_id'] = storeId;
    data['id'] = id;
    data['isActive'] = isActive;
    return data;
  }
}