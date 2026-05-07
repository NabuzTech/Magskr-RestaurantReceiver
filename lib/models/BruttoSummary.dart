class BruttoSummary {
  double? taxRate;
  double? brutto;
  double? netto;
  double? tax_amount;

  BruttoSummary({this.taxRate, this.brutto, this.netto, this.tax_amount});

  factory BruttoSummary.fromJson(Map<String, dynamic> json) => BruttoSummary(
        taxRate: (json["tax_rate"] as num?)?.toDouble(),
        brutto: (json["brutto"] as num?)?.toDouble(),
        netto: (json["netto"] as num?)?.toDouble(),
        tax_amount: (json["tax_amount"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "tax_rate": taxRate,
        "brutto": brutto,
        "netto": netto,
        "tax_amount": tax_amount,
      };
}
