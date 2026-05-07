class AddNewProductCategoryResponseModel {
  String? name;
  int? storeId;
  int? taxId;
  String? imageUrl;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  Tax? tax;

  AddNewProductCategoryResponseModel(
      {this.name,
        this.storeId,
        this.taxId,
        this.imageUrl,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.tax});

  AddNewProductCategoryResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    storeId = json['store_id'];
    taxId = json['tax_id'];
    imageUrl = json['image_url'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'];
    id = json['id'];
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
  double? percentage; // Changed from int? to double?
  int? storeId;
  int? id;

  Tax({this.name, this.percentage, this.storeId, this.id});

  Tax.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage']?.toDouble(); // Convert to double safely
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