class GetGroupItemResponseModel {
  int? toppingGroupId;
  int? toppingId;
  int? displayOrder;
  int? id;
  Topping? topping;
  Group? group;

  GetGroupItemResponseModel(
      {this.toppingGroupId,
        this.toppingId,
        this.displayOrder,
        this.id,
        this.topping,
        this.group});

  GetGroupItemResponseModel.fromJson(Map<String, dynamic> json) {
    toppingGroupId = json['topping_group_id'];
    toppingId = json['topping_id'];
    displayOrder = json['display_order'];
    id = json['id'];
    topping =
    json['topping'] != null ? Topping.fromJson(json['topping']) : null;
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['topping_group_id'] = toppingGroupId;
    data['topping_id'] = toppingId;
    data['display_order'] = displayOrder;
    data['id'] = id;
    if (topping != null) {
      data['topping'] = topping!.toJson();
    }
    if (group != null) {
      data['group'] = group!.toJson();
    }
    return data;
  }
}

class Topping {
  String? name;
  String? description;
  double? price;
  int? storeId;
  int? id;
  bool? isActive;

  Topping(
      {this.name,
        this.description,
        this.price,
        this.storeId,
        this.id,
        this.isActive});

  Topping.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    price = json['price'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['store_id'] = storeId;
    data['id'] = id;
    data['isActive'] = isActive;
    return data;
  }
}

class Group {
  String? name;
  int? minSelect;
  int? maxSelect;
  bool? isRequired;
  int? storeId;
  int? id;
  bool? isActive;

  Group(
      {this.name,
        this.minSelect,
        this.maxSelect,
        this.isRequired,
        this.storeId,
        this.id,
        this.isActive});

  Group.fromJson(Map<String, dynamic> json) {
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