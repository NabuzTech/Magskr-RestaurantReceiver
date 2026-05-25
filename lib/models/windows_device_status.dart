class WindowsDeviceStatus {
  Summary? summary;
  List<Online>? online;
  List<Offline>? offline;

  WindowsDeviceStatus({this.summary, this.online, this.offline});

  WindowsDeviceStatus.fromJson(Map<String, dynamic> json) {
    summary =
    json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    if (json['online'] != null) {
      online = <Online>[];
      json['online'].forEach((v) {
        online!.add(new Online.fromJson(v));
      });
    }
    if (json['offline'] != null) {
      offline = <Offline>[];
      json['offline'].forEach((v) {
        offline!.add(new Offline.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    if (this.online != null) {
      data['online'] = this.online!.map((v) => v.toJson()).toList();
    }
    if (this.offline != null) {
      data['offline'] = this.offline!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Summary {
  int? total;
  int? online;
  int? offline;

  Summary({this.total, this.online, this.offline});

  Summary.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    online = json['online'];
    offline = json['offline'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['online'] = this.online;
    data['offline'] = this.offline;
    return data;
  }
}

class Online {
  int? storeId;
  String? storeName;
  bool? online;
  String? since;

  Online({this.storeId, this.storeName, this.online, this.since});

  Online.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    online = json['online'];
    since = json['since'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['online'] = this.online;
    data['since'] = this.since;
    return data;
  }
}

class Offline {
  int? storeId;
  String? storeName;
  bool? online;
  String? since;

  Offline({this.storeId, this.storeName, this.online, this.since});

  Offline.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    online = json['online'];
    since = json['since'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['online'] = this.online;
    data['since'] = this.since;
    return data;
  }
}