
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/DailySalesReport.dart';
import '../../models/reservation/get_history_reservation.dart';
import '../../utils/my_application.dart';

class ReportScreenBottom extends StatefulWidget {
  const ReportScreenBottom({super.key});

  @override
  _ReportScreenBottomState createState() => _ReportScreenBottomState();
}

class _ReportScreenBottomState extends State<ReportScreenBottom> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  List<DailySalesReport> reportList = [];
  DateTime? _selectedDate;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading=false;
  @override
  void initState() {
    super.initState();
    initVar();
    loadReservationCounts();
  }
  Map<String, int> reservationCounts = {};
  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
    });

    reservationHistory();
  }

  Future<void> loadReservationCounts() async {
    var reservations = app.appController.reservationsList;

    Map<String, int> counts = {};

    for (var reservation in reservations) {
      if (reservation.reservedFor != null) {
        try {
          // reserved_for को date में convert करें
          DateTime reservationDate = DateTime.parse(reservation.reservedFor!);
          String dateKey = DateFormat('yyyy-MM-dd').format(reservationDate);
          counts[dateKey] = (counts[dateKey] ?? 0) + 1;

          print("Reservation ${reservation.id} reserved for: $dateKey"); // Debug
        } catch (e) {
          print("Error parsing reserved_for date: ${reservation.reservedFor}, Error: $e");
        }
      }
    }

    print("Final reservation counts: $counts"); // Debug

    setState(() {
      reservationCounts = counts;
    });
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
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
        child: ListView(
          children: [
            _calendar(),
          ],
        ),
      ),
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

    final reportMap = _getReportsForMonth(month, year);
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
            const Text("Reservations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 40,color: Colors.green),
                  onPressed: () {
                    setState(() {
                      if (selectedMonth == 1) {
                        selectedMonth = 12;
                        selectedYear--;
                      } else {
                        selectedMonth--;
                      }
                    });
                    loadReservationCounts();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 40,color: Colors.green),
                  onPressed: () {
                    setState(() {
                      if (selectedMonth == 12) {
                        selectedMonth = 1;
                        selectedYear++;
                      } else {
                        selectedMonth++;
                      }
                    });
                    loadReservationCounts();
                  },
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ),
                    ),
                    TextSpan(
                      text: year.toString(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text('${'total_reserv'.tr} : $totalReservationsForMonth',style: const TextStyle(
                fontFamily: 'Mulish',fontSize: 15,fontWeight: FontWeight.w600
              ),)
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
                  final report = isCurrentMonth ? reportMap[cellDate.day] : null;

                  return _calendarCellWithDate(cellDate, report, isCurrentMonth);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _calendarCellWithDate(DateTime date, DailySalesReport? report, bool isCurrentMonth) {
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
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 2),

              // Sales report (existing)
              if (report != null)
                GestureDetector(
                  onTap: () => showCalendarDialog(
                    context,
                    report,
                    DateFormat('yyyy-MM-dd').format(date),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/ic_report_dialog.svg',
                        height: 12,
                        width: 12,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${"currency".tr}${formatAmount(report.totalSales ?? 0)}",
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ],
                  ),
                ),

              // Booking count (new)
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
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showCalendarDialog(BuildContext context, DailySalesReport report, String day) {
    final DateTime parsedDate = DateTime.parse(report.startDate!);

  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> reservationHistory() async {
    setState(() {
      isLoading = true;
    });

    // Use selected date from calendar
    String targetDate;
    if (_selectedDate != null) {
      targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else {
      targetDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storeIdString = prefs.getString(valueShared_STORE_KEY);
    int storeId;

    if (storeIdString != null && storeIdString.isNotEmpty) {
      storeId = int.tryParse(storeIdString) ?? 13;
    } else {
      storeId = 13;
      print("Warning: Store ID not found in SharedPreferences, using default: 13");
    }

    var map = {
      "store_id": storeId,
      "target_date": targetDate,
      "offset": 0
    };

    print("Getting History Map Value Is $map");

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );

      List<GetHistoryReservationResponseModel> orders = await CallService().reservationHistory(map);

      print('Number of orders received: ${orders.length}');

      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (_selectedDate != null) {
        String displayDate = DateFormat('d MMMM, y').format(_selectedDate!);
        Navigator.of(context).pop(displayDate);
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'gett_history'.tr}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('Getting History error: $e');
    }
  }

}

