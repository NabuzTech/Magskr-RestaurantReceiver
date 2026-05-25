import 'package:flutter/material.dart';
import 'package:food_receiver/Database/databse_helper.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final String? storeId;
  NotificationController({this.storeId});

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final list = await DatabaseHelper().getNotifications(storeId: storeId);
    notifications.assignAll(list);
  }

  Future<void> clearAll() async {
    await DatabaseHelper().clearAllNotifications(storeId: storeId);
    notifications.clear();
  }
}

class NotificationScreen extends StatefulWidget {
  final String? storeId;
  const NotificationScreen({super.key, this.storeId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late NotificationController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>(force: true);
    }
    controller = Get.put(NotificationController(storeId: widget.storeId));
  }

  @override
  void dispose() {
    Get.delete<NotificationController>(force: true);
    super.dispose();
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconForTitle(String title) {
    if (title.toLowerCase().contains('online')) return Icons.computer;
    if (title.toLowerCase().contains('offline')) return Icons.computer;
    return Icons.notifications;
  }

  Color _colorForTitle(String title) {
    if (title.toLowerCase().contains('online')) return Colors.green;
    if (title.toLowerCase().contains('offline')) return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: InkWell(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.all(5.0),
            child: Icon(Icons.arrow_back_ios),
          ),
        ),
        elevation: 0.5,
        actions: [
          Obx(() => controller.notifications.isNotEmpty
              ? TextButton(
                  onPressed: controller.clearAll,
                  child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        final list = controller.notifications;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No notifications',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  'Windows App status updates appear here',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final n = list[index];
              final title = n['title'] as String? ?? '';
              final body = n['body'] as String? ?? '';
              final receivedAt = n['received_at'] as int? ?? 0;
              final color = _colorForTitle(title);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(30),
                    child: Icon(_iconForTitle(title), color: color, size: 20),
                  ),
                  title: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(body,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 5),
                      Text(
                        _timeAgo(receivedAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
