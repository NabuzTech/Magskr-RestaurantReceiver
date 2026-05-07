class Invoice {
  String? invoiceNumber;
  double? totalAmount;
  DateTime? issuedAt;
  int? storeId;
  int? id;
  int? orderId;
  double? delivery_fee;
  double? discount_amount;

  Invoice({
    this.invoiceNumber,
    this.totalAmount,
    this.issuedAt,
    this.storeId,
    this.id,
    this.orderId,
    this.delivery_fee,
    this.discount_amount,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        invoiceNumber: json["invoice_number"],
        totalAmount: (json["total_amount"] as num?)?.toDouble(),
        issuedAt: DateTime.tryParse(json["issued_at"]),
        storeId: json["store_id"],
        id: json["id"],
        orderId: json["order_id"],
        delivery_fee: (json["delivery_fee"] as num?)?.toDouble(),
        discount_amount: (json["discount_amount"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "invoice_number": invoiceNumber,
        "total_amount": totalAmount,
        "issued_at": issuedAt?.toIso8601String(),
        "store_id": storeId,
        "id": id,
        "order_id": orderId,
        "delivery_fee": delivery_fee,
        "discount_amount": discount_amount,
      };
}
