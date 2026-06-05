class LogoutStoreBySuperAdmin {
  String? msg;
  int? sessionsDeleted;
  int? tokensDeleted;

  LogoutStoreBySuperAdmin({this.msg, this.sessionsDeleted, this.tokensDeleted});

  LogoutStoreBySuperAdmin.fromJson(Map<String, dynamic> json) {
    msg = json['msg'];
    sessionsDeleted = json['sessions_deleted'];
    tokensDeleted = json['tokens_deleted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['msg'] = this.msg;
    data['sessions_deleted'] = this.sessionsDeleted;
    data['tokens_deleted'] = this.tokensDeleted;
    return data;
  }
}