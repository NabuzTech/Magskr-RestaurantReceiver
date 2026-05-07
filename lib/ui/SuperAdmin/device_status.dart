import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/device_status_response_model.dart';
import '../../models/get_specific_store_device_status_response_model.dart';

class DeviceStatusScreen extends StatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<DeviceStatus>? allDevices = [];
  List<DeviceStatus>? aliveDevices = [];
  List<DeviceStatus>? staleDevices = [];
  List<DeviceStatus>? filteredDevices = [];
  StatusSummary? summary;

  // For tab selection
  String selectedTab = 'total'; // total, alive, stale
  String storeId='';
  GetSpecificStoreDeviceStatus? specificStoreDevice;
  late SharedPreferences sharedPreferences;
  // For blinking animation
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  String store='',storeName='',userName='',lastBeat='',time='';
  bool isAlive=false;
  bool isConnected=false;
  bool websocket=false;
  @override
  void initState() {
    super.initState();
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

      if (storeId.isNotEmpty) {
        getSpecificStoreDeviceStatus();
      } else {
        getAllDeviceStatus();
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                          ),
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
                          if (storeId.isNotEmpty) {
                            getSpecificStoreDeviceStatus();
                          } else {
                            getAllDeviceStatus();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            size: 24,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Summary Cards (Tappable Tabs)
                  if (storeId.isEmpty) ...[
                  Row(
                    children: [
                      // Total Card
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = 'total';
                            filteredDevices = allDevices;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedTab == 'total'
                                  ? const Color(0xffE0D2AA)
                                  : Colors.grey.shade300,
                              width: selectedTab == 'total' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xffFAF3E0),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  '${summary?.total ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                 Text(
                                   'total'.tr,
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
                      ),
                      const SizedBox(width: 10),

                      // Alive Card
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = 'alive';
                            filteredDevices = aliveDevices;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedTab == 'alive'
                                  ? const Color(0xff029543)
                                  : Colors.grey.shade300,
                              width: selectedTab == 'alive' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xffEBFAF2),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  '${summary?.alive ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                 Text(
                                  'alive'.tr,
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
                      ),
                      const SizedBox(width: 10),

                      // Stale Card
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = 'stale';
                            filteredDevices = staleDevices;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedTab == 'stale'
                                  ? const Color(0xff624BA1)
                                  : Colors.grey.shade300,
                              width: selectedTab == 'stale' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xffFDFCFF),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  '${summary?.stale ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                 Text(
                                  'stale'.tr,
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
          ],
                  // Section Title
                  Text(
                    selectedTab == 'total'
                        ? 'all_device'.tr
                        : selectedTab == 'alive'
                        ? 'alive'.tr
                        : 'stale',
                    style:  const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Device List (Scrollable)
            Expanded(
              child: filteredDevices == null || filteredDevices!.isEmpty
                  ? Center(
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
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredDevices?.length ?? 0,
                itemBuilder: (context, index) {
                  final device = filteredDevices![index];
                  return _buildDeviceCard(device);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          // Store ID and Name
          Row(
            children: [
              Text(
                'store_id'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                ),),
              Text(
                '${device.storeId ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'store_n'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                ),
              ),
              Text(
                device.storeName ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'user'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: Colors.black87,
                ),
              ),
              Text(
                device.username ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mulish',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'last_heart'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: Colors.black87,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: Text(
                  device.lastHeartbeat ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Mulish',
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                  'tim'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: Colors.black87,
                ),
              ),
              Text(
                '${device.secondsSinceHeartbeat ?? 0} sec',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mulish',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Indicators
          Row(
            children: [
              // Is Alive Indicator with ripple
              _buildStatusIndicator('is_alive'.tr,
                device.isAlive == true ? const Color(0xff23C53D) : Colors.grey,
                device.isAlive == true, // shouldAnimate
              ),
              const SizedBox(width: 12),

              // Is Connected Indicator with ripple
              _buildStatusIndicator(
                'connect'.tr,
                device.isConnected == true ? const Color(0xff23C53D) : Colors.grey,
                device.isConnected == true, // shouldAnimate
              ),
              const SizedBox(width: 12),

              // Websocket Indicator with ripple
              _buildStatusIndicator(
                'web'.tr,
                device.websocketConnected == true ? const Color(0xffED4C5C) : Colors.grey,
                device.websocketConnected == true, // shouldAnimate
              ),
            ],
          ),
        ],
      ),
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
                  // Outer ripple circle
                  Container(
                    width: 24 * _rippleAnimation.value,
                    height: 24 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(
                        (1 - _rippleAnimation.value) * 0.4,
                      ),
                    ),
                  ),
                  // Middle ripple circle
                  Container(
                    width: 18 * _rippleAnimation.value,
                    height: 18 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(
                        (1 - _rippleAnimation.value) * 0.6,
                      ),
                    ),
                  ),
                  // Center dot (static)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          )
              : Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Mulish',
          ),
        ),
      ],
    );
  }

  Future<void> getAllDeviceStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Use addPostFrameCallback to show dialog after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
          barrierDismissible: false,
        );
      });

      DeviceStatusResponseModel status = await CallService().getDeviceStatus();

      setState(() {
        allDevices = [
          ...(status.alive ?? []),
          ...(status.stale ?? []),
        ];

        aliveDevices = status.alive ?? [];
        staleDevices = status.stale ?? [];
        summary = status.summary;

        filteredDevices = allDevices;

        print('Total devices: ${allDevices?.length}');
        print('Alive devices: ${aliveDevices?.length}');
        print('Stale devices: ${staleDevices?.length}');
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error getting device status: $e');
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show error after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('failed_dev'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> getSpecificStoreDeviceStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Use addPostFrameCallback to show dialog after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
          barrierDismissible: false,
        );
      });

      GetSpecificStoreDeviceStatus status = await CallService().getDeviceStatusSpecificStore(storeId);

      setState(() {
        specificStoreDevice = status;

        // Convert specific store device to DeviceStatus format for list display
        DeviceStatus device = DeviceStatus(
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

        print('Specific store device loaded: ${status.storeName}');
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error getting Specific Store  device status: $e');
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show error after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('failed_dev'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
}