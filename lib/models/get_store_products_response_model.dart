class GetStoreProducts {
  String? name;
  String? itemCode;
  int? categoryId;
  String? imageUrl;
  String? type;
  double? price;
  double? discountPrice;
  int? storeId;
  String? taxId;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  int? ownerId;
  Category? category;
  List<Variants>? variants;
  String? tax;
  List<EnrichedToppingGroups>? enrichedToppingGroups;

  GetStoreProducts(
      {this.name,
        this.itemCode,
        this.categoryId,
        this.imageUrl,
        this.type,
        this.price,
        this.discountPrice,
        this.storeId,
        this.taxId,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.ownerId,
        this.category,
        this.variants,
        this.tax,
        this.enrichedToppingGroups,
       });

  GetStoreProducts.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    itemCode = json['item_code']?.toString();
    categoryId = json['category_id'] != null ? (json['category_id'] as num).toInt() : null;
    imageUrl = json['image_url']?.toString();
    type = json['type']?.toString();
    price = json['price']?.toDouble();
    discountPrice = json['discount_price']?.toDouble();
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id']?.toString();
    isActive = json['isActive'] as bool?;  // ✅ ADDED
    description = json['description']?.toString();
    displayOrder = json['display_order'] != null ? (json['display_order'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    ownerId = json['owner_id'] != null ? (json['owner_id'] as num).toInt() : null;
    category = json['category'] != null
        ? Category.fromJson(json['category'])
        : null;
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(Variants.fromJson(v));
      });
    }
    tax = json['tax']?.toString();
    if (json['enriched_topping_groups'] != null) {
      enrichedToppingGroups = <EnrichedToppingGroups>[];
      json['enriched_topping_groups'].forEach((v) {
        enrichedToppingGroups!.add(EnrichedToppingGroups.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['item_code'] = itemCode;
    data['category_id'] = categoryId;
    data['image_url'] = imageUrl;
    data['type'] = type;
    data['price'] = price;
    data['discount_price'] = discountPrice;
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
    if (variants != null) {
      data['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    data['tax'] = tax;
    if (enrichedToppingGroups != null) {
      data['enriched_topping_groups'] =
          enrichedToppingGroups!.map((v) => v.toJson()).toList();
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
    name = json['name']?.toString();
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id'] != null ? (json['tax_id'] as num).toInt() : null;
    imageUrl = json['image_url']?.toString();
    isActive = json['isActive'] as bool?;  // ✅ ADD THIS LINE
    description = json['description']?.toString();
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

class Variants {
  String? name;
  num? price;
  String? itemCode;
  String? imageUrl;
  String? description;
  int? id;
  List<EnrichedToppingGroups>? enrichedToppingGroups;
  Variants(
      {this.name,
        this.price,
        this.itemCode,
        this.imageUrl,
        this.description,
        this.id,
        this.enrichedToppingGroups,
      });

  Variants.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price'] as num?;
    itemCode = json['item_code'];
    imageUrl = json['image_url'];
    description = json['description'];
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    if (json['enriched_topping_groups'] != null) {
      enrichedToppingGroups = <EnrichedToppingGroups>[];
      json['enriched_topping_groups'].forEach((v) {
        enrichedToppingGroups!.add(EnrichedToppingGroups.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['item_code'] = itemCode;
    data['image_url'] = imageUrl;
    data['description'] = description;
    data['id'] = id;
    if (enrichedToppingGroups != null) {
      data['enriched_topping_groups'] =
          enrichedToppingGroups!.map((v) => v.toJson()).toList();
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
    name = json['name']?.toString();
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

class EnrichedToppingGroups {
  int? id;
  String? name;
  int? minSelect;
  int? maxSelect;
  bool? isRequired;
  List<Toppings>? toppings;

  EnrichedToppingGroups(
      {this.id,
        this.name,
        this.minSelect,
        this.maxSelect,
        this.isRequired,
        this.toppings});

  EnrichedToppingGroups.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    minSelect = json['min_select'];
    maxSelect = json['max_select'];
    isRequired = json['is_required'];
    if (json['toppings'] != null) {
      toppings = <Toppings>[];
      json['toppings'].forEach((v) {
        toppings!.add(Toppings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['min_select'] = minSelect;
    data['max_select'] = maxSelect;
    data['is_required'] = isRequired;
    if (toppings != null) {
      data['toppings'] = toppings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Toppings {
  String? name;
  String? description;
  double? price;
  int? storeId;
  bool? isActive;
  int? id;

  Toppings(
      {this.name,
        this.description,
        this.price,
        this.storeId,
        this.isActive,
        this.id});

  Toppings.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    price = json['price'];
    storeId = json['store_id'];
    isActive = json['isActive'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['store_id'] = storeId;
    data['isActive'] = isActive;
    data['id'] = id;
    return data;
  }
}
