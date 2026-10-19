import 'dart:typed_data';
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
import '../../Order_history/order_history.dart';
import '../../Report/PdfPreviewScreen.dart';
import '../../Report/ReportScreen.dart' show CustomDateRangeDialog;
import 'package:food_receiver/constants/app_theme.dart';

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
          const SnackBar(content: Text('Store ID not found', style: const TextStyle(fontFamily: 'Sora'))),
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
          SnackBar(content: Text('Failed to load report: $e', style: const TextStyle(fontFamily: 'Sora'))),
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
    return AppGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
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
            _buildGenerateReportOptions(),
            if (showCalendar) ...[
              _calendar(),
              const SizedBox(height: 16),
            ],
            showCalendar && _selectedDate != null
                ? _buildDailyReportStatus(_selectedDailyReport)
                : !showCalendar && !_showGenerateOptions
                ? _buildMonthlyReportStatus(storeReport)
                : const SizedBox.shrink(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  }


  // ─── Generate PDF report (same as ReportScreen) ───
  Widget _buildGenerateReportOptions() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'generate_report'.tr,
              style: const TextStyle(
                fontFamily: 'Sora',
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
                  child: CircularProgressIndicator(color: AppTheme.accent),
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
                    final monday = today.subtract(Duration(days: today.weekday - 1));
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(monday),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('monthly_option'.tr, () {
                    final today = DateTime.now();
                    final firstOfMonth = DateTime(today.year, today.month, 1);
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(firstOfMonth),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('yearly'.tr, () {
                    final today = DateTime.now();
                    final firstOfYear = DateTime(today.year, 1, 1);
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(firstOfYear),
                      DateFormat('yyyy-MM-dd').format(today),
                    );
                  }),
                  _reportOptionChip('custom_range'.tr, () async {
                    final result = await _showCustomDateRangePicker();
                    if (result == null || !mounted) return;
                    _callGenerateReport(
                      DateFormat('yyyy-MM-dd').format(result['start']!),
                      DateFormat('yyyy-MM-dd').format(result['end']!),
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
          border: Border.all(color: AppTheme.accent, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }

  Future<Map<String, DateTime>?> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);

    return showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: CustomDateRangeDialog(
            firstDate: twoYearsAgo,
            lastDate: now,
          ),
        );
      },
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
          content: Text('${'generate_error'.tr}: $e', style: const TextStyle(fontFamily: 'Sora')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
                style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildDataRows(data['sales']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/payment.json',
              width: 30, height: 30, repeat: true),
          Text("payment".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['payment']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/orderType.json',
              width: 30, height: 30, repeat: true),
          Text("order_type".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['orderType']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/approval.json',
              width: 30, height: 30, repeat: true),
          Text("approval".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['approval']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/tax.json',
              width: 30, height: 30, repeat: true),
          Text("tax".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
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
        //         borderRadius: BorderRadius.circular(5), color: AppTheme.accent),
        //     child: Center(
        //       child: Text('view_full'.tr,
        //           style: TextStyle(
        //               fontWeight: FontWeight.w600,
        //               fontSize: 14,
        //               fontFamily: 'Sora',
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
                  style: TextStyle(fontFamily: 'Sora', 
                      fontWeight: FontWeight.bold,
                      color: isCurrentMonth ? Colors.black : Colors.grey[600])),
              const SizedBox(height: 2),
              if (dailyReport != null) ...[
                SvgPicture.asset('assets/images/ic_report.svg', height: 12, width: 12),
                const SizedBox(height: 2),
                Text("${"currency".tr}${formatAmount(dailyReport.totalSales ?? 0)}",
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 10, color: AppTheme.accent)),
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
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14),
            ),
            _isCalculatingTotal
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            )
                : Text(
              '${"currency".tr} ${formatAmount(_monthTotalSales)}',
              style: const TextStyle(fontFamily: 'Sora', 
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.accent,
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
                  Text(storeName ?? 'Store Report',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Sora',
                          color: AppTheme.accent)),
                  Positioned(
                    right: -11,
                    top: 0,
                    child: FadeTransition(
                      opacity: _animation,
                      child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: AppTheme.accent, shape: BoxShape.circle)),
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
                    fontFamily: 'Sora'),
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
                _selectedDailyReport = null;
                _selectedDate = null;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showGenerateOptions ? AppTheme.accent : AppTheme.accentLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 16, color: _showGenerateOptions ? Colors.white : AppTheme.accent),
                const SizedBox(width: 4),
                Text(
                  'report_btn'.tr,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _showGenerateOptions ? Colors.white : AppTheme.accent,
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
                _selectedDate = null;
                _resetCalendarToCurrentMonth();
              }
            });
          },
          child: Row(
            children: [
              Text('history'.tr,
                  style: const TextStyle(
                      fontFamily: 'Sora',
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
                style: const TextStyle(fontFamily: 'Sora', 
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
                const TextStyle(color: Colors.black, fontFamily: 'Sora')),
            TextSpan(
                text: "   ${e.value}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    fontFamily: 'Sora')),
          ],
        ),
      ),
    ))
        .toList();
  }

  Map<String, Map<String, String>> _getMonthlyReportData(Report report) {
    return {
      'sales': {
        "total_sales".tr: '${"currency".tr} ${formatAmount(report.totalSales ?? 0.0)}',
        "total_order".tr: '${report.totalOrders ?? 0}',
        "total_tax".tr: '${"currency".tr} ${formatAmount(report.totalTax ?? 0.0)}',
        "cash_total".tr: '${"currency".tr} ${formatAmount(report.cashTotal ?? 0.0)}',
        "online".tr: '${"currency".tr} ${formatAmount(report.onlineTotal ?? 0.0)}',
        "net_subtotal".tr: '${"currency".tr} ${formatAmount(report.netTotal ?? 0.0)}',
        "discounts".tr: '${"currency".tr} ${formatAmount(report.discountTotal ?? 0.0)}',
        "delivery_fee".tr: '${"currency".tr} ${formatAmount(report.deliveryTotal ?? 0.0)}',
        "sale".tr: '${"currency".tr} ${formatAmount(report.totalSalesDelivery ?? 0.0)}',
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
        "19%": '${"currency".tr} ${formatAmount(report.taxBreakdown?.d19 ?? 0.0)}',
        "7%": '${"currency".tr} ${formatAmount(report.taxBreakdown?.d7 ?? 0.0)}',
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
            content: Text('Failed to load order history: $e', style: const TextStyle(fontFamily: 'Sora')),
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

      print('💰 Total calculated: ${"currency".tr}$total from $reportCount reports');

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
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildDataRows(data['sales']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/payment.json',
              width: 30, height: 30, repeat: true),
          Text("payment".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['payment']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/orderType.json',
              width: 30, height: 30, repeat: true),
          Text("order_type".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['orderType']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/approval.json',
              width: 30, height: 30, repeat: true),
          Text("approval".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ..._buildDataRows(data['approval']!),
        const SizedBox(height: 12),
        Row(children: [
          Lottie.asset('assets/animations/tax.json',
              width: 30, height: 30, repeat: true),
          Text("tax".tr,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16)),
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
                borderRadius: BorderRadius.circular(5), color: AppTheme.accent),
            child: Center(
              child: Text('view_full'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Sora',
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
          "total_sales".tr: '${"currency".tr} 0.00',
          "total_order".tr: '0',
          "total_tax".tr: '${"currency".tr} 0.00',
          "cash_total".tr: '${"currency".tr} 0.00',
          "online".tr: '${"currency".tr} 0.00',
          "net_subtotal".tr: '${"currency".tr} 0.00',
          "discounts".tr: '0',
          "delivery_fee".tr: '${"currency".tr} 0.00',
          "sale".tr: '${"currency".tr} 0.00',
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
          "19%": '${"currency".tr} 0.00',
          "7%": '${"currency".tr} 0.00',
        },
      };
    }

    return {
      'sales': {
        "total_sales".tr: '${"currency".tr} ${formatAmount(report.totalSales ?? 0.0)}',
        "total_order".tr: '${report.totalOrders ?? 0}',
        "total_tax".tr: '${"currency".tr} ${formatAmount(report.totalTax ?? 0.0)}',
        "cash_total".tr: '${"currency".tr} ${formatAmount(report.cashTotal ?? 0.0)}',
        "online".tr: '${"currency".tr} ${formatAmount(report.onlineTotal ?? 0.0)}',
        "net_subtotal".tr: '${"currency".tr} ${formatAmount(report.data?.netTotal ?? 0.0)}',
        "discounts".tr: '${(report.data?.discountTotal ?? 0).toInt()}',
        "delivery_fee".tr: '${"currency".tr} ${formatAmount(report.data?.deliveryTotal?.toDouble() ?? 0.0)}',
        "sale".tr: '${"currency".tr} ${formatAmount(report.data?.totalSalesDelivery ?? 0.0)}',
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
        "19%": '${"currency".tr} ${formatAmount(report.data?.taxBreakdown?.d19 ?? 0.0)}',
        "7%": '${"currency".tr} ${formatAmount(report.data?.taxBreakdown?.d7 ?? 0.0)}',
      },
    };
  }

}
