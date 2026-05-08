class ResetStorePasswordBySuperAdminModel {
  int? storeId;
  int? resetCount;
  List<String>? usernames;

  ResetStorePasswordBySuperAdminModel(
      {this.storeId, this.resetCount, this.usernames});

  ResetStorePasswordBySuperAdminModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    resetCount = json['reset_count'];
    usernames = json['usernames'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['reset_count'] = this.resetCount;
    data['usernames'] = this.usernames;
    return data;
  }
}