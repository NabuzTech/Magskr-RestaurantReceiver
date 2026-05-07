class EditExistingProductCategoryResponseModel {
  String? name;
  int? storeId;
  int? taxId;
  String? imageUrl;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  Tax? tax;

  EditExistingProductCategoryResponseModel(
      {this.name,
        this.storeId,
        this.taxId,
        this.imageUrl,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.tax});

  EditExistingProductCategoryResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id'] != null ? (json['tax_id'] as num).toInt() : null;
    imageUrl = json['image_url'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'] != null ? (json['display_order'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    tax = json['tax'] != null ? Tax.fromJson(json['tax']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['store_id'] = storeId;
    data['tax_id'] = taxId;
    data['image_url'] = imageUrl;
    data['isActive'] = isActive;
    data['description'] = description;
    data['display_order'] = displayOrder;
    data['id'] = id;
    if (tax != null) {
      data['tax'] = tax!.toJson();
    }
    return data;
  }
}

class Tax {
  String? name;
  int? percentage;
  int? storeId;
  int? id;

  Tax({this.name, this.percentage, this.storeId, this.id});

  Tax.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage'] != null ? (json['percentage'] as num).toInt() : null;
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
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