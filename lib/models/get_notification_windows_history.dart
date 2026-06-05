class GetWindowsNotificationHistory {
  int? days;
  int? totalStores;
  int? totalEvents;
  List<Stores>? stores;

  GetWindowsNotificationHistory(
      {this.days, this.totalStores, this.totalEvents, this.stores});

  GetWindowsNotificationHistory.fromJson(Map<String, dynamic> json) {
    days = json['days'];
    totalStores = json['total_stores'];
    totalEvents = json['total_events'];
    if (json['stores'] != null) {
      stores = <Stores>[];
      json['stores'].forEach((v) {
        stores!.add(new Stores.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['days'] = this.days;
    data['total_stores'] = this.totalStores;
    data['total_events'] = this.totalEvents;
    if (this.stores != null) {
      data['stores'] = this.stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Stores {
  int? storeId;
  String? storeName;
  int? total;
  List<Events>? events;

  Stores({this.storeId, this.storeName, this.total, this.events});

  Stores.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    total = json['total'];
    if (json['events'] != null) {
      events = <Events>[];
      json['events'].forEach((v) {
        events!.add(new Events.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['total'] = this.total;
    if (this.events != null) {
      data['events'] = this.events!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Events {
  int? id;
  String? state;
  String? occurredAt;

  Events({this.id, this.state, this.occurredAt});

  Events.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    state = json['state'];
    occurredAt = json['occurred_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['state'] = this.state;
    data['occurred_at'] = this.occurredAt;
    return data;
  }
}