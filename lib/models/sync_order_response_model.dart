class SyncLocalOrder {
  String? status;
  int? limit;
  int? offset;
  int? processed;
  List<int>? syncedOrderIds;

  SyncLocalOrder(
      {this.status,
        this.limit,
        this.offset,
        this.processed,
        this.syncedOrderIds});

  SyncLocalOrder.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    limit = json['limit'];
    offset = json['offset'];
    processed = json['processed'];
    syncedOrderIds = json['synced_order_ids'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['limit'] = limit;
    data['offset'] = offset;
    data['processed'] = processed;
    data['synced_order_ids'] = syncedOrderIds;
    return data;
  }
}