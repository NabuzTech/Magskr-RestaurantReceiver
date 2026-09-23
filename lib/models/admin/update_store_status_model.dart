class UpdateStoreStatusModel {
  int? id;
  String? name;
  bool? isActive;
  String? message;

  UpdateStoreStatusModel({this.id, this.name, this.isActive, this.message});

  UpdateStoreStatusModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isActive = json['is_active'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['is_active'] = this.isActive;
    data['message'] = this.message;
    return data;
  }
}
