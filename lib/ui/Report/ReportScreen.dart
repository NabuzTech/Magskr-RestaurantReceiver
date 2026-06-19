import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/DailySalesReport.dart';
import '../../models/order_history_response_model.dart';
import '../../models/today_report.dart';
import '../../utils/my_application.dart';
import '../Order_history/order_history.dart';
import 'PdfPreviewScreen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  List<DailySalesReport> reportList = [];
  DailySalesReport? _selectedReport;
  DailySalesReport? _currentDateReport;
  DateTime? _selectedDate;
  bool _isInitialLoading = true;
  late int displayedMonth;
  late int displayedYear;
  bool _isRefreshing = false;
  String totalSales = '0', totalOrder = '0', totalTax = '0', cashTotal = '0',
      online = '0', net = '0', discount = '0', deliveryFee = '0',
      salesDelivery = '0', cashMethod = '0', delivery = '0', pickUp = '0',
      dineIn = '0', pending = '0', accepted = '0', declined = '0',
      tax19 = '0', tax7 = '0';
  bool _isDisposed = false;
  bool showCalendar = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  DateTime? _lastUpdateTime;
  Timer? _liveDataTimer;

  bool _isCalculatingTotal = false;
  double _monthTotalSales = 0.0;

  bool _showGenerateOptions = false;
  bool _isGeneratingReport = false;

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

    ever(app.appController.reportRefreshTrigger, (_) {
      if (!_isRefreshing) {
        _refreshReportData();
      }
    });

    ever<int>(app.appController.selectedTabIndexRx, (tabIndex) {
      if (tabIndex == 2 && !_isRefreshing) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_isRefreshing) {
            _refreshReportData();
          }
        });
      }
    });

    initVar();
    _startLiveDataUpdates();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    _liveDataTimer?.cancel();
    super.dispose();
  }

  Future<void> initVar() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    setState(() {
      _isInitialLoading = true;
    });

    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    await getReports(bearerKey);
    getCurrentDateReport();
    await getLiveSaleReport();

    _calculateMonthTotal(displayedMonth, displayedYear);

    setState(() {
      _isInitialLoading = false;
    });
    _isRefreshing = false;
  }

  void getCurrentDateReport() {
    if (_isDisposed || !mounted) return;
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DailySalesReport? foundReport;
    for (var report in reportList) {
      if (report.startDate != null) {
        try {
          final reportDate = DateTime.parse(report.startDate!);
          if (DateFormat('yyyy-MM-dd').format(reportDate) == todayString) {
            foundReport = report;
            break;
          }
        } catch (e) {
          continue;
        }
      }
    }

    setState(() {
      _currentDateReport = foundReport ?? DailySalesReport(
        startDate: todayString,
        totalSales: 0.0,
        totalOrders: 0,
        cashTotal: 0.0,
        onlineTotal: 0.0,
        totalTax: 0.0,
      );
      if (foundReport == null) reportList.insert(0, _currentDateReport!);
    });
  }

  void _startLiveDataUpdates() {
    _liveDataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!showCalendar) getLiveSaleReport();
    });
  }

  Future<void> getReports(String? bearerKey) async {
    if (bearerKey == null) return;

    try {
      // ✅ No loading dialog - just fetch data
      final result = await ApiRepo().reportGetApi(bearerKey).timeout(const Duration(seconds: 7));
      if (!mounted) return;
      setState(() => reportList = result);
        } catch (e) {
      if (!mounted) return;
      showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
    }
  }

  void _resetCalendarToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      showCalendar = false;
      displayedMonth = now.month;
      displayedYear = now.year;
      _selectedReport = null;
      _selectedDate = null;
    });
  }

  Future<void> getLiveSaleReport() async {
    try {
      if (bearerKey == null || bearerKey!.isEmpty) {
        _setEmptyValues();
        return;
      }

      GetTodayReport model = await CallService().getLiveSaleData();

      if (model.code != null && model.code != 200) {
        _setEmptyValues();
        return;
      }

      if (mounted) {
        setState(() {
          totalSales = formatAmount(model.totalSales ?? 0.0);
          totalOrder = '${model.totalOrders ?? 0}';
          totalTax = formatAmount(model.totalTax ?? 0.0);
          cashTotal = formatAmount(model.cashTotal ?? 0.0);
          online = formatAmount(_toDouble(model.onlineTotal));
          net = formatAmount(model.netTotal ?? 0.0);
          discount = '${_toInt(model.discountTotal)}';
          deliveryFee = formatAmount(_toDouble(model.deliveryTotal));
          salesDelivery = formatAmount(model.totalSalesDelivery ?? 0.0);
          cashMethod = '${model.paymentMethods?.cash ?? 0}';
          delivery = '${model.orderTypes?.delivery ?? 0}';
          pickUp = '${model.orderTypes?.pickup ?? 0}';
          dineIn = '${model.orderTypes?.dineIn ?? 0}';
          pending = '${model.approvalStatuses?.pending ?? 0}';
          accepted = '${model.approvalStatuses?.accepted ?? 0}';
          declined = '${model.approvalStatuses?.declined ?? 0}';
          tax19 = formatAmount(model.taxBreakdown?.d19 ?? 0.0);
          tax7 = formatAmount(model.taxBreakdown?.d7 ?? 0.0);
          _lastUpdateTime = DateTime.now();
        });
      }
    } catch (e) {
      _setEmptyValues();
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return value is int ? value.toDouble() : value as double;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    return value is double ? value.toInt() : value as int;
  }

  void _setEmptyValues() {
    if (!mounted) return;
    setState(() {
      totalSales = totalTax = cashTotal = online = net = deliveryFee = salesDelivery = tax19 = tax7 = '0.00';
      totalOrder = discount = cashMethod = delivery = pickUp = dineIn = pending = accepted = declined = '0';
    });
  }

  Future<void> _refreshReportData() async {
    if (_isDisposed || !mounted) return;
    if (_isRefreshing) return;

    _isRefreshing = true;
    _resetCalendarToCurrentMonth();
    await getReports(bearerKey);
    getCurrentDateReport();
    await getLiveSaleReport();
    _calculateMonthTotal(displayedMonth, displayedYear);
    _isRefreshing = false;
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    return NumberFormat('#,##0.0#', locale == 'de' ? 'de_DE' : 'en_US').format(amount);
  }

  void _showLoadingDialog() {
    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );
  }

  void _closeDialog() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  void _calculateMonthTotal(int month, int year) {
    setState(() {
      _isCalculatingTotal = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      double total = 0.0;
      for (var report in reportList) {
        if (report.startDate != null) {
          try {
            final date = DateTime.parse(report.startDate!);
            if (date.month == month && date.year == year) {
              total += report.totalSales ?? 0.0;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (mounted) {
        setState(() {
          _monthTotalSales = total;
          _isCalculatingTotal = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isInitialLoading
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
            _buildGenerateReportOptions(),
            if (showCalendar) ...[
              _calendar(),
              const SizedBox(height: 16),
            ],
            showCalendar && _selectedDate != null
                ? _buildReportStatus(_selectedReport ?? _currentDateReport)
                : !showCalendar && !_showGenerateOptions ? _buildReportStatus(null) : const SizedBox.shrink(),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
                _selectedReport = null;
                _selectedDate = null;
                _resetCalendarToCurrentMonth();
              });
            }
            if (_showGenerateOptions) {
              setState(() => _showGenerateOptions = false);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text('liveSale'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: "Mulish", color: Color(0xff0C831F))),
                  Positioned(
                    right: -11, top: 0,
                    child: FadeTransition(
                      opacity: _animation,
                      child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xff0C831F), shape: BoxShape.circle)),
                    ),
                  ),
                ],
              ),
              Text(
                _selectedDate != null ? DateFormat('MMMM y').format(_selectedDate!) : DateFormat('MMMM y').format(DateTime.now()),
                style: const TextStyle(fontSize: 11, color: Color(0xff757B8F), fontWeight: FontWeight.w600, fontFamily: "Mulish"),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _showGenerateOptions = !_showGenerateOptions;
              if (_showGenerateOptions) {
                showCalendar = false;
                _selectedReport = null;
                _selectedDate = null;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showGenerateOptions ? Colors.green : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 16, color: _showGenerateOptions ? Colors.white : Colors.green),
                const SizedBox(width: 4),
                Text(
                  'report_btn'.tr,
                  style: TextStyle(
                    fontFamily: "Mulish",
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _showGenerateOptions ? Colors.white : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              showCalendar = !showCalendar;
              if (showCalendar) {
                _showGenerateOptions = false;
              }
              if (!showCalendar) {
                _selectedReport = null;
                _selectedDate = null;
                _resetCalendarToCurrentMonth();
              }
            });
          },
          child: Row(
            children: [
              Text('history'.tr, style: const TextStyle(fontFamily: "Mulish", fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff1F1E1E))),
              const SizedBox(width: 5),
              SvgPicture.asset('assets/images/dropdown.svg', height: 5, width: 11),
            ],
          ),
        )
      ],
    );
  }

  Map<int, DailySalesReport> _getReportsForMonth(int month, int year) {
    final Map<int, DailySalesReport> map = {};
    for (var report in reportList) {
      if (report.startDate != null) {
        final date = DateTime.parse(report.startDate!);
        if (date.month == month && date.year == year) {
          map[date.day] = report;
        }
      }
    }
    return map;
  }

  Widget _calendar() {
    final reportMap = _getReportsForMonth(displayedMonth, displayedYear);
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
                _selectedReport = null;
                _calculateMonthTotal(prevMonth, prevYear);
              }),
            ),
            Text("${_monthName(displayedMonth)} $displayedYear", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                displayedMonth = nextMonth;
                displayedYear = nextYear;
                _selectedReport = null;
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
                  final report = isCurrentMonth ? reportMap[cellDate.day] : null;

                  return _calendarCell(cellDate, report, isCurrentMonth);
                }),
              );
            }),
          ],
        ),

      ],
    );
  }

  String _monthName(int month) {
    var names = ['', 'january'.tr, 'february'.tr, 'march'.tr, 'april'.tr, 'may'.tr, 'june'.tr,
      'july'.tr, 'august'.tr, 'september'.tr, 'october'.tr, 'november'.tr, 'december'.tr];
    return names[month];
  }

  Widget _calendarCell(DateTime date, DailySalesReport? report, bool isCurrentMonth) {
    return GestureDetector(
      onTap: () {
        if (report != null) {
          setState(() {
            _selectedReport = report;
            _selectedDate = date;
          });
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
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: isCurrentMonth ? Colors.black : Colors.grey[600])),
              const SizedBox(height: 2),
              if (report != null) ...[
                SvgPicture.asset('assets/images/ic_report.svg', height: 12, width: 12),
                const SizedBox(height: 2),
                Text(formatAmount(report.totalSales ?? 0), style: const TextStyle(fontSize: 10, color: Colors.green)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildWeekdayRow() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return TableRow(
      children: days.map((day) => Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Center(child: Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
      )).toList(),
    );
  }

  Widget _buildReportStatus(DailySalesReport? report) {
    if (showCalendar && _selectedDate == null) return const SizedBox.shrink();

    final isLiveData = report == null;
    final data = isLiveData ? _getLiveData() : _getReportData(report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Lottie.asset('assets/animations/sales.json', width: 30, height: 30, repeat: true),
            Text(_selectedDate != null ? DateFormat('dd MMMM y').format(_selectedDate!) : "sales".tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        if (isLiveData && _lastUpdateTime != null) ...[
          const SizedBox(height: 4),
          Text("${"last".tr}: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}",
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 8),
        ..._buildDataRows(data['sales']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/payment.json', width: 30, height: 30, repeat: true),
          Text("payment".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['payment']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/orderType.json', width: 30, height: 30, repeat: true),
          Text("order_type".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['orderType']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/approval.json', width: 30, height: 30, repeat: true),
          Text("approval".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['approval']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/tax.json', width: 30, height: 30, repeat: true),
          Text("tax".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['tax']!),
        if (!isLiveData) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: orderHistory,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.green),
              child: Text('view_full'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: "Mulish", color: Colors.white)),
            ),
          )
        ]
      ],
    );
  }

  List<Widget> _buildDataRows(Map<String, String> data) {
    return data.entries.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: e.key, style: const TextStyle(color: Colors.black)),
            TextSpan(text: "   ${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    )).toList();
  }

  Map<String, Map<String, String>> _getLiveData() {
    return {
      'sales': {
        "total_sales".tr: totalSales,
        "total_order".tr: totalOrder,
        "total_tax".tr: totalTax,
        "cash_total".tr: cashTotal,
        "online".tr: online,
        "net_subtotal".tr: net,
        "discounts".tr: discount,
        "delivery_fee".tr: deliveryFee,
        "sale".tr: salesDelivery,
      },
      'payment': {"cash".tr: cashMethod},
      'orderType': {
        "delivery".tr: delivery,
        "pickup".tr: pickUp,
        "dine_in".tr: dineIn,
      },
      'approval': {
        "pending".tr: pending,
        "accepted".tr: accepted,
        "decline".tr: declined,
      },
      'tax': {"19": tax19, "7": tax7},
    };
  }

  Map<String, Map<String, String>> _getReportData(DailySalesReport? report) {
    if (report == null) return _getLiveData();

    return {
      'sales': {
        "total_sales".tr: formatAmount(report.totalSales ?? 0.0),
        "total_order".tr: '${(report.totalOrders ?? 0).toInt()}',
        "total_tax".tr: formatAmount(report.totalTax ?? 0.0),
        "cash_total".tr: formatAmount(report.cashTotal ?? 0.0),
        "online".tr: formatAmount(report.onlineTotal ?? 0.0),
        "net_subtotal".tr: formatAmount(report.data?.netTotal ?? 0.0),
        "discounts".tr: '${(report.data?.discountTotal ?? 0).toInt()}',
        "delivery_fee".tr: formatAmount(_toDouble(report.data?.deliveryTotal)),
        "sale".tr: formatAmount(report.data?.totalSalesDelivery ?? 0.0),
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
        "19": '${report.data?.taxBreakdown?.d19 ?? 0}',
        "7": '${report.data?.taxBreakdown?.d7 ?? 0}',
      },
    };
  }

  Widget _buildGenerateReportOptions() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'generate_report'.tr,
              style: const TextStyle(
                fontFamily: "Mulish",
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xff1F1E1E),
              ),
            ),
            const SizedBox(height: 12),
            if (_isGeneratingReport)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _reportOptionChip('today_option'.tr, () {
                    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    _callGenerateReport(today, today);
                  }),
                  _reportOptionChip('weekly'.tr, () {
                    final today = DateTime.now();
                    final from = today.subtract(const Duration(days: 7));
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(from),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('monthly_option'.tr, () {
                    final today = DateTime.now();
                    final from = DateTime(today.year, today.month - 1, today.day);
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(from),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('yearly'.tr, () {
                    final today = DateTime.now();
                    final from = DateTime(today.year - 1, today.month, today.day);
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(from),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('custom_range'.tr, () async {
                    final now = DateTime.now();
                    final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);

                    final dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: twoYearsAgo,
                      lastDate: now,
                      initialDateRange: DateTimeRange(
                        start: now.subtract(const Duration(days: 30)),
                        end: now,
                      ),
                      helpText: 'select_from_date'.tr,
                      saveText: 'OK',
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.green,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (dateRange == null || !mounted) return;

                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(dateRange.start),
                      DateFormat('yyyy-MM-dd').format(dateRange.end),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
      crossFadeState: _showGenerateOptions
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _reportOptionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.green, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Mulish",
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Future<void> _callGenerateReport(String fromDate, String toDate) async {
    setState(() => _isGeneratingReport = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

      final pdfBytes = await CallService().generateReport(
        fromDate: fromDate,
        toDate: toDate,
        storeId: storeId,
        language: 'De',
      );

      if (!mounted) return;
      setState(() => _isGeneratingReport = false);

      Get.to(() => PdfPreviewScreen(
        pdfBytes: Uint8List.fromList(pdfBytes),
        fromDate: fromDate,
        toDate: toDate,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'generate_error'.tr}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> orderHistory() async {
    final targetDate = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

    var map = {"store_id": storeId, "target_date": targetDate, "offset": 0};

    try {
      _showLoadingDialog();
      List<orderHistoryResponseModel> orders = await CallService().orderHistory(map);
      _closeDialog();

      app.appController.setHistoryOrders(orders);
      Get.to(() => OrderHistory(orders: orders, targetDate: targetDate));
    } catch (e) {
      _closeDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'during'.tr}: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
      );
    }
  }
}
