class GetCategoryAvailabilityResponseModel {
  final String name;
  final int storeId;
  final int taxId;
  final String? imageUrl;
  final bool isActive;
  final String description;
  final int displayOrder;
  final int id;
  final Tax tax;
  final List<CategoryAvailability> categoriesAvailability;

  GetCategoryAvailabilityResponseModel({
    required this.name,
    required this.storeId,
    required this.taxId,
    this.imageUrl,
    required this.isActive,
    required this.description,
    required this.displayOrder,
    required this.id,
    required this.tax,
    required this.categoriesAvailability,
  });

  factory GetCategoryAvailabilityResponseModel.fromJson(Map<String, dynamic> json) {
    return GetCategoryAvailabilityResponseModel(
      name: json['name'] as String? ?? '',
      storeId: json['store_id'] as int? ?? 0,
      taxId: json['tax_id'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      tax: json['tax'] != null
          ? Tax.fromJson(json['tax'] as Map<String, dynamic>)
          : Tax(name: '', percentage: 0, storeId: 0, id: 0),
      categoriesAvailability: (json['categories_availability'] as List<dynamic>?)
          ?.map((e) => CategoryAvailability.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],  // Agar null hai to empty list return karega
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'store_id': storeId,
      'tax_id': taxId,
      'image_url': imageUrl,
      'isActive': isActive,
      'description': description,
      'display_order': displayOrder,
      'id': id,
      'tax': tax.toJson(),
      'categories_availability': categoriesAvailability.map((e) => e.toJson()).toList(),
    };
  }

  static List<GetCategoryAvailabilityResponseModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => GetCategoryAvailabilityResponseModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

class Tax {
  final String name;
  final num percentage;
  final int storeId;
  final int id;

  Tax({
    required this.name,
    required this.percentage,
    required this.storeId,
    required this.id,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      name: json['name'] as String,
      percentage: json['percentage'] as num,
      storeId: json['store_id'] as int,
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'percentage': percentage,
      'store_id': storeId,
      'id': id,
    };
  }
}

class CategoryAvailability {
  final int categoryId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String label;
  final bool isActive;
  final int id;
  final int storeId;

  CategoryAvailability({
    required this.categoryId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.isActive,
    required this.id,
    required this.storeId,
  });

  factory CategoryAvailability.fromJson(Map<String, dynamic> json) {
    return CategoryAvailability(
      categoryId: json['category_id'] as int? ?? 0,
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      id: json['id'] as int? ?? 0,
      storeId: json['store_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'label': label,
      'isActive': isActive,
      'id': id,
      'store_id': storeId,
    };
  }
}