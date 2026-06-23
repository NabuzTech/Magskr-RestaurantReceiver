class EditPaymentMethodModel {
  int? orderId;
  String? paymentMethod;
  String? paymentStatus;
  bool? autoAccepted;
  String? message;

  EditPaymentMethodModel(
      {this.orderId,
        this.paymentMethod,
        this.paymentStatus,
        this.autoAccepted,
        this.message});

  EditPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    paymentMethod = json['payment_method'];
    paymentStatus = json['payment_status'];
    autoAccepted = json['auto_accepted'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_id'] = this.orderId;
    data['payment_method'] = this.paymentMethod;
    data['payment_status'] = this.paymentStatus;
    data['auto_accepted'] = this.autoAccepted;
    data['message'] = this.message;
    return data;
  }
}