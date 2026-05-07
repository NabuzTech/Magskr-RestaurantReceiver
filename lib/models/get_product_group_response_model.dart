class GetProductGroupResponseModel {
  int? productId;
  int? toppingGroupId;
  int? id;
  Product? product;
  Group? group;

  GetProductGroupResponseModel(
      {this.productId, this.toppingGroupId, this.id, this.product, this.group});

  GetProductGroupResponseModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    toppingGroupId = json['topping_group_id'];
    id = json['id'];
    product =
    json['product'] != null ? Product.fromJson(json['product']) : null;
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['topping_group_id'] = toppingGroupId;
    data['id'] = id;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (group != null) {
      data['group'] = group!.toJson();
    }
    return data;
  }
}

class Product {
  String? name;
  String? itemCode;
  int? categoryId;
  String? imageUrl;
  String? type;
  double? price;
  int? storeId;
  int? taxId;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  int? ownerId;
  Category? category;
  Tax? tax;

  Product(
      {this.name,
        this.itemCode,
        this.categoryId,
        this.imageUrl,
        this.type,
        this.price,
        this.storeId,
        this.taxId,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.ownerId,
        this.category,
        this.tax,
        });

  Product.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    itemCode = json['item_code'];
    categoryId = json['category_id'];
    imageUrl = json['image_url'];
    type = json['type'];
    price = json['price'];
    storeId = json['store_id'];
    taxId = json['tax_id'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'];
    id = json['id'];
    ownerId = json['owner_id'];
    category = json['category'] != null
        ? Category.fromJson(json['category'])
        : null;

    tax = json['tax'] != null ? Tax.fromJson(json['tax']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['item_code'] = itemCode;
    data['category_id'] = categoryId;
    data['image_url'] = imageUrl;
    data['type'] = type;
    data['price'] = price;
    data['store_id'] = storeId;
    data['tax_id'] = taxId;
    data['isActive'] = isActive;
    data['description'] = description;
    data['display_order'] = displayOrder;
    data['id'] = id;
    data['owner_id'] = ownerId;
    if (category != null) {
      data['category'] = category!.toJson();
    }

    if (tax != null) {
      data['tax'] = tax!.toJson();
    }
    return data;
  }
}

class Category {
  String? name;
  int? storeId;
  int? taxId;
  String? imageUrl;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  Tax? tax;


  Category(
      {this.name,
        this.storeId,
        this.taxId,
        this.imageUrl,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.tax,
       });

  Category.fromJson(Map<String, dynamic> json) {
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
  double? percentage;
  int? storeId;
  int? id;

  Tax({this.name, this.percentage, this.storeId, this.id});

  Tax.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage'];
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