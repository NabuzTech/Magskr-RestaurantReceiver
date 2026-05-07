import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';

class SocketService {
  WebSocketChannel? channel;
  String? currentStoreId;
  StreamSubscription? _subscription;

  // ✅ Stream controller for store status
  final _storeStatusController = StreamController<Map<String, dynamic>>.broadcast();

  // ✅ Public stream getter
  Stream<Map<String, dynamic>> get storeStatusStream => _storeStatusController.stream;

  // ✅ Connect to WebSocket with Bearer token
  Future<void> connect() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      currentStoreId = prefs.getString(valueShared_STORE_KEY);
      String? token = prefs.getString(valueShared_BEARER_KEY);

      if (currentStoreId == null) {
        print("❌ Store ID is null. Cannot connect to socket.");
        return;
      }

      if (token == null) {
        print("❌ Token is null. Cannot connect to socket.");
        return;
      }

      print("🔌 Connecting to WebSocket for store: $currentStoreId");
      print("🔑 Using token: ${token.substring(0, 20)}...");

      // ✅ Correct WebSocket URL with wss:// (secure) or ws://
      final wsUrl = Uri.parse('wss://magskr.com/ws/store/$currentStoreId/status');

      // ✅ Create WebSocket connection with Authorization header
      channel = WebSocketChannel.connect(
        wsUrl,
        // protocols: ['Bearer', token], // Some servers use this
      );

      // ✅ Send authorization message after connection (if server expects it)
      channel?.sink.add(jsonEncode({
        'type': 'auth',
        'token': token,
      }));

      // ✅ Listen to messages
      _subscription = channel!.stream.listen(
            (message) {
          print("📡 WebSocket received: $message");
          try {
            var data = jsonDecode(message);
            if (data is Map) {
              _storeStatusController.add(Map<String, dynamic>.from(data));
            }
          } catch (e) {
            print("⚠️ Error parsing message: $e");
            // If message is already a Map
            if (message is Map) {
              _storeStatusController.add(Map<String, dynamic>.from(message));
            }
          }
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
        },
        onDone: () {
          print("🔌 WebSocket connection closed");
        },
      );

      print("✅ WebSocket connected successfully");

    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
    }
  }

  // ✅ Listen to store status (not needed for direct WebSocket, but keep for compatibility)
  void listenToStoreStatus(String storeId) {
    print("🔊 WebSocket already listening to store status for: $storeId");
  }

  // ✅ Check if connected
  bool isConnected() {
    return channel != null && _subscription != null;
  }

  // ✅ Reconnect if disconnected
  Future<void> ensureConnected() async {
    if (!isConnected()) {
      print("🔄 WebSocket not connected. Reconnecting...");
      await connect();
      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  // ✅ Disconnect
  void disconnect() {
    print("🔌 Disconnecting WebSocket...");
    _subscription?.cancel();
    _subscription = null;
    channel?.sink.close();
    channel = null;
  }

  // ✅ Dispose
  void dispose() {
    disconnect();
    _storeStatusController.close();
  }
}