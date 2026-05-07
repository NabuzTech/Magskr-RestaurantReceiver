class ManualOverrideResponseModel {
  String? message;
  int? storeId;
  bool? isManualOverride;
  String? manualStatus;

  ManualOverrideResponseModel(
      {this.message, this.storeId, this.isManualOverride, this.manualStatus});

  ManualOverrideResponseModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    storeId = json['store_id'];
    isManualOverride = json['is_manual_override'];
    manualStatus = json['manual_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['store_id'] = storeId;
    data['is_manual_override'] = isManualOverride;
    data['manual_status'] = manualStatus;
    return data;
  }
}