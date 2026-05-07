class printOrderWithoutIp {
  String? detail;
  int? orderId;

  printOrderWithoutIp({this.detail, this.orderId});

  printOrderWithoutIp.fromJson(Map<String, dynamic> json) {
    detail = json['detail'];
    orderId = json['order_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['detail'] = detail;
    data['order_id'] = orderId;
    return data;
  }
}