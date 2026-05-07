class GetSpecificStoreDeviceStatus {
  int? storeId;
  String? storeName;
  String? username;
  String? lastHeartbeat;
  int? secondsSinceHeartbeat;
  bool? isAlive;
  bool? isConnected;
  bool? websocketConnected;

  GetSpecificStoreDeviceStatus(
      {this.storeId,
        this.storeName,
        this.username,
        this.lastHeartbeat,
        this.secondsSinceHeartbeat,
        this.isAlive,
        this.isConnected,
        this.websocketConnected});

  GetSpecificStoreDeviceStatus.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    username = json['username'];
    lastHeartbeat = json['last_heartbeat'];
    secondsSinceHeartbeat = json['seconds_since_heartbeat'];
    isAlive = json['is_alive'];
    isConnected = json['is_connected'];
    websocketConnected = json['websocket_connected'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['username'] = username;
    data['last_heartbeat'] = lastHeartbeat;
    data['seconds_since_heartbeat'] = secondsSinceHeartbeat;
    data['is_alive'] = isAlive;
    data['is_connected'] = isConnected;
    data['websocket_connected'] = websocketConnected;
    return data;
  }
}