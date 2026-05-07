// class DeviceStatusResponseModel {
//   List<Alive>? alive;
//   List<Stale>? stale;
//   Summary? summary;
//
//   DeviceStatusResponseModel({this.alive, this.stale, this.summary});
//
//   DeviceStatusResponseModel.fromJson(Map<String, dynamic> json) {
//     if (json['alive'] != null) {
//       alive = <Alive>[];
//       json['alive'].forEach((v) {
//         alive!.add(new Alive.fromJson(v));
//       });
//     }
//     if (json['stale'] != null) {
//       stale = <Stale>[];
//       json['stale'].forEach((v) {
//         stale!.add(new Stale.fromJson(v));
//       });
//     }
//     summary =
//     json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.alive != null) {
//       data['alive'] = this.alive!.map((v) => v.toJson()).toList();
//     }
//     if (this.stale != null) {
//       data['stale'] = this.stale!.map((v) => v.toJson()).toList();
//     }
//     if (this.summary != null) {
//       data['summary'] = this.summary!.toJson();
//     }
//     return data;
//   }
// }
//
// class Alive {
//   int? storeId;
//   String? storeName;
//   String? username;
//   String? lastHeartbeat;
//   int? secondsSinceHeartbeat;
//   bool? isAlive;
//   bool? isConnected;
//   bool? websocketConnected;
//
//   Alive(
//       {this.storeId,
//         this.storeName,
//         this.username,
//         this.lastHeartbeat,
//         this.secondsSinceHeartbeat,
//         this.isAlive,
//         this.isConnected,
//         this.websocketConnected});
//
//   Alive.fromJson(Map<String, dynamic> json) {
//     storeId = json['store_id'];
//     storeName = json['store_name'];
//     username = json['username'];
//     lastHeartbeat = json['last_heartbeat'];
//     secondsSinceHeartbeat = json['seconds_since_heartbeat'];
//     isAlive = json['is_alive'];
//     isConnected = json['is_connected'];
//     websocketConnected = json['websocket_connected'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['store_id'] = this.storeId;
//     data['store_name'] = this.storeName;
//     data['username'] = this.username;
//     data['last_heartbeat'] = this.lastHeartbeat;
//     data['seconds_since_heartbeat'] = this.secondsSinceHeartbeat;
//     data['is_alive'] = this.isAlive;
//     data['is_connected'] = this.isConnected;
//     data['websocket_connected'] = this.websocketConnected;
//     return data;
//   }
// }
//
// class Summary {
//   int? total;
//   int? alive;
//   int? stale;
//
//   Summary({this.total, this.alive, this.stale});
//
//   Summary.fromJson(Map<String, dynamic> json) {
//     total = json['total'];
//     alive = json['alive'];
//     stale = json['stale'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['total'] = this.total;
//     data['alive'] = this.alive;
//     data['stale'] = this.stale;
//     return data;
//   }
// }
class DeviceStatusResponseModel {
  final List<DeviceStatus>? alive;
  final List<DeviceStatus>? stale;
  final StatusSummary? summary;

  DeviceStatusResponseModel({
    this.alive,
    this.stale,
    this.summary,
  });

  factory DeviceStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return DeviceStatusResponseModel(
      alive: json['alive'] != null
          ? List<DeviceStatus>.from(
        json['alive'].map((x) => DeviceStatus.fromJson(x)),
      )
          : [],
      stale: json['stale'] != null
          ? List<DeviceStatus>.from(
        json['stale'].map((x) => DeviceStatus.fromJson(x)),
      )
          : [],
      summary: json['summary'] != null
          ? StatusSummary.fromJson(json['summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alive': alive?.map((x) => x.toJson()).toList(),
      'stale': stale?.map((x) => x.toJson()).toList(),
      'summary': summary?.toJson(),
    };
  }
}
class DeviceStatus {
  final int? storeId;
  final String? storeName;
  final String? username;
  final String? lastHeartbeat;
  final int? secondsSinceHeartbeat;
  final bool? isAlive;
  final bool? isConnected;
  final bool? websocketConnected;

  DeviceStatus({
    this.storeId,
    this.storeName,
    this.username,
    this.lastHeartbeat,
    this.secondsSinceHeartbeat,
    this.isAlive,
    this.isConnected,
    this.websocketConnected,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      storeId: json['store_id'],
      storeName: json['store_name'],
      username: json['username'],
      lastHeartbeat: json['last_heartbeat'],
      secondsSinceHeartbeat: json['seconds_since_heartbeat'],
      isAlive: json['is_alive'],
      isConnected: json['is_connected'],
      websocketConnected: json['websocket_connected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'username': username,
      'last_heartbeat': lastHeartbeat,
      'seconds_since_heartbeat': secondsSinceHeartbeat,
      'is_alive': isAlive,
      'is_connected': isConnected,
      'websocket_connected': websocketConnected,
    };
  }
}
class StatusSummary {
  final int? total;
  final int? alive;
  final int? stale;

  StatusSummary({
    this.total,
    this.alive,
    this.stale,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      total: json['total'],
      alive: json['alive'],
      stale: json['stale'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'alive': alive,
      'stale': stale,
    };
  }
}

