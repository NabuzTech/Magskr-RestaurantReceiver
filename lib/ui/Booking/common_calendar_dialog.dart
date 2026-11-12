import 'package:flutter/material.dart';

import '../../api/repository/api_repository.dart';

/// Custom calendar date-picker dialog, ported from the sibling Restaurant
/// Receiver app's reservation calendar so every date picker in this app
/// looks and behaves the same (with booking-day dots) instead of the
/// default Material [showDatePicker].
class CommonCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CommonCalendarDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CommonCalendarDialog> createState() => _CommonCalendarDialogState();
}

class _CommonCalendarDialogState extends State<CommonCalendarDialog> {
  static const Color primaryGreen = Color(0xFFFF5E18);

  late int _month;
  late int _year;
  Map<int, int> _bookingCounts = {}; // day → number of bookings
  final Map<String, Map<int, int>> _monthCache = {};

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
    _loadMonthBookings();
  }

  Future<void> _loadMonthBookings() async {
    final requestedYear = _year;
    final requestedMonth = _month;
    final key = '$requestedYear-$requestedMonth';
    final cached = _monthCache[key];
    if (cached != null) {
      if (mounted) setState(() => _bookingCounts = cached);
      return;
    }

    final Map<int, int> days;
    try {
      days = await CallService().getMonthBookingCountsV2(requestedYear, requestedMonth);
    } catch (_) {
      return; // not cached, so reopening the month retries
    }
    _monthCache[key] = days;
    if (mounted && _year == requestedYear && _month == requestedMonth) {
      setState(() => _bookingCounts = days);
    }
  }

  bool _inRange(DateTime d) {
    if (widget.firstDate != null &&
        d.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month, widget.firstDate!.day))) {
      return false;
    }
    if (widget.lastDate != null &&
        d.isAfter(DateTime(widget.lastDate!.year, widget.lastDate!.month, widget.lastDate!.day))) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_year, _month, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(_year, _month + 1, 0).day;
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      if (_month == 1) {
                        _month = 12;
                        _year--;
                      } else {
                        _month--;
                      }
                      _bookingCounts = {};
                    });
                    _loadMonthBookings();
                  },
                ),
                Text('${_monthNames[_month]} $_year',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      if (_month == 12) {
                        _month = 1;
                        _year++;
                      } else {
                        _month++;
                      }
                      _bookingCounts = {};
                    });
                    _loadMonthBookings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekLabels
                  .map((d) => Expanded(
                      child: Center(
                          child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))))
                  .toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate(totalCells ~/ 7, (week) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = week * 7 + dayIndex;
                  final day = cellIndex - startWeekday + 1;
                  final isCurrentMonth = day >= 1 && day <= totalDays;
                  final cellDate = isCurrentMonth ? DateTime(_year, _month, day) : null;
                  final enabled = cellDate != null && _inRange(cellDate);
                  final isSelected = cellDate != null &&
                      cellDate.year == widget.initialDate.year &&
                      cellDate.month == widget.initialDate.month &&
                      cellDate.day == widget.initialDate.day;
                  final isToday = cellDate != null &&
                      cellDate.year == today.year &&
                      cellDate.month == today.month &&
                      cellDate.day == today.day;
                  final bookingCount = isCurrentMonth ? (_bookingCounts[day] ?? 0) : 0;
                  final hasBooking = bookingCount > 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: enabled ? () => Navigator.pop(context, cellDate) : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen : null,
                          border: isToday && !isSelected
                              ? Border.all(color: primaryGreen)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: hasBooking
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white24
                                        : primaryGreen.withOpacity(.12),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : primaryGreen,
                                      width: 1.5,
                                    ),
                                  )
                                : null,
                            child: Text(
                              isCurrentMonth ? '$day' : '',
                              style: TextStyle(
                                color: !enabled
                                    ? Colors.black26
                                    : (isSelected
                                        ? Colors.white
                                        : (hasBooking ? primaryGreen : Colors.black87)),
                                fontWeight: isToday || isSelected || hasBooking
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                              if (hasBooking)
                                Positioned(
                                  top: -6,
                                  right: -8,
                                  child: bookingCountBadge(bookingCount, primaryGreen),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Small "number of bookings" badge on a calendar day (shared with History)
Widget bookingCountBadge(int count, Color color) {
  return Container(
    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white, width: 1),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Convenience wrapper matching [showDatePicker]'s call shape.
Future<DateTime?> showCommonCalendarDialog({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => CommonCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
