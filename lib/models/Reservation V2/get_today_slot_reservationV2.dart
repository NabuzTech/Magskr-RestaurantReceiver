class GetTodaySlotOfReservation {
  int? storeId;
  String? date;
  int? partySize;
  bool? enabled;
  String? reason;
  List<Slots>? slots;

  GetTodaySlotOfReservation(
      {this.storeId,
        this.date,
        this.partySize,
        this.enabled,
        this.reason,
        this.slots});

  GetTodaySlotOfReservation.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    date = json['date'];
    partySize = json['party_size'];
    enabled = json['enabled'];
    reason = json['reason'];
    if (json['slots'] != null) {
      slots = <Slots>[];
      json['slots'].forEach((v) {
        slots!.add(new Slots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['date'] = this.date;
    data['party_size'] = this.partySize;
    data['enabled'] = this.enabled;
    data['reason'] = this.reason;
    if (this.slots != null) {
      data['slots'] = this.slots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Slots {
  String? time;
  String? datetime;
  int? available;
  int? total;
  bool? bookable;

  Slots({this.time, this.datetime, this.available, this.total, this.bookable});

  Slots.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    datetime = json['datetime'];
    available = json['available'];
    total = json['total'];
    bookable = json['bookable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['datetime'] = this.datetime;
    data['available'] = this.available;
    data['total'] = this.total;
    data['bookable'] = this.bookable;
    return data;
  }
}
