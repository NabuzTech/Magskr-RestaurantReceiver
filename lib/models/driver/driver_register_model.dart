class DriverRegisterModel {
  String? message;
  int? driverId;
  int? userId;
  int? storeId;

  DriverRegisterModel({this.message, this.driverId, this.userId, this.storeId});

  DriverRegisterModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    driverId = json['driver_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['driver_id'] = driverId;
    data['user_id'] = userId;
    data['store_id'] = storeId;
    return data;
  }
}