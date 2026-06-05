import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/device_status_response_model.dart';
import '../../models/get_notification_windows_history.dart';
import '../../models/get_specific_store_device_status_response_model.dart';
import '../../models/windows_device_status.dart';
import '../Notification/notification.dart';

class DeviceStatusScreen extends StatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen> with TickerProviderStateMixin {
  bool isLoading = false;
  List<DeviceStatus>? allDevices = [];
  List<DeviceStatus>? aliveDevices = [];
  List<DeviceStatus>? staleDevices = [];
  List<DeviceStatus>? filteredDevices = [];
  StatusSummary? summary;

  String selectedTab = 'total';
  String storeId = '';
  GetSpecificStoreDeviceStatus? specificStoreDevice;
  late SharedPreferences sharedPreferences;

  WindowsDeviceStatus? windowsStatus;
  String selectedWindowsTab = 'total';

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late TabController _tabController;
  GetWindowsNotificationHistory? windowsHistory;
  String selectedHistoryTab = 'all';
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () async {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences.getString(valueShared_STORE_KEY) ?? '';

      // Superadmin (role_id == 1) should always use the all-devices path,
      // even if a store_id was saved when they visited a store's screen.
      final int roleId = sharedPreferences.getInt(valueShared_ROLE_ID) ?? 0;
      if (roleId == 1) storeId = '';

      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }
      Get.put(NotificationController(storeId: storeId.isEmpty ? null : storeId));

      if (storeId.isNotEmpty) {
        getSpecificStoreDeviceStatus();
      } else {
        getAllDeviceStatus();
        _fetchWindowsDeviceStatus();
        getWindowsHistory(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rippleController.dispose();
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFCFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      child: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'device_status'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      if (_tabController.index == 2) {
                        if (Get.isRegistered<NotificationController>()) {
                          Get.find<NotificationController>().load();
                        }
                      } else if (_tabController.index == 0) {
                        _fetchWindowsDeviceStatus();
                      } else {
                        if (storeId.isNotEmpty) {
                          getSpecificStoreDeviceStatus();
                        } else {
                          getAllDeviceStatus();
                        }
                      }
                      if (_tabController.index == 3) {
                        getWindowsHistory();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.refresh, size: 24, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Bar — 3 tabs
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'Mulish',
              ),
              tabs: const [
                Tab(text: 'Windows'),
                Tab(text: 'Devices'),
                Tab(text: 'Notifications'),
                Tab(text: 'History'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWindowsTab(),
                  _buildDevicesTab(),
                  _buildNotificationsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Windows Tab ─────────────────────────────────────────────────────────────

  Widget _buildWindowsTab() {
    final onlineList = windowsStatus?.online ?? [];
    final offlineList = windowsStatus?.offline ?? [];

    List<Map<String, dynamic>> displayList = [];
    if (selectedWindowsTab == 'total') {
      displayList = [
        ...onlineList.map((s) => {
              'storeId': s.storeId,
              'storeName': s.storeName,
              'since': s.since,
              'isOnline': true,
            }),
        ...offlineList.map((s) => {
              'storeId': s.storeId,
              'storeName': s.storeName,
              'since': s.since,
              'isOnline': false,
            }),
      ];
    } else if (selectedWindowsTab == 'online') {
      displayList = onlineList
          .map((s) => {
                'storeId': s.storeId,
                'storeName': s.storeName,
                'since': s.since,
                'isOnline': true,
              })
          .toList();
    } else {
      displayList = offlineList
          .map((s) => {
                'storeId': s.storeId,
                'storeName': s.storeName,
                'since': s.since,
                'isOnline': false,
              })
          .toList();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 15, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                _windowsSummaryCard(
                  'total',
                  '${windowsStatus?.summary?.total ?? 0}',
                  'Total',
                  const Color(0xffE0D2AA),
                  const Color(0xffFAF3E0),
                ),
                const SizedBox(width: 10),
                _windowsSummaryCard(
                  'online',
                  '${windowsStatus?.summary?.online ?? 0}',
                  'Online',
                  const Color(0xff029543),
                  const Color(0xffEBFAF2),
                ),
                const SizedBox(width: 10),
                _windowsSummaryCard(
                  'offline',
                  '${windowsStatus?.summary?.offline ?? 0}',
                  'Offline',
                  const Color(0xffED4C5C),
                  const Color(0xffFFF5F5),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              selectedWindowsTab == 'total'
                  ? 'All Windows Stores'
                  : selectedWindowsTab == 'online'
                      ? 'Online Stores'
                      : 'Offline Stores',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                fontFamily: 'Mulish',
              ),
            ),

            const SizedBox(height: 10),

            if (windowsStatus == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (displayList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.computer, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No Windows stores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayList.map(
                (item) => _buildWindowsStoreCard(
                  item['storeId'] as int?,
                  item['storeName'] as String?,
                  item['since'] as String?,
                  item['isOnline'] as bool,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _windowsSummaryCard(
    String tab,
    String count,
    String label,
    Color borderColor,
    Color bgColor,
  ) {
    final isSelected = selectedWindowsTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedWindowsTab = tab),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? borderColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: bgColor,
          ),
          child: Column(
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsStoreCard(
    int? wStoreId,
    String? wStoreName,
    String? since,
    bool isOnline,
  ) {
    final dotColor = isOnline ? const Color(0xff029543) : Colors.grey.shade400;
    final sinceFormatted = (since != null && since.isNotEmpty) ? _formatSinceWithDate(since) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wStoreName ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Mulish',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${wStoreId ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Mulish',
                  ),
                ),
                if (sinceFormatted != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sinceFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xffEBFAF2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline ? const Color(0xff029543) : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns "2h ago  25 May 2026 10:28"
  String _formatSinceWithDate(String since) {
    try {
      final dt = DateTime.parse(since).toLocal();
      final diff = DateTime.now().difference(dt);

      String relative;
      if (diff.inMinutes < 1) {
        relative = 'Just now';
      } else if (diff.inMinutes < 60) {
        relative = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        relative = '${diff.inHours}h ago';
      } else {
        relative = '${diff.inDays}d ago';
      }

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      return '$relative   $dateStr $timeStr';
    } catch (_) {
      return '';
    }
  }

  // ─── Devices Tab ─────────────────────────────────────────────────────────────

  Widget _buildDevicesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (storeId.isEmpty) ...[
                  Row(
                    children: [
                      _summaryCard(
                          'total',
                          '${summary?.total ?? 0}',
                          'total'.tr,
                          const Color(0xffE0D2AA),
                          const Color(0xffFAF3E0)),
                      const SizedBox(width: 10),
                      _summaryCard(
                          'alive',
                          '${summary?.alive ?? 0}',
                          'alive'.tr,
                          const Color(0xff029543),
                          const Color(0xffEBFAF2)),
                      const SizedBox(width: 10),
                      _summaryCard(
                          'stale',
                          '${summary?.stale ?? 0}',
                          'stale'.tr,
                          const Color(0xff624BA1),
                          const Color(0xffFDFCFF)),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
                Text(
                  selectedTab == 'total'
                      ? 'all_device'.tr
                      : selectedTab == 'alive'
                          ? 'alive'.tr
                          : 'stale',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'Mulish',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (filteredDevices == null || filteredDevices!.isEmpty)
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_other, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'no_device'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredDevices?.length ?? 0,
              itemBuilder: (context, index) {
                final device = filteredDevices![index];
                return _buildDeviceCard(device);
              },
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String tab, String count, String label, Color borderColor, Color bgColor) {
    final isSelected = selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = tab;
          filteredDevices = tab == 'total'
              ? allDevices
              : tab == 'alive'
                  ? aliveDevices
                  : staleDevices;
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          color: bgColor,
        ),
        child: Column(
          children: [
            Text(count,
                style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ─── Notifications Tab ────────────────────────────────────────────────────────

  Widget _buildNotificationsTab() {
    if (!Get.isRegistered<NotificationController>()) {
      return const Center(child: CircularProgressIndicator());
    }
    final controller = Get.find<NotificationController>();

    return Obx(() {
      final list = controller.notifications.where((n) {
        final t = (n['title'] as String? ?? '').toLowerCase();
        return t.contains('online') || t.contains('offline');
      }).toList();

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

      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.clearAll,
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final n = list[index];
                  final title = n['title'] as String? ?? '';
                  final body = n['body'] as String? ?? '';
                  final receivedAt = n['received_at'] as int? ?? 0;
                  final isOnline = title.toLowerCase().contains('online');
                  final color = isOnline ? Colors.green : Colors.red;

                  return Container(
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
                        child: Icon(Icons.computer, color: color, size: 20),
                      ),
                      title: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'Mulish')),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(body,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 5),
                          Text(
                            _formatTime(receivedAt),
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
            ),
          ),
        ],
      );
    });
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final time = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return time;
    }
    return '${dt.day} ${months[dt.month - 1]}  $time';
  }

  // ─── History Tab ──────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (windowsHistory == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    List<Map<String, dynamic>> historyItems = [];

    for (final store in windowsHistory!.stores ?? []) {
      for (final event in store.events ?? []) {
        historyItems.add({
          'storeName': store.storeName,
          'status': event.state,
          'occurredAt': event.occurredAt,
        });
      }
    }

    if (historyItems.isEmpty) {
      return const Center(
        child: Text('No History Found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        final item = historyItems[index];

        final bool isOnline =
            (item['status'] ?? '').toString().toLowerCase() == 'online';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                isOnline ? Colors.green.shade50 : Colors.red.shade50,
                child: Icon(
                  isOnline ? Icons.check_circle : Icons.cancel,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['storeName'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Mulish',
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item['status'] ?? '',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatHistoryDate(item['occurredAt']),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatHistoryDate(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final dt = DateTime.parse(value).toLocal();

      return DateFormat(
        'dd MMM yyyy • hh:mm a',
      ).format(dt);
    } catch (e) {
      return value;
    }
  }
  // ─── Device Card ──────────────────────────────────────────────────────────────

  Widget _buildDeviceCard(DeviceStatus device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('store_id'.tr, '${device.storeId ?? 'N/A'}'),
          const SizedBox(height: 4),
          _infoRow('store_n'.tr, device.storeName ?? 'N/A'),
          const SizedBox(height: 4),
          _infoRow('user'.tr, device.username ?? 'N/A'),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('last_heart'.tr,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Colors.black87)),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Text(device.lastHeartbeat ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Mulish',
                        color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _infoRow('tim'.tr, '${device.secondsSinceHeartbeat ?? 0} sec'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusIndicator(
                  'is_alive'.tr,
                  device.isAlive == true ? const Color(0xff23C53D) : Colors.grey,
                  device.isAlive == true),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                  'connect'.tr,
                  device.isConnected == true ? const Color(0xff23C53D) : Colors.grey,
                  device.isConnected == true),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                  'web'.tr,
                  device.websocketConnected == true
                      ? const Color(0xffED4C5C)
                      : Colors.grey,
                  device.websocketConnected == true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                color: Colors.black87)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Mulish',
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, Color color, bool shouldAnimate) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: shouldAnimate
              ? AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24 * _rippleAnimation.value,
                          height: 24 * _rippleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color
                                .withOpacity((1 - _rippleAnimation.value) * 0.4),
                          ),
                        ),
                        Container(
                          width: 18 * _rippleAnimation.value,
                          height: 18 * _rippleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color
                                .withOpacity((1 - _rippleAnimation.value) * 0.6),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ],
                    );
                  },
                )
              : Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Mulish')),
      ],
    );
  }

  // ─── API Calls ────────────────────────────────────────────────────────────────

  Future<void> _fetchWindowsDeviceStatus() async {
    try {
      final status = await CallService().getWindowsDeviceStatus();
      if (mounted) setState(() => windowsStatus = status);
    } catch (e) {
      print('Error getting Windows device status: $e');
    }
  }

  Future<void> getAllDeviceStatus() async {
    setState(() => isLoading = true);

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            child: Lottie.asset('assets/animations/burger.json',
                width: 150, height: 150, repeat: true),
          ),
          barrierDismissible: false,
        );
      });

      DeviceStatusResponseModel status = await CallService().getDeviceStatus();

      setState(() {
        allDevices = [...(status.alive ?? []), ...(status.stale ?? [])];
        aliveDevices = status.alive ?? [];
        staleDevices = status.stale ?? [];
        summary = status.summary;
        filteredDevices = allDevices;
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) Get.back();
    } catch (e) {
      print('Error getting device status: $e');
      setState(() => isLoading = false);
      if (Get.isDialogOpen ?? false) Get.back();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('failed_dev'.tr), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  Future<void> getSpecificStoreDeviceStatus() async {
    setState(() => isLoading = true);

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            child: Lottie.asset('assets/animations/burger.json',
                width: 150, height: 150, repeat: true),
          ),
          barrierDismissible: false,
        );
      });

      GetSpecificStoreDeviceStatus status =
          await CallService().getDeviceStatusSpecificStore(storeId);

      setState(() {
        specificStoreDevice = status;
        final device = DeviceStatus(
          storeId: status.storeId,
          storeName: status.storeName,
          username: status.username,
          lastHeartbeat: status.lastHeartbeat,
          secondsSinceHeartbeat: status.secondsSinceHeartbeat,
          isAlive: status.isAlive,
          isConnected: status.isConnected,
          websocketConnected: status.websocketConnected,
        );
        aliveDevices = [device];
        filteredDevices = [device];
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) Get.back();
    } catch (e) {
      print('Error getting Specific Store device status: $e');
      setState(() => isLoading = false);
      if (Get.isDialogOpen ?? false) Get.back();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('failed_dev'.tr), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  Future<void> getWindowsHistory({bool showLoader = true}) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
        Get.dialog(
          Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      }
      GetWindowsNotificationHistory history = await CallService().getWindowsNotificationHistory();

      setState(() {
        windowsHistory = history;
        isLoading = false;
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    } catch (e) {
      print('Error getting WindowsHistory: $e');
      setState(() {
        isLoading = false;
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    }
  }

}
