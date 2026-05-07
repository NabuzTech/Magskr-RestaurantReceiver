class UserMe {
  String? username;
  int? id;
  int? store_id;
  int? role_id;
  int? code;
  String? mess;

  UserMe({
    this.username,
    this.id,
    this.store_id,
    this.role_id,
    this.code,
    this.mess,
  });

  UserMe.withError({
    int? code,
    String? mess,
  })  : code = code,
        mess = mess;

  factory UserMe.fromJson(Map<String, dynamic> json) => UserMe(
        username: json["username"],
        id: json["id"],
        store_id: json["store_id"],
        role_id: json["role_id"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "id": id,
        "store_id": store_id,
        "role_id": role_id,
      };
}
