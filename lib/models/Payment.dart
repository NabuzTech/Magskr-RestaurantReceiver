class Payment {
  String? paymentMethod;
  String? status;
  DateTime? paidAt;
  int? id;
  int? orderId;
  double? amount;

  Payment({
    this.paymentMethod,
    this.status,
    this.paidAt,
    this.id,
    this.orderId,
    this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    paymentMethod: json["payment_method"],
    status: json["status"],
    paidAt: DateTime.tryParse(json["paid_at"]),
    id: json["id"],
    orderId: json["order_id"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "payment_method": paymentMethod,
    "status": status,
    "paid_at": paidAt?.toIso8601String(),
    "id": id,
    "order_id": orderId,
    "amount": amount,
  };
}
