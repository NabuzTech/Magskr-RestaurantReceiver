class GetTodayReceivedReservationV2SuperAdminModel {
  String? date;
  int? storeCount;
  Totals? totals;
  List<Stores>? stores;

  GetTodayReceivedReservationV2SuperAdminModel(
      {this.date, this.storeCount, this.totals, this.stores});

  GetTodayReceivedReservationV2SuperAdminModel.fromJson(
      Map<String, dynamic> json) {
    date = json['date'];
    storeCount = json['store_count'];
    totals =
    json['totals'] != null ? new Totals.fromJson(json['totals']) : null;
    if (json['stores'] != null) {
      stores = <Stores>[];
      json['stores'].forEach((v) {
        stores!.add(new Stores.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['store_count'] = this.storeCount;
    if (this.totals != null) {
      data['totals'] = this.totals!.toJson();
    }
    if (this.stores != null) {
      data['stores'] = this.stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Totals {
  int? total;
  int? pending;
  int? booked;
  int? cancelled;
  int? activeTotal;
  int? pendingCovers;
  int? bookedCovers;
  int? activeCovers;
  int? upcomingPending;
  int? upcomingBooked;
  int? upcomingTotal;
  int? upcomingPendingCovers;
  int? upcomingBookedCovers;
  Null? nextUpcomingDate;
  bool? upcomingPendingTruncated;

  Totals(
      {this.total,
        this.pending,
        this.booked,
        this.cancelled,
        this.activeTotal,
        this.pendingCovers,
        this.bookedCovers,
        this.activeCovers,
        this.upcomingPending,
        this.upcomingBooked,
        this.upcomingTotal,
        this.upcomingPendingCovers,
        this.upcomingBookedCovers,
        this.nextUpcomingDate,
        this.upcomingPendingTruncated});

  Totals.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    pending = json['pending'];
    booked = json['booked'];
    cancelled = json['cancelled'];
    activeTotal = json['active_total'];
    pendingCovers = json['pending_covers'];
    bookedCovers = json['booked_covers'];
    activeCovers = json['active_covers'];
    upcomingPending = json['upcoming_pending'];
    upcomingBooked = json['upcoming_booked'];
    upcomingTotal = json['upcoming_total'];
    upcomingPendingCovers = json['upcoming_pending_covers'];
    upcomingBookedCovers = json['upcoming_booked_covers'];
    nextUpcomingDate = json['next_upcoming_date'];
    upcomingPendingTruncated = json['upcoming_pending_truncated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['pending'] = this.pending;
    data['booked'] = this.booked;
    data['cancelled'] = this.cancelled;
    data['active_total'] = this.activeTotal;
    data['pending_covers'] = this.pendingCovers;
    data['booked_covers'] = this.bookedCovers;
    data['active_covers'] = this.activeCovers;
    data['upcoming_pending'] = this.upcomingPending;
    data['upcoming_booked'] = this.upcomingBooked;
    data['upcoming_total'] = this.upcomingTotal;
    data['upcoming_pending_covers'] = this.upcomingPendingCovers;
    data['upcoming_booked_covers'] = this.upcomingBookedCovers;
    data['next_upcoming_date'] = this.nextUpcomingDate;
    data['upcoming_pending_truncated'] = this.upcomingPendingTruncated;
    return data;
  }
}

class Stores {
  int? storeId;
  String? storeName;
  Totals? summary;

  Stores({this.storeId, this.storeName, this.summary});

  Stores.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    summary =
    json['summary'] != null ? new Totals.fromJson(json['summary']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    return data;
  }
}
