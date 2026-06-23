class BulkDeleteOrderResponse {
  List<int>? deleted;
  List<int>? notFound;
  List<ReportRebuilt>? reportsRebuilt;
  String? error;

  BulkDeleteOrderResponse({
    this.deleted,
    this.notFound,
    this.reportsRebuilt,
  });

  BulkDeleteOrderResponse.withError(this.error);

  factory BulkDeleteOrderResponse.fromJson(Map<String, dynamic> json) {
    return BulkDeleteOrderResponse(
      deleted: json['deleted'] != null
          ? List<int>.from(json['deleted'])
          : [],
      notFound: json['not_found'] != null
          ? List<int>.from(json['not_found'])
          : [],
      reportsRebuilt: json['reports_rebuilt'] != null
          ? (json['reports_rebuilt'] as List)
              .map((e) => ReportRebuilt.fromJson(e))
              .toList()
          : [],
    );
  }
}

class ReportRebuilt {
  int? storeId;
  String? date;
  String? result;

  ReportRebuilt({this.storeId, this.date, this.result});

  factory ReportRebuilt.fromJson(Map<String, dynamic> json) {
    return ReportRebuilt(
      storeId: json['store_id'],
      date: json['date'],
      result: json['result'],
    );
  }
}
