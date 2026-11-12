class BookingV2DetailsModel {
  int? id;
  int? storeId;
  int? userId;
  int? serviceId;
  int? resourceId;
  String? reference;
  String? startAt;
  String? endAt;
  String? blockedUntil;
  int? durationMinutes;
  int? partySize;
  int? units;
  String? status;
  String? paymentStatus;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  FormData? formData;
  dynamic selectedOptions;
  int? priceTotal;
  double? depositAmount;
  String? currency;
  String? createdAt;

BookingV2DetailsModel(
      {this.id,
        this.storeId,
        this.userId,
        this.serviceId,
        this.resourceId,
        this.reference,
        this.startAt,
        this.endAt,
        this.blockedUntil,
        this.durationMinutes,
        this.partySize,
        this.units,
        this.status,
        this.paymentStatus,
        this.customerName,
        this.customerPhone,
        this.customerEmail,
        this.note,
        this.formData,
        this.selectedOptions,
        this.priceTotal,
        this.depositAmount,
        this.currency,
        this.createdAt});

BookingV2DetailsModel.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num?)?.toInt();
    storeId = (json['store_id'] as num?)?.toInt();
    userId = (json['user_id'] as num?)?.toInt();
    serviceId = (json['service_id'] as num?)?.toInt();
    resourceId = (json['resource_id'] as num?)?.toInt();
    reference = json['reference'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    blockedUntil = json['blocked_until'];
    durationMinutes = (json['duration_minutes'] as num?)?.toInt();
    partySize = (json['party_size'] as num?)?.toInt();
    units = (json['units'] as num?)?.toInt();
    status = json['status'];
    paymentStatus = json['payment_status'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
    formData = json['form_data'] != null
        ? new FormData.fromJson(json['form_data'])
        : null;
    selectedOptions = json['selected_options'];
    priceTotal = (json['price_total'] as num?)?.toInt();
    depositAmount = (json['deposit_amount'] as num?)?.toDouble();
    currency = json['currency'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['user_id'] = this.userId;
    data['service_id'] = this.serviceId;
    data['resource_id'] = this.resourceId;
    data['reference'] = this.reference;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['blocked_until'] = this.blockedUntil;
    data['duration_minutes'] = this.durationMinutes;
    data['party_size'] = this.partySize;
    data['units'] = this.units;
    data['status'] = this.status;
    data['payment_status'] = this.paymentStatus;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_email'] = this.customerEmail;
    data['note'] = this.note;
    if (this.formData != null) {
      data['form_data'] = this.formData!.toJson();
    }
    data['selected_options'] = this.selectedOptions;
    data['price_total'] = this.priceTotal;
    data['deposit_amount'] = this.depositAmount;
    data['currency'] = this.currency;
    data['created_at'] = this.createdAt;
    return data;
  }
}

class FormData {
  String? childDob;
  String? childName;
  bool? isBirthday;
  String? childFavouriteTeam;

  FormData(
      {this.childDob,
        this.childName,
        this.isBirthday,
        this.childFavouriteTeam});

  FormData.fromJson(Map<String, dynamic> json) {
    childDob = json['child_dob'];
    childName = json['child_name'];
    isBirthday = json['is_birthday'];
    childFavouriteTeam = json['child_favourite_team'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['child_dob'] = this.childDob;
    data['child_name'] = this.childName;
    data['is_birthday'] = this.isBirthday;
    data['child_favourite_team'] = this.childFavouriteTeam;
    return data;
  }
}
