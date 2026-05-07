class GetPrinterIpResponseModel {
  String? name;
  String? ipAddress;
  int? storeId;
  bool? isActive;
  int? type;
  String? categoryId;
  bool? isRemote;
  int? id;

  GetPrinterIpResponseModel(
      {this.name,
        this.ipAddress,
        this.storeId,
        this.isActive,
        this.type,
        this.categoryId,
        this.isRemote,
        this.id});

  GetPrinterIpResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    ipAddress = json['ip_address'];
    storeId = json['store_id'];
    isActive = json['isActive'];
    type = json['type'];
    categoryId = json['category_id'];
    isRemote = json['isRemote'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['ip_address'] = ipAddress;
    data['store_id'] = storeId;
    data['isActive'] = isActive;
    data['type'] = type;
    data['category_id'] = categoryId;
    data['isRemote'] = isRemote;
    data['id'] = id;
    return data;
  }
}