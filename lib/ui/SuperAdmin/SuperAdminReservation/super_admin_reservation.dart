import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../models/reservation/get_history_reservation.dart';
import '../../../utils/my_application.dart';
import '../../Login/LoginScreen.dart';
import '../../table Book/reservation_details.dart';

class SuperAdminReservation extends StatefulWidget {
  const SuperAdminReservation({super.key});

  @override
  State<SuperAdminReservation> createState() => _SuperAdminReservationState();
}

class _SuperAdminReservationState extends State<SuperAdminReservation> with WidgetsBindingObserver {
  String dateSeleted = "";
  bool hasInternet = true;
  Timer? _internetCheckTimer;
  bool _isDialogShowing = false;
  Timer? _reservationTimer;
  String? storeId;
  SharedPreferences? sharedPreferences;
  bool isLoading = false;

  // Store history reservations
  List<GetHistoryReservationResponseModel> historyReservations = [];

  Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'booked':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String? status) {
    if (status == null) return Icons.help;

    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.visibility;
      case 'booked':
        return Icons.check;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  void _startInternetMonitoring() {
    _internetCheckTimer?.cancel();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnection = connectivityResult != ConnectivityResult.none;

      if (hasConnection != hasInternet) {
        setState(() {
          hasInternet = hasConnection;
        });

        if (hasConnection) {
          print("🌐 Internet restored in super admin reservation screen, refreshing data...");
          loadReservationHistory();
        }
      }
    });
  }

  String? convertDisplayDateToApiFormat(String displayDate) {
    try {
      DateTime parsedDate = DateFormat('d MMMM, y').parse(displayDate);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print("Error parsing display date: $e");
      return null;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  Future<void> _offlineLogout() async {
    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );

      print("🚪 Starting offline logout process...");

      await _preserveUserIPDataOffline();
      await _forceCompleteLogoutCleanupOffline();
      app.appController.clearOnLogout();

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.offAll(() => const LoginScreen());
      print("✅ Offline logout completed successfully");

    } catch (e) {
      print("❌ Error in offline logout: $e");
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.offAll(() => const LoginScreen());
    }
  }

  Future<void> _preserveUserIPDataOffline() async {
    try {
      print("💾 Preserving IP data for current user (offline)...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentStoreId = prefs.getString(valueShared_STORE_KEY);

      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        String userPrefix = "user_${currentStoreId}_";

        for (int i = 0; i < 5; i++) {
          String? currentIP = prefs.getString('printer_ip_$i');
          if (currentIP != null && currentIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
          }
        }

        for (int i = 0; i < 5; i++) {
          String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
          if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
          }
        }

        print("✅ IP data preserved for store: $currentStoreId (offline)");
      }
    } catch (e) {
      print("❌ Error preserving IP data (offline): $e");
    }
  }

  Future<void> _forceCompleteLogoutCleanupOffline() async {
    try {
      print("🧹 Starting complete offline logout cleanup...");

      for (int attempt = 0; attempt < 3; attempt++) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
          'printer_ip_backup',
          'printer_ip_0_backup',
          'last_save_timestamp',
          'printer_ip_0',
          'printer_ip_remote_0',
          'selected_ip_index',
          'selected_ip_remote_index',
          'auto_order_accept',
          'auto_order_print',
          'auto_order_remote_accept',
          'auto_order_remote_print',
          'cached_sales_date',
          'cached_order_date',
          'cached_store_id',
          'cached_store_name',
          'store_name',
          valueShared_STORE_NAME,
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        await prefs.reload();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print("✅ Complete offline logout cleanup SUCCESS");
    } catch (e) {
      print("❌ Error in complete offline logout cleanup: $e");
    }
  }

  void _showLogoutDialog() {
    if (_isDialogShowing || !mounted) return;

    _isDialogShowing = true;
    print("📱 Showing logout dialog");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Text("Connection Error"),
              ],
            ),
            content: const Text("Cannot connect to server. Please logout and login again to continue."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  _offlineLogout();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInternetMonitoring();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadReservationHistory();
    });
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String date = DateFormat('dd-MM-yyyy').format(dateTime);
      String time = DateFormat('HH:mm').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed, refreshing reservations");
      loadReservationHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _internetCheckTimer?.cancel();
    _reservationTimer?.cancel();
    super.dispose();
  }

  Future<void> loadReservationHistory() async {
    await getReservationHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('reserv'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            )),
                        GestureDetector(
                          onTap: () {
                            openCalendarScreen();
                          },
                          child: Text(
                            dateSeleted.isEmpty
                                ? DateFormat('d MMMM, y').format(DateTime.now())
                                : dateSeleted,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0, top: 5),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                openCalendarScreen();
                              },
                              child: Row(
                                children: [
                                  Text('history'.tr,
                                      style: const TextStyle(
                                          fontFamily: "Mulish",
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xff1F1E1E))),
                                  const SizedBox(width: 5),
                                  SvgPicture.asset('assets/images/dropdown.svg',
                                      height: 5, width: 11),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (dateSeleted.isNotEmpty &&
                                dateSeleted !=
                                    DateFormat('d MMMM, y')
                                        .format(DateTime.now()))
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    dateSeleted = "";
                                  });
                                  loadReservationHistory();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue, width: 1),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.today,
                                          size: 14, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text(
                                        'Today',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${'total_reserv'.tr}: ${historyReservations.length}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: "Mulish",
                                color: Colors.black),
                          ),
                          IconButton(
                              iconSize: 24,
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await loadReservationHistory();
                              }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              historyReservations.isEmpty
                  ? Center(
                child: Column(
                  children: [
                    Lottie.asset('assets/animations/empty.json',
                        height: 150, width: 150),
                    Text('no_reservation'.tr)
                  ],
                ),
              )
                  : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyReservations.length,
                  itemBuilder: (context, index) {
                    var reserv = historyReservations[index];

                    return GestureDetector(
                      onTap: () async {
                        await Get.to(
                              () => ReservationDetails(reserv.id.toString()),
                        )?.then((result) async {
                          print("Returned from ReservationDetails, refreshing reservations");
                          await getReservationHistory();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/reservation.png',
                                      height: 25,
                                      width: 25,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      formatDateTime(reserv.reservedFor.toString()),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Mulish',
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 5),
                                    Text(
                                      reserv.createdAt != null
                                          ? DateFormat('HH:mm').format(
                                          DateTime.parse(
                                              reserv.createdAt!))
                                          : '--:--',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontFamily: "Mulish",
                                        fontSize: 10,
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.5,
                                  child: Text(
                                    '${reserv.customerName.toString()}/${reserv.customerPhone.toString()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        fontFamily: "Mulish"),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${'order_id'.tr} :',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          fontFamily: "Mulish"),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      reserv.id.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          fontFamily: "Mulish"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/person.png',
                                      height: 18,
                                      width: 14,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      reserv.guestCount.toString(),
                                      style: const TextStyle(
                                          fontFamily: 'Mulish',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      reserv.status.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontFamily: "Mulish-Regular",
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                        getStatusColor(reserv.status),
                                        child: Icon(
                                          getStatusIcon(reserv.status),
                                          color: Colors.white,
                                          size: 16,
                                        )),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getReservationHistory() async {
    setState(() {
      isLoading = true;
    });

    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );
    }

    _reservationTimer = Timer(const Duration(seconds: 7), () {
      if (Get.isDialogOpen ?? false) {
        Navigator.of(Get.overlayContext!).pop();
        showSnackbar("Timeout", "Request timed out. Please try again.");
      }
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (Get.isDialogOpen == true) {
          Navigator.of(Get.overlayContext!).pop();
        }

        setState(() {
          isLoading = false;
          hasInternet = false;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
        return;
      }

      // Get target date
      String targetDate;
      if (dateSeleted.isNotEmpty) {
        targetDate = convertDisplayDateToApiFormat(dateSeleted) ??
            DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else {
        targetDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      // Get store ID
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storeIdString = prefs.getString(valueShared_STORE_KEY);
      int storeIdInt;

      if (storeIdString != null && storeIdString.isNotEmpty) {
        storeIdInt = int.tryParse(storeIdString) ?? 13;

      } else {
        storeIdInt = 13;
        print("Warning: Store ID not found, using default: 13");
      }

      var map = {
        "store_id": storeIdInt,
        "target_date": targetDate,
        "offset": 0
      };

      print("📋 Getting Reservation History: $map");

      List<GetHistoryReservationResponseModel> reservations = await CallService().reservationHistory(map);

      _reservationTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      setState(() {
        hasInternet = true;
        isLoading = false;
        historyReservations = reservations;
      });

      print('✅ Loaded ${reservations.length} reservations from history');
    } catch (e) {
      _reservationTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      setState(() {
        isLoading = false;
      });

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        setState(() {
          hasInternet = false;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      } else {
        print('❌ Error getting reservation history: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr} - ${'load'.tr}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void openCalendarScreen() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const SuperAdminCalendarDialog(),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => dateSeleted = result);
      await getReservationHistory();
      print("Selected date: $result");
    }
  }

  void showSnackbar(String title, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class SuperAdminCalendarDialog extends StatefulWidget {
  const SuperAdminCalendarDialog({super.key});

  @override
  _SuperAdminCalendarDialogState createState() => _SuperAdminCalendarDialogState();
}

class _SuperAdminCalendarDialogState extends State<SuperAdminCalendarDialog> {
  DateTime? _selectedDate;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading = false;
  Map<String, int> reservationCounts = {};
  int? storeId; // ✅ Store ID as instance variable

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  // ✅ Initialize store ID and then load data
  Future<void> _initializeAndLoadData() async {
    await _getStoreId();
    await loadReservationCountsFromAPI();
  }

  Future<void> _getStoreId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storeIdString = prefs.getString(valueShared_STORE_KEY);

      if (storeIdString != null && storeIdString.isNotEmpty) {
        storeId = int.tryParse(storeIdString);
        print('✅ Super Admin Calendar Store ID: $storeId');
      } else {
        print('❌ Store ID not found');
      }
    } catch (e) {
      print('❌ Error getting store ID: $e');
    }
  }

// ✅ NEW METHOD: Fetch reservations from API for the entire month
  Future<void> loadReservationCountsFromAPI() async {
    if (storeId == null) {
      print('❌ Cannot load reservations: Store ID is null');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, int> counts = {};

      // Get first and last day of selected month
      DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
      DateTime lastDay = DateTime(selectedYear, selectedMonth + 1, 0);

      print('📅 Fetching reservations for: ${DateFormat('yyyy-MM').format(firstDay)}');

      // ✅ Fetch reservations day by day for the selected month
      for (int day = 1; day <= lastDay.day; day++) {
        DateTime targetDate = DateTime(selectedYear, selectedMonth, day);
        String dateString = DateFormat('yyyy-MM-dd').format(targetDate);

        var map = {
          "store_id": storeId!,
          "target_date": dateString,
          "offset": 0
        };

        try {
          List<GetHistoryReservationResponseModel> dayReservations =
          await CallService().reservationHistory(map);

          if (dayReservations.isNotEmpty) {
            counts[dateString] = dayReservations.length;
          }
        } catch (e) {
          print('⚠️ Error fetching $dateString: $e');
        }

        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        setState(() {
          reservationCounts = counts;
          isLoading = false;
        });
      }

      print('✅ Loaded ${counts.length} days with reservations');
    } catch (e) {
      print('❌ Error loading reservation counts: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    if (!mounted) return;

    setState(() {
      _selectedDate = selectedDate;
    });

    reservationHistory();
  }

  Future<void> reservationHistory() async {
    if (!mounted) return;

    if (storeId == null) {
      print('❌ Cannot get reservation history: Store ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store ID not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String targetDate;
    if (_selectedDate != null) {
      targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else {
      targetDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    var map = {
      "store_id": storeId!,
      "target_date": targetDate,
      "offset": 0
    };

    print("📋 Getting History with Store ID: $storeId, Date: $targetDate");

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );

      List<GetHistoryReservationResponseModel> orders = await CallService().reservationHistory(map);

      print('✅ Number of orders received: ${orders.length}');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (_selectedDate != null && mounted) {
        String displayDate = DateFormat('d MMMM, y').format(_selectedDate!);
        Navigator.of(context).pop(displayDate);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'gett_history'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      print('❌ Getting History error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading && reservationCounts.isEmpty // ✅ Show loader only on first load
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/burger.json',
                width: 100,
                height: 100,
                repeat: true,
              ),
              const SizedBox(height: 10),
              const Text('Loading reservations...\nPlease Wait It Will Take SomeTime',
                  style: TextStyle(fontFamily: 'Mulish')),
            ],
          ),
        )
            : ListView(
          children: [
            if (isLoading) // ✅ Show small indicator during month change
              LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            _buildCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final year = selectedYear;
    final month = selectedMonth;

    final firstDay = DateTime(year, month, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(year, month + 1, 0).day;

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevMonthDays = DateTime(year, month, 0).day;

    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;

    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;

    int totalReservationsForMonth = 0;
    for (int day = 1; day <= totalDays; day++) {
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
      totalReservationsForMonth += reservationCounts[dateKey] ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Reservations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish',
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.green),
                  onPressed: isLoading ? null : () async { // ✅ Disable during loading
                    setState(() {
                      if (selectedMonth == 1) {
                        selectedMonth = 12;
                        selectedYear--;
                      } else {
                        selectedMonth--;
                      }
                    });
                    await loadReservationCountsFromAPI();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: Colors.green),
                  onPressed: isLoading ? null : () async { // ✅ Disable during loading
                    setState(() {
                      if (selectedMonth == 12) {
                        selectedMonth = 1;
                        selectedYear++;
                      } else {
                        selectedMonth++;
                      }
                    });
                    await loadReservationCountsFromAPI();
                  },
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${DateFormat('MMMM').format(DateTime(year, month))}, ',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    TextSpan(
                      text: year.toString(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${'total_reserv'.tr}: $totalReservationsForMonth',
                style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            _buildWeekdayRow(),
            ...List.generate(totalCells ~/ 7, (week) {
              return TableRow(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = week * 7 + dayIndex;
                  DateTime cellDate;

                  if (cellIndex < startWeekday) {
                    final day = prevMonthDays - (startWeekday - cellIndex - 1);
                    cellDate = DateTime(prevYear, prevMonth, day);
                  } else if (cellIndex >= startWeekday + totalDays) {
                    final day = cellIndex - (startWeekday + totalDays) + 1;
                    cellDate = DateTime(nextYear, nextMonth, day);
                  } else {
                    final day = cellIndex - startWeekday + 1;
                    cellDate = DateTime(year, month, day);
                  }

                  final isCurrentMonth = cellDate.month == month;

                  return _buildCalendarCell(cellDate, isCurrentMonth);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isCurrentMonth) {
    final textColor = isCurrentMonth ? Colors.black : Colors.grey[400];
    String dateKey = DateFormat('yyyy-MM-dd').format(date);
    int bookingCount = reservationCounts[dateKey] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: isCurrentMonth ? () => _onDateSelected(date) : null,
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day
                ? Colors.green.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${date.day}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),

              // Show reservation count if available
              if (isCurrentMonth && bookingCount > 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$bookingCount',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildWeekdayRow() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return TableRow(
      children: days.map((day) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Mulish',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}