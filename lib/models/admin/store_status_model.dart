class storeStatusModel {
  int? id;
  String? name;
  bool? isActive;
  int? storeType;
  String? address;

  storeStatusModel(
      {this.id, this.name, this.isActive, this.storeType, this.address});

  storeStatusModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isActive = json['is_active'];
    storeType = json['store_type'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['is_active'] = this.isActive;
    data['store_type'] = this.storeType;
    data['address'] = this.address;
    return data;
  }
}
