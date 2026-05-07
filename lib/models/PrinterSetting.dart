
class PrinterSetting {
  String? name;
  String? ipAddress;
  int? storeId;
  bool? isActive;
  int? type;
  int? categoryId;
  bool? isRemote;
  int? id;
  String? msg;
  int? code;
  String? mess;

  PrinterSetting({
    this.name,
    this.ipAddress,
    this.storeId,
    this.isActive,
    this.type,
    this.categoryId,
    this.isRemote,
    this.id,
    this.msg,
    this.code,
    this.mess,
  });

  PrinterSetting.withError({
    this.code,
    this.mess,
  });

  factory PrinterSetting.fromJson(Map<String, dynamic> json) =>
      PrinterSetting(
        name: json["name"],
        ipAddress: json["ip_address"],
        storeId: json["store_id"],
        isActive: json["isActive"],
        type: json["type"],
        categoryId: json["category_id"],
        isRemote: json["isRemote"],
        id: json["id"],
        msg: json["msg"],
      );
}
