class EditAllergyResponseModel {
  String? name;
  String? description;
  int? storeId;
  String? imageUrl;
  int? id;

  EditAllergyResponseModel(
      {this.name, this.description, this.storeId, this.imageUrl, this.id});

  EditAllergyResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    storeId = json['store_id'];
    imageUrl = json['image_url'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['store_id'] = storeId;
    data['image_url'] = imageUrl;
    data['id'] = id;
    return data;
  }
}