import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/Store.dart';
import '../../models/get_printer_ip_response_model.dart';
import '../../models/manual_override_response_model.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  late PageController _pageController;
  final TextEditingController _newIpController = TextEditingController();
  final FocusNode _ipFocusNode = FocusNode();
  final TextEditingController _syncTimeController = TextEditingController();
  final FocusNode _syncTimeFocusNode = FocusNode();
  bool isLoading = false;
  bool _autoRemoteOrderrAccept = false;
  bool _autotableBook = false;
  bool deliveryAvailable = false;
  bool pickupEnabled = false;
  bool reservationEnabled = false;
  List<IpAddressItem> _ipAddresses = [];
  late SharedPreferences sharedPreferences;
  List<GetPrinterIpResponseModel> ip = [];
  String? storeId;
  bool isManualOverride = false;
  bool isManualStatus = false;
  bool _isManualOverride = false;
  bool _isManualStart = true;
  bool _manualSettingsInitialized = false;
  bool _autoAcceptUserModified = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addObserver(this);
    _initSharedPrefs();
    _loadStoreData();
  }

  void _openTab(int index) {
    if (_pageController.hasClients && _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> _initSharedPrefs() async {
    sharedPreferences = await SharedPreferences.getInstance();
    await getPrinterIp();
    await _loadSettings();
    await _loadManualSettings();
    String? savedSyncTime = sharedPreferences.getString('sync_time');
    if (savedSyncTime != null && savedSyncTime.isNotEmpty) {
      int? syncTimeSeconds = int.tryParse(savedSyncTime);
      if (syncTimeSeconds != null) {
        int syncTimeMinutes = (syncTimeSeconds / 60).round();
        _syncTimeController.text = syncTimeMinutes.toString();
        print('✅ Loaded sync time: $syncTimeMinutes minutes ($syncTimeSeconds seconds)');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print("📱 App resumed on Printer Settings, refreshing...");
      _refreshData();
    }
  }

  Future<void> _loadStoreData() async {
    String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    if (bearerKey != null && bearerKey.isNotEmpty) await getStoredta(bearerKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      print("🔄 Printer Settings became visible, refreshing...");
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    print("🔄 Refreshing printer settings data...");
    await getPrinterIp(showLoader: false);
    _loadSettings();
    _loadStoreData();
  }

  Future<void> _loadSettings() async {
    setState(() {
      if (ip.isNotEmpty) {
        _ipAddresses = ip.map((item) => IpAddressItem(
          ip: item.ipAddress ?? '',
          isActive: item.isActive ?? false,
        )).toList();
      }
    });
    String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    if (bearerKey != null && bearerKey.isNotEmpty) await getStoreSetting(bearerKey);
  }

  Future<void> _loadManualSettings() async {
    setState(() {
      _isManualOverride = sharedPreferences.getBool('manual_override') ?? false;
      _isManualStart = sharedPreferences.getBool('manual_start') ?? false;
    });
  }

  Future<void> manualStatus() async {
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      print('Store ID not found');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Store ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ));
      }
      return;
    }
    try {
      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );
      var map = {
        "is_manual_override": _isManualOverride,
        "manual_status": _isManualStart ? "open" : "close"
      };
      print("Manual Override Map: $map");
      print("Store ID: $storeId");
      ManualOverrideResponseModel model = await CallService().addManualOverride(map, storeId!);
      print("API Response: ${model.message}");
      if (Get.isDialogOpen == true) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Manual override updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1500),
        ));
      }
    } catch (e) {
      print('❌ Error updating manual override: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (Get.isDialogOpen == true) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> _saveManualSettings() async {
    await sharedPreferences.setBool('manual_override', _isManualOverride);
    await sharedPreferences.setBool('manual_start', _isManualStart);
    await manualStatus();
  }

  Future<void> _saveSettings() async {
    await sharedPreferences.setBool('auto_accept', _autoRemoteOrderrAccept);
    await sharedPreferences.setStringList('ip_addresses', _ipAddresses.map((e) => e.ip).toList());
    await sharedPreferences.setStringList('ip_statuses', _ipAddresses.map((e) => e.isActive.toString()).toList());
  }

  void _toggleIpStatus(int index) {
    setState(() => _ipAddresses[index].isActive = !_ipAddresses[index].isActive);
    _saveSettings();
  }

  void _editIpAddress(int index) {
    TextEditingController editController = TextEditingController(text: _ipAddresses[index].ip);
    Get.dialog(AlertDialog(
      title: const Text('Edit IP Address'),
      content: TextField(
        controller: editController,
        decoration: const InputDecoration(
          labelText: 'IP Address',
          hintText: 'e.g. 192.168.1.100',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            String newIp = editController.text.trim();
            String? validation = _validateIP(newIp);
            if (validation != null) {
              Get.snackbar('Invalid IP', validation, backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            Get.back();
            if (ip.isNotEmpty && index < ip.length) {
              await editPrinterIp(ip[index].id.toString(), newIp);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Unable to edit. Please refresh and try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[300], foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    ));
  }

  String? _validateIP(String ip) {
    if (ip.isEmpty) return 'IP address cannot be empty';
    final parts = ip.split('.');
    if (parts.length != 4) return 'IP must have 4 parts separated by dots';
    for (String part in parts) {
      if (part.isEmpty) return 'IP parts cannot be empty';
      int? num = int.tryParse(part);
      if (num == null) return 'Each part must be a number';
      if (num < 0 || num > 255) return 'Each part must be between 0-255';
    }
    return null;
  }

  @override
  void dispose() {
    _newIpController.dispose();
    _ipFocusNode.dispose();
    _syncTimeController.dispose();
    _syncTimeFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveSyncTime() async {
    String syncTime = _syncTimeController.text.trim();
    if (syncTime.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('please_enter_sync'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1500),
        ));
      }
      return;
    }
    int? syncTimeMinutes = int.tryParse(syncTime);
    if (syncTimeMinutes == null || syncTimeMinutes < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync time must be at least 1 minute'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ));
      }
      return;
    }
    try {
      int syncTimeSeconds = syncTimeMinutes * 60;
      await sharedPreferences.setString('sync_time', syncTimeSeconds.toString());
      if (mounted) {
        _syncTimeFocusNode.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'sync_time_saved'.tr}: $syncTimeMinutes minutes'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      print('Error saving sync time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('failed_save_sync'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1500),
        ));
      }
    }
  }

  Widget _buildSectionContainer({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
    ),
    child: child,
  );

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLeft = false,
    bool isRight = false,
  })
  {
    BorderRadius? borderRadius;
    if (isLeft) borderRadius = const BorderRadius.horizontal(left: Radius.circular(2));
    if (isRight) borderRadius = const BorderRadius.horizontal(right: Radius.circular(2));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () => _ipFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: CustomDrawer(onSelectTab: _openTab),
        appBar: const CustomAppBar(),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                // Manual Override Section
                _buildSectionContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('is_manual'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _isManualOverride ? Colors.green : Colors.yellow[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                _buildToggleButton(
                                  label: 'yes'.tr,
                                  isSelected: _isManualOverride,
                                  onTap: () {
                                    setState(() => _isManualOverride = true);
                                    sharedPreferences.setBool('manual_override', _isManualOverride);
                                    _saveManualSettings();
                                  },
                                ),
                                _buildToggleButton(
                                  label: 'no_'.tr,
                                  isSelected: !_isManualOverride,
                                  onTap: () {
                                    setState(() => _isManualOverride = false);
                                    _saveManualSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isManualOverride) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                             Expanded(
                              child: Text('manual'.tr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _isManualStart ? Colors.green : Colors.yellow[700],
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _isManualStart = true);
                                      _saveManualSettings();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _isManualStart ? Colors.white : Colors.yellow[700],
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                                      ),
                                      child: Text('open'.tr,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _isManualStart ? Colors.black : Colors.white)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _isManualStart = false);
                                      _saveManualSettings();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: !_isManualStart ? Colors.white : Colors.green,
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                                      ),
                                      child: Text('close'.tr,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _isManualStart ? Colors.white : Colors.black)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Auto Accept Toggle
                _buildSectionContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('auto_order'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                      ),
                      Switch(
                        value: _autoRemoteOrderrAccept,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          setState(() {
                            _autoRemoteOrderrAccept = val;
                            _autoAcceptUserModified = true;
                          });
                          await poststoreSetting(val, showDialog: true);
                        },
                      ),
                    ],
                  ),
                ),

                // Auto Reservation Toggle
                _buildSectionContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('auto_Reserv'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                      ),
                      Switch(
                        value: _autotableBook,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          setState(() => _autotableBook = val);
                          await poststoreSetting(_autoRemoteOrderrAccept, showDialog: true, autoTableBookValue: val);
                        },
                      ),
                    ],
                  ),
                ),


                // Delivery Available Toggle
                _buildSectionContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('delivery_avail'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                      ),
                      Switch(
                        value: deliveryAvailable,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          setState(() => deliveryAvailable = val);
                          await poststoreSetting(_autoRemoteOrderrAccept, showDialog: true, deliveryAvailableValue: val);
                        },
                      ),
                    ],
                  ),
                ),

                // Pickup Enabled Toggle
                _buildSectionContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('pickup_enabled'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                      ),
                      Switch(
                        value: pickupEnabled,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          setState(() => pickupEnabled = val);
                          await poststoreSetting(_autoRemoteOrderrAccept, showDialog: true, pickupEnabledValue: val);
                        },
                      ),
                    ],
                  ),
                ),

                // Reservation Enabled Toggle
                _buildSectionContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('reservation_enabled'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                      ),
                      Switch(
                        value: reservationEnabled,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          setState(() => reservationEnabled = val);
                          await poststoreSetting(_autoRemoteOrderrAccept, showDialog: true, reservationEnabledValue: val);
                        },
                      ),
                    ],
                  ),
                ),

                // // Sync Time
                // _buildSectionContainer(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text('sync_time'.tr,
                //           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                //       const SizedBox(height: 8),
                //       Row(
                //         children: [
                //           Expanded(
                //             child: TextFormField(
                //               controller: _syncTimeController,
                //               focusNode: _syncTimeFocusNode,
                //               keyboardType: TextInputType.number,
                //               decoration: InputDecoration(
                //                 hintText: 'e.g. 30',
                //                 suffixText: 'minutes'.tr,
                //                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                //                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                //               ),
                //               onFieldSubmitted: (value) => _saveSyncTime(),
                //             ),
                //           ),
                //           const SizedBox(width: 8),
                //           ElevatedButton(
                //             onPressed: _saveSyncTime,
                //             style: ElevatedButton.styleFrom(
                //               backgroundColor: Colors.green[300],
                //               foregroundColor: Colors.black,
                //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //             ),
                //             child: Text('saved'.tr,
                //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                //
                // // IP List Header
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //   decoration: BoxDecoration(
                //     color: Colors.grey[100],
                //     border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                //   ),
                //   child: Row(
                //     children: [
                //       Expanded(flex: 4,
                //           child: Text('ip'.tr,
                //               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87))),
                //       Expanded(flex: 2,
                //           child: Text('status'.tr,
                //               textAlign: TextAlign.center,
                //               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87))),
                //       Expanded(flex: 3,
                //           child: Text('action'.tr,
                //               textAlign: TextAlign.center,
                //               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87))),
                //     ],
                //   ),
                // ),
                //
                // // IP Address List
                // SizedBox(
                //   height: 300,
                //   child: _ipAddresses.isEmpty
                //       ? Center(
                //     child: Column(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Icon(Icons.list_alt, size: 64, color: Colors.grey[300]),
                //         const SizedBox(height: 16),
                //         Text('no_ip'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                //       ],
                //     ),
                //   )
                //       : ListView.builder(
                //     itemCount: _ipAddresses.length,
                //     itemBuilder: (context, index) => Container(
                //       decoration: BoxDecoration(
                //           border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5))),
                //       child: Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //         child: Row(
                //           children: [
                //             Expanded(flex: 4,
                //                 child: Text(_ipAddresses[index].ip,
                //                     style: const TextStyle(fontSize: 14, color: Colors.black87))),
                //             Expanded(
                //               flex: 2,
                //               child: Center(
                //                 child: GestureDetector(
                //                   onTap: () => _toggleIpStatus(index),
                //                   child: Container(
                //                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                //                     decoration: BoxDecoration(
                //                       color: _ipAddresses[index].isActive ? Colors.green[100] : Colors.grey[200],
                //                       borderRadius: BorderRadius.circular(12),
                //                     ),
                //                     child: Text(
                //                       _ipAddresses[index].isActive ? 'active'.tr : 'inactive'.tr,
                //                       style: TextStyle(
                //                         fontSize: 12,
                //                         color: _ipAddresses[index].isActive ? Colors.green[800] : Colors.grey[700],
                //                         fontWeight: FontWeight.w500,
                //                       ),
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //             Expanded(
                //               flex: 3,
                //               child: Row(
                //                 mainAxisAlignment: MainAxisAlignment.center,
                //                 children: [
                //                   IconButton(
                //                     icon: const Icon(Icons.edit, size: 20),
                //                     color: Colors.blue,
                //                     onPressed: () => _editIpAddress(index),
                //                     padding: const EdgeInsets.all(4),
                //                     constraints: const BoxConstraints(),
                //                   ),
                //                   const SizedBox(width: 8),
                //                   IconButton(
                //                     icon: const Icon(Icons.delete, size: 20),
                //                     color: Colors.red,
                //                     onPressed: () {
                //                       if (ip.isNotEmpty && index < ip.length) {
                //                         showDeleteDialog(context, _ipAddresses[index].ip, ip[index].id.toString());
                //                       } else {
                //                         if (mounted) {
                //                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //                             content: Text('unable_to'.tr),
                //                             backgroundColor: Colors.red,
                //                             duration: const Duration(seconds: 2),
                //                           ));
                //                         }
                //                       }
                //                     },
                //                     padding: const EdgeInsets.all(4),
                //                     constraints: const BoxConstraints(),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                //
                // // Add New IP Section
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
                //     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.stretch,
                //     children: [
                //       Text('enter_new'.tr,
                //           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                //       const SizedBox(height: 12),
                //       TextFormField(
                //         controller: _newIpController,
                //         focusNode: _ipFocusNode,
                //         decoration: InputDecoration(
                //           hintText: 'e.g. 192.168.1.100',
                //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                //           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //         ),
                //         keyboardType: TextInputType.text,
                //       ),
                //       const SizedBox(height: 12),
                //       ElevatedButton(
                //         onPressed: () async {
                //           String newIp = _newIpController.text.trim();
                //           if (newIp.isEmpty) {
                //             if (mounted) {
                //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //                 content: Text('please_enter_ip'.tr),
                //                 backgroundColor: Colors.red,
                //                 duration: const Duration(milliseconds: 100),
                //               ));
                //             }
                //             return;
                //           }
                //           String? validation = _validateIP(newIp);
                //           if (validation != null) {
                //             if (mounted) {
                //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //                 content: Text(validation),
                //                 backgroundColor: Colors.red,
                //                 duration: const Duration(milliseconds: 100),
                //               ));
                //             }
                //             return;
                //           }
                //           bool success = await addNewIp();
                //           if (success) {
                //             _newIpController.clear();
                //             _ipFocusNode.unfocus();
                //           }
                //         },
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.green[300],
                //           foregroundColor: Colors.black,
                //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                //           padding: const EdgeInsets.symmetric(vertical: 14),
                //         ),
                //         child: Text('saved'.tr,
                //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingDialog() => Center(
      child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true));

  Future<void> getPrinterIp({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => isLoading = true);
      Get.dialog(_loadingDialog(), barrierDismissible: false);
    }
    try {
      final result = await Future.any([
        CallService().getIpAddress(),
        Future.delayed(const Duration(seconds: 6)).then((_) => <GetPrinterIpResponseModel>[])
      ]);
      if (showLoader && Get.isDialogOpen == true) Get.back();
      if (mounted) setState(() { ip = result; isLoading = false; });
    } catch (e) {
      if (showLoader && Get.isDialogOpen == true) Get.back();
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> addNewIp() async {
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('storeId'.tr), backgroundColor: Colors.red));
      }
      return false;
    }
    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Get.dialog(_loadingDialog(), barrierDismissible: false);
    try {
      var map = {
        "name": "",
        "ip_address": _newIpController.text.trim(),
        "store_id": storeId,
        "isActive": true,
        "type": 0,
        "category_id": 0,
        "isRemote": true
      };
      final result = await Future.any([
        CallService().addNewIp(map),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (result != null) {
        await getPrinterIp(showLoader: false);
        _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ip_added'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 100),
          ));
        }
        return true;
      } else {
        throw Exception('timeout_null'.tr);
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'failed_ip'.tr}: $e'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 100),
        ));
      }
      return false;
    }
  }

  Future<void> poststoreSetting(bool autoAcceptValue, {bool showDialog = true,
    bool? autoTableBookValue, bool? deliveryAvailableValue, bool? pickupEnabledValue,
    bool? reservationEnabledValue}) async
  {
    if (!mounted) return;
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    Map<String, dynamic> jsonData = {
      "auto_accept_orders_remote": autoAcceptValue,
      "auto_print_orders_remote": false,
      "auto_accept_orders_local": false,
      "auto_print_orders_local": false,
      "auto_accept_reservations": autoTableBookValue ?? _autotableBook,
      "lieferung_enabled": deliveryAvailableValue ?? deliveryAvailable,
      "abholung_enabled": pickupEnabledValue ?? pickupEnabled,
      "tisch_reservierung_enabled": reservationEnabledValue ?? reservationEnabled,
      "store_id": storeID
    };
    try {
      if (showDialog) {
        if (Get.isDialogOpen == true) {
          Get.back();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        Get.dialog(_loadingDialog(), barrierDismissible: false);
      }
      String? bearerToken = sharedPreferences.getString(valueShared_BEARER_KEY);
      if (bearerToken == null || bearerToken.isEmpty) {
        if (showDialog && Get.isDialogOpen == true) {
          Get.back();
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('auth'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 100),
          ));
        }
        return;
      }
      final result = await Future.any([
        ApiRepo().storeSettingPost(bearerToken, jsonData,storeID!),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (result != null && mounted) {
        await sharedPreferences.setBool('auto_order_remote_accept', autoAcceptValue);
        _autoAcceptUserModified = false;
        if (showDialog && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('setting_update'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 100),
          ));
        }
      } else {
        if (showDialog && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('request'.tr),
            backgroundColor: Colors.orange,
            duration: const Duration(milliseconds: 100),
          ));
        }
      }
    } catch (e) {
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      print("Error: $e");
      if (showDialog && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'failed_update'.tr}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 100),
        ));
      }
    }
  }

  Future<void> deletePrinterIp(String printerId) async {
    Get.dialog(_loadingDialog(), barrierDismissible: false);
    try {
      await CallService().deleteExistingIp(printerId);
      Get.back();
      await getPrinterIp(showLoader: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ip_delete'.tr),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      Get.back();
      print('${'error_delete'.tr}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('failed_delete_ip'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void showDeleteDialog(BuildContext context, String ip, String printerId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '${'are'.tr} "$ip"  ?',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'Mulish'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dialogButton(
                        label: 'cancel'.tr,
                        color: const Color(0xFF8E9AAF),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 15),
                      _dialogButton(
                        label: 'delete'.tr,
                        color: const Color(0xFFE25454),
                        onPressed: () {
                          Get.back();
                          deletePrinterIp(printerId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFED4C5C), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton({required String label, required Color color, required VoidCallback onPressed}) =>
      Container(
        height: 35,
        width: 70,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      );

  Future<bool> editPrinterIp(String printerId, String newIpAddress) async {
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('storeId'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 100),
        ));
      }
      return false;
    }
    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Get.dialog(_loadingDialog(), barrierDismissible: false);
    try {
      var map = {
        "name": "",
        "ip_address": newIpAddress,
        "store_id": storeId,
        "isActive": true,
        "type": 0,
        "category_id": 0,
        "isRemote": true
      };
      final result = await Future.any([
        CallService().editIpAddress(map, printerId),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (result != null) {
        await getPrinterIp(showLoader: false);
        _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('update_ip'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 100),
          ));
        }
        return true;
      } else {
        throw Exception('timeout_null'.tr);
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'failed_update_ip'.tr}: $e'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 100),
        ));
      }
      return false;
    }
  }

  Future<void> getStoreSetting(String bearerKey) async {
    if (!mounted) return;
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      if (storeID == null) { print("❌ Store ID not found"); return; }
      final result = await Future.any([
        ApiRepo().getStoreSetting(bearerKey, storeID),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);
      if (result != null && mounted) {
        setState(() {
          if (!_autoAcceptUserModified) _autoRemoteOrderrAccept = result.auto_accept_orders_remote ?? false;  // CHANGE
          deliveryAvailable = result.lieferung_enabled ?? false;
          pickupEnabled = result.abholung_enabled ?? false;
          reservationEnabled = result.tisch_reservierung_enabled ?? false;
          _autotableBook = result.auto_accept_reservations ?? false;
        });
        print("✅ Settings loaded from server: Remote Accept = $_autoRemoteOrderrAccept");
      }
    } catch (e) {
      print("❌ getStoreSetting error: $e");
    }
  }

  Future<void> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      if (storeID == null) return;
      Store store = await ApiRepo().getStoreData(bearerKey, storeID);
      if (mounted && !_manualSettingsInitialized) {  // CHANGE: add this condition
        setState(() {
          _isManualOverride = store.isManualOverride ?? false;
          _isManualStart = store.manualStatus == "open";
          _manualSettingsInitialized = true;  // ADD THIS
        });
      }
    } catch (e) {
      print("getStoredta error: $e");
    }
  }
}

class IpAddressItem {
  String ip;
  bool isActive;
  IpAddressItem({required this.ip, required this.isActive});
}