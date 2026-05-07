class ChangePasswordModel {
  String? msg;

  ChangePasswordModel({this.msg});

  ChangePasswordModel.fromJson(Map<String, dynamic> json) {
    msg = json['msg'];
  }
}
