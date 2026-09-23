class UpdatePaymentByOrderTypeModel {
  int? storeId;
  int? orderType;
  String? orderTypeName;
  bool? isOverride;
  Flags? flags;

  UpdatePaymentByOrderTypeModel(
      {this.storeId,
        this.orderType,
        this.orderTypeName,
        this.isOverride,
        this.flags});

  UpdatePaymentByOrderTypeModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    orderType = json['order_type'];
    orderTypeName = json['order_type_name'];
    isOverride = json['is_override'];
    flags = json['flags'] != null ? new Flags.fromJson(json['flags']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['order_type'] = this.orderType;
    data['order_type_name'] = this.orderTypeName;
    data['is_override'] = this.isOverride;
    if (this.flags != null) {
      data['flags'] = this.flags!.toJson();
    }
    return data;
  }
}

class Flags {
  bool? cashEnabled;
  bool? cardEnabled;
  bool? stripeEnabled;
  bool? paypalEnabled;
  bool? ecEnabled;

  Flags(
      {this.cashEnabled,
        this.cardEnabled,
        this.stripeEnabled,
        this.paypalEnabled,
        this.ecEnabled});

  Flags.fromJson(Map<String, dynamic> json) {
    cashEnabled = json['cash_enabled'];
    cardEnabled = json['card_enabled'];
    stripeEnabled = json['stripe_enabled'];
    paypalEnabled = json['paypal_enabled'];
    ecEnabled = json['ec_enabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cash_enabled'] = this.cashEnabled;
    data['card_enabled'] = this.cardEnabled;
    data['stripe_enabled'] = this.stripeEnabled;
    data['paypal_enabled'] = this.paypalEnabled;
    data['ec_enabled'] = this.ecEnabled;
    return data;
  }
}
