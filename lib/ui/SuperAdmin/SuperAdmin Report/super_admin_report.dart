import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../models/DailySalesReport.dart';
import '../../../models/get_admin_report_response_model.dart';
import '../../../models/order_history_response_model.dart';
import '../../order_history.dart';

class SuperAdminReport extends StatefulWidget {
  const SuperAdminReport({super.key});

  @override
  State<SuperAdminReport> createState() => _SuperAdminReportState();
}

class _SuperAdminReportState extends State<SuperAdminReport> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  Report? storeReport;
  String? storeName;
  int? storeId;
  DateTime? _selectedDate;
  bool showCalendar = false;
  late int displayedMonth;
  late int displayedYear;
  List<DailySalesReport> dailyReportsList = [];
  DailySalesReport? _selectedDailyReport;
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isCalculatingTotal = false;
  double _monthTotalSales = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    displayedMonth = now.month;
    displayedYear = now.year;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoreIdAndFetchReport();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStoreIdAndFetchReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '');

    if (storeId != null) {
      await getAdminReport(); // ✅ Keep - for monthly summary
      await getDailyReports(); // ✅ NEW - for calendar
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store ID not found')),
        );
      }
    }
  }

  Future<void> getAdminReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

    setState(() {
      isLoading = true;
    });

    try {
      GetAdminReportResponseModel report = await CallService().getAdminReport(storeId.toString());

      if (mounted) {
        // Find report for this specific store
        Reports? matchedStore = report.reports?.firstWhere(
              (r) => r.storeId == storeId,
          orElse: () => Reports(),
        );

        setState(() {
          if (matchedStore?.hasData == true && matchedStore?.report != null) {
            storeReport = matchedStore!.report;
            storeName = matchedStore.storeName;
            _monthTotalSales = storeReport!.totalSales ?? 0.0;
          }
          isLoading = false;
          print('Store Report loaded for Store ID: $storeId');
        });
      }
    } catch (e) {
      print('Error getting Report : $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
      }
    }
  }

  Future<void> getDailyReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

    if (bearerKey == null || bearerKey.isEmpty) {
      print('❌ Bearer key not found for daily reports');
      return;
    }

    try {
      print('🔄 Fetching daily reports...');
      final result = await CallService().reportGetApiAdmin(bearerKey,storeId.toString()).timeout(const Duration(seconds: 7));

      print('✅ Daily Reports Response: ${result.length ?? 0} reports found');

      // ✅ Print first few reports to debug
      if (result.isNotEmpty) {
        for (var i = 0; i < (result.length < 3 ? result.length : 3); i++) {
          print('Report $i: Date=${result[i].startDate}, Sales=${result[i].totalSales}');
        }
      }

      if (mounted) {
        setState(() {
          dailyReportsList = result;
          print('📊 Daily reports list updated: ${dailyReportsList.length} reports');
          _calculateMonthTotal(displayedMonth, displayedYear);
        });
      }
    } catch (e) {
      print('❌ Error getting daily reports: $e');
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    return NumberFormat('#,##0.0#', locale == 'de' ? 'de_DE' : 'en_US').format(amount);
  }

  void _resetCalendarToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      showCalendar = false;
      displayedMonth = now.month;
      displayedYear = now.year;
      _selectedDate = null;
      _selectedDailyReport = null; // ✅ Added
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
        child: Lottie.asset(
          'assets/animations/burger.json',
          width: 150,
          height: 150,
          repeat: true,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (showCalendar) ...[
              _calendar(),
              const SizedBox(height: 16),
            ],
            showCalendar && _selectedDate != null
                ? _buildDailyReportStatus(_selectedDailyReport)
                : !showCalendar
                ? _buildMonthlyReportStatus(storeReport)
                : const SizedBox.shrink(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildMonthlyReportStatus(Report? report) {
    final reportToShow = report ?? Report();
    final data = _getMonthlyReportData(reportToShow); // ✅ Renamed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Lottie.asset('assets/animations/sales.json',
                width: 30, height: 30, repeat: true),
            const Text("Monthly Report", // ✅ Changed label
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildDataRows(data['sales']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/payment.json',
              width: 30, height: 30, repeat: true),
          Text("payment".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['payment']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/orderType.json',
              width: 30, height: 30, repeat: true),
          Text("order_type".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['orderType']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/approval.json',
              width: 30, height: 30, repeat: true),
          Text("approval".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['approval']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/tax.json',
              width: 30, height: 30, repeat: true),
          Text("tax".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['tax']!),
        const SizedBox(height: 20),
        // GestureDetector(
        //   onTap: () => orderHistory(),
        //   child: Container(
        //     width: double.infinity,
        //     padding: EdgeInsets.all(12),
        //     decoration: BoxDecoration(
        //         borderRadius: BorderRadius.circular(5), color: Colors.green),
        //     child: Center(
        //       child: Text('view_full'.tr,
        //           style: TextStyle(
        //               fontWeight: FontWeight.w600,
        //               fontSize: 14,
        //               fontFamily: "Mulish",
        //               color: Colors.white)),
        //     ),
        //   ),
        // )
      ],
    );
  }

  Widget _calendarCell(DateTime date, DailySalesReport? dailyReport, bool isCurrentMonth) {
    return GestureDetector(
      onTap: () {
        if (dailyReport != null) {
          print('📱 Cell tapped: ${date.day}, Sales: ${dailyReport.totalSales}');
          setState(() {
            _selectedDailyReport = dailyReport;
            _selectedDate = date;
          });
        } else {
          print('📱 Cell tapped: ${date.day}, No data available');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${date.day}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentMonth ? Colors.black : Colors.grey[600])),
              const SizedBox(height: 2),
              if (dailyReport != null) ...[
                SvgPicture.asset('assets/images/ic_report.svg', height: 12, width: 12),
                const SizedBox(height: 2),
                Text("€${formatAmount(dailyReport.totalSales ?? 0)}", // ✅ Added € symbol
                    style: const TextStyle(fontSize: 10, color: Colors.green)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendar() {
    final dailyReportsMap = _getDailyReportsForMonth(displayedMonth, displayedYear);

    print('🗓️ Calendar rendering for: $displayedMonth/$displayedYear');
    print('🗓️ Reports map has ${dailyReportsMap.length} days with data');

    final today = DateTime.now();
    final firstDay = DateTime(displayedYear, displayedMonth, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(displayedYear, displayedMonth + 1, 0).day;
    final prevMonth = displayedMonth == 1 ? 12 : displayedMonth - 1;
    final prevYear = displayedMonth == 1 ? displayedYear - 1 : displayedYear;
    final prevMonthDays = DateTime(displayedYear, displayedMonth, 0).day;
    final nextMonth = displayedMonth == 12 ? 1 : displayedMonth + 1;
    final nextYear = displayedMonth == 12 ? displayedYear + 1 : displayedYear;
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                displayedMonth = prevMonth;
                displayedYear = prevYear;
                _selectedDailyReport = null;
                _selectedDate = null;
                _calculateMonthTotal(prevMonth, prevYear);
              }),
            ),
            Text("${_monthName(displayedMonth)} $displayedYear",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                displayedMonth = nextMonth;
                displayedYear = nextYear;
                _selectedDailyReport = null;
                _selectedDate = null;
                _calculateMonthTotal(nextMonth, nextYear);
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${'total_sales'.tr} : ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            _isCalculatingTotal
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
                : Text(
              '€ ${formatAmount(_monthTotalSales)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          ],
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
                    cellDate = DateTime(displayedYear, displayedMonth, day);
                  }

                  final isCurrentMonth = cellDate.month == displayedMonth;
                  final dailyReport = isCurrentMonth ? dailyReportsMap[cellDate.day] : null;

                  // ✅ Debug log for each cell
                  if (isCurrentMonth && dailyReport != null) {
                    print('Cell ${cellDate.day}: Has data = ${dailyReport.totalSales}');
                  }

                  return _calendarCell(cellDate, dailyReport, isCurrentMonth);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (showCalendar) {
              setState(() {
                showCalendar = false;
                _selectedDate = null;
                _resetCalendarToCurrentMonth();
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(storeName ?? 'Store Report',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: "Mulish",
                          color: Color(0xff0C831F))),
                  Positioned(
                    right: -11,
                    top: 0,
                    child: FadeTransition(
                      opacity: _animation,
                      child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: Color(0xff0C831F), shape: BoxShape.circle)),
                    ),
                  ),
                ],
              ),
              Text(
                _selectedDate != null
                    ? DateFormat('MMMM y').format(_selectedDate!)
                    : DateFormat('MMMM y').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff757B8F),
                    fontWeight: FontWeight.w600,
                    fontFamily: "Mulish"),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              showCalendar = !showCalendar;
              if (!showCalendar) {
                _selectedDate = null;
                _resetCalendarToCurrentMonth();
              }
            });
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
              SvgPicture.asset('assets/images/dropdown.svg', height: 5, width: 11),
            ],
          ),
        )
      ],
    );
  }

  String _monthName(int month) {
    var names = [
      '',
      'january'.tr,
      'february'.tr,
      'march'.tr,
      'april'.tr,
      'may'.tr,
      'june'.tr,
      'july'.tr,
      'august'.tr,
      'september'.tr,
      'october'.tr,
      'november'.tr,
      'december'.tr
    ];
    return names[month];
  }

  TableRow _buildWeekdayRow() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return TableRow(
      children: days
          .map((day) => Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Center(
            child: Text(day,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16))),
      ))
          .toList(),
    );
  }

  List<Widget> _buildDataRows(Map<String, String> data) {
    return data.entries
        .map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: e.key,
                style:
                const TextStyle(color: Colors.black, fontFamily: 'Mulish')),
            TextSpan(
                text: "   ${e.value}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontFamily: 'Mulish')),
          ],
        ),
      ),
    ))
        .toList();
  }

  Map<String, Map<String, String>> _getMonthlyReportData(Report report) {
    return {
      'sales': {
        "total_sales".tr: '€ ${formatAmount(report.totalSales ?? 0.0)}',
        "total_order".tr: '${report.totalOrders ?? 0}',
        "total_tax".tr: '€ ${formatAmount(report.totalTax ?? 0.0)}',
        "cash_total".tr: '€ ${formatAmount(report.cashTotal ?? 0.0)}',
        "online".tr: '€ ${formatAmount(report.onlineTotal ?? 0.0)}',
        "net_subtotal".tr: '€ ${formatAmount(report.netTotal ?? 0.0)}',
        "discounts".tr: '€ ${formatAmount(report.discountTotal ?? 0.0)}',
        "delivery_fee".tr: '€ ${formatAmount(report.deliveryTotal ?? 0.0)}',
        "sale".tr: '€ ${formatAmount(report.totalSalesDelivery ?? 0.0)}',
      },
      'payment': {"cash".tr: '${report.paymentMethods?.cash ?? 0}'},
      'orderType': {
        "delivery".tr: '${report.orderTypes?.delivery ?? 0}',
        "pickup".tr: '${report.orderTypes?.pickup ?? 0}',
        "dine_in".tr: '${report.orderTypes?.dineIn ?? 0}',
      },
      'approval': {
        "pending".tr: '${report.approvalStatuses?.pending ?? 0}',
        "accepted".tr: '${report.approvalStatuses?.accepted ?? 0}',
        "decline".tr: '${report.approvalStatuses?.declined ?? 0}',
      },
      'tax': {
        "19%": '€ ${formatAmount(report.taxBreakdown?.d19 ?? 0.0)}',
        "7%": '€ ${formatAmount(report.taxBreakdown?.d7 ?? 0.0)}',
      },
    };
  }

  Future<void> orderHistory() async {
    // ✅ Use _selectedDate directly (no parameter needed)
    final targetDate = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

    var map = {"store_id": storeId, "target_date": targetDate, "offset": 0};

    try {
      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json',
            width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );

      List<orderHistoryResponseModel> orders = await CallService().orderHistory(map);

      if (Get.isDialogOpen ?? false) Get.back();

      Get.to(() => OrderHistory(orders: orders, targetDate: targetDate));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load order history: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3)),
      );
    }
  }

  Map<int, DailySalesReport> _getDailyReportsForMonth(int month, int year) {
    print('📅 Getting reports for month: $month, year: $year');
    print('📋 Total daily reports available: ${dailyReportsList.length}');

    final Map<int, DailySalesReport> map = {};

    for (var report in dailyReportsList) {
      if (report.startDate != null) {
        try {
          final date = DateTime.parse(report.startDate!);
          print('   Checking report: ${report.startDate} -> month=${date.month}, year=${date.year}');

          if (date.month == month && date.year == year) {
            map[date.day] = report;
            print('   ✅ Added to map: day=${date.day}, sales=${report.totalSales}');
          }
        } catch (e) {
          print('   ❌ Error parsing date: ${report.startDate}, error: $e');
          continue;
        }
      }
    }

    print('🎯 Final map for month $month: ${map.length} days with data');
    print('🎯 Days with data: ${map.keys.toList()}');

    return map;
  }

  void _calculateMonthTotal(int month, int year) {
    print('💰 Calculating total for month: $month, year: $year');

    setState(() {
      _isCalculatingTotal = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      double total = 0.0;
      int reportCount = 0;

      for (var report in dailyReportsList) {
        if (report.startDate != null) {
          try {
            final date = DateTime.parse(report.startDate!);
            if (date.month == month && date.year == year) {
              total += report.totalSales ?? 0.0;
              reportCount++;
              print('   Adding: ${report.startDate} -> ${report.totalSales}');
            }
          } catch (e) {
            continue;
          }
        }
      }

      print('💰 Total calculated: €$total from $reportCount reports');

      if (mounted) {
        setState(() {
          _monthTotalSales = total;
          _isCalculatingTotal = false;
        });
      }
    });
  }

  Widget _buildDailyReportStatus(DailySalesReport? dailyReport) {
    final data = _getDailyReportData(dailyReport);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Lottie.asset('assets/animations/sales.json',
                width: 30, height: 30, repeat: true),
            Text(
                _selectedDate != null
                    ? DateFormat('dd MMMM y').format(_selectedDate!)
                    : "sales".tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildDataRows(data['sales']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/payment.json',
              width: 30, height: 30, repeat: true),
          Text("payment".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['payment']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/orderType.json',
              width: 30, height: 30, repeat: true),
          Text("order_type".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['orderType']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/approval.json',
              width: 30, height: 30, repeat: true),
          Text("approval".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['approval']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/tax.json',
              width: 30, height: 30, repeat: true),
          Text("tax".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['tax']!),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => orderHistory(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5), color: Colors.green),
            child: Center(
              child: Text('view_full'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: "Mulish",
                      color: Colors.white)),
            ),
          ),
        )
      ],
    );
  }

  Map<String, Map<String, String>> _getDailyReportData(DailySalesReport? report) {
    if (report == null) {
      return {
        'sales': {
          "total_sales".tr: '€ 0.00',
          "total_order".tr: '0',
          "total_tax".tr: '€ 0.00',
          "cash_total".tr: '€ 0.00',
          "online".tr: '€ 0.00',
          "net_subtotal".tr: '€ 0.00',
          "discounts".tr: '0',
          "delivery_fee".tr: '€ 0.00',
          "sale".tr: '€ 0.00',
        },
        'payment': {"cash".tr: '0'},
        'orderType': {
          "delivery".tr: '0',
          "pickup".tr: '0',
          "dine_in".tr: '0',
        },
        'approval': {
          "pending".tr: '0',
          "accepted".tr: '0',
          "decline".tr: '0',
        },
        'tax': {
          "19%": '€ 0.00',
          "7%": '€ 0.00',
        },
      };
    }

    return {
      'sales': {
        "total_sales".tr: '€ ${formatAmount(report.totalSales ?? 0.0)}',
        "total_order".tr: '${report.totalOrders ?? 0}',
        "total_tax".tr: '€ ${formatAmount(report.totalTax ?? 0.0)}',
        "cash_total".tr: '€ ${formatAmount(report.cashTotal ?? 0.0)}',
        "online".tr: '€ ${formatAmount(report.onlineTotal ?? 0.0)}',
        "net_subtotal".tr: '€ ${formatAmount(report.data?.netTotal ?? 0.0)}',
        "discounts".tr: '${(report.data?.discountTotal ?? 0).toInt()}',
        "delivery_fee".tr: '€ ${formatAmount(report.data?.deliveryTotal?.toDouble() ?? 0.0)}',
        "sale".tr: '€ ${formatAmount(report.data?.totalSalesDelivery ?? 0.0)}',
      },
      'payment': {"cash".tr: '${report.data?.paymentMethods['cash'] ?? 0}'},
      'orderType': {
        "delivery".tr: '${report.data?.orderTypes['delivery'] ?? 0}',
        "pickup".tr: '${report.data?.orderTypes['pickup'] ?? 0}',
        "dine_in".tr: '${report.data?.orderTypes['dine_in'] ?? 0}',
      },
      'approval': {
        "pending".tr: '${report.data?.approvalStatuses['pending'] ?? 0}',
        "accepted".tr: '${report.data?.approvalStatuses['accepted'] ?? 0}',
        "decline".tr: '${report.data?.approvalStatuses['declined'] ?? 0}',
      },
      'tax': {
        "19%": '€ ${formatAmount(report.data?.taxBreakdown?.d19 ?? 0.0)}',
        "7%": '€ ${formatAmount(report.data?.taxBreakdown?.d7 ?? 0.0)}',
      },
    };
  }

}