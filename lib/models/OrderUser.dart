class OrderUser {
  String? username;
  int? id;
  int? storeId;
  int? roleId;

  OrderUser({this.username, this.id, this.storeId, this.roleId});

  factory OrderUser.fromJson(Map<String, dynamic> json) => OrderUser(
    username: json["username"],
    id: json["id"],
    storeId: json["store_id"],
    roleId: json["role_id"],
  );

  Map<String, dynamic> toJson() => {
    "username": username,
    "id": id,
    "store_id": storeId,
    "role_id": roleId,
  };
}
