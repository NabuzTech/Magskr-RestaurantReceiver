class TaxSummary {
  double? taxRate;
  double? taxAmount;

  TaxSummary({this.taxRate, this.taxAmount});

  factory TaxSummary.fromJson(Map<String, dynamic> json) => TaxSummary(
    taxRate: (json["tax_rate"] as num?)?.toDouble(),
    taxAmount: (json["tax_amount"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "tax_rate": taxRate,
    "tax_amount": taxAmount,
  };
}
