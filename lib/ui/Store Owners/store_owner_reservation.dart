import 'package:flutter/material.dart';
import 'package:food_receiver/constants/app_theme.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../api/repository/api_repository.dart';
import '../../models/get_all_reservation_for_all_store.dart';
import '../table Book/reservation_details.dart';

class StoreOwnerReservation extends StatefulWidget {
  const StoreOwnerReservation({super.key});

  @override
  State<StoreOwnerReservation> createState() => _StoreOwnerReservationState();
}

class _StoreOwnerReservationState extends State<StoreOwnerReservation> {
  bool isLoading = false;
  List<Stores> stores = [];
  int? total;
  DateTime selectedDate = DateTime.now();
  Stores? selectedStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getReservation();
    });
  }

  String get _formattedApiDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SingleDatePickerDialog(initialDate: selectedDate),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedStore = null;
      });
      getReservation();
    }
  }

  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
      selectedStore = null;
    });
    getReservation();
  }

  Map<String, Color> _storeColors(int? storeId) {
    switch (storeId) {
      case 12:
        return {'border': const Color(0xff029543), 'background': const Color(0xffEBFAF2), 'nameColor': const Color(0xff029543)};
      case 13:
        return {'border': const Color(0xffE4121E), 'background': const Color(0xffFCF6F7), 'nameColor': const Color(0xffE4121E)};
      case 14:
        return {'border': const Color(0xff841D1C), 'background': const Color(0xffF6EDED), 'nameColor': const Color(0xff841D1C)};
      case 15:
        return {'border': const Color(0xff023047), 'background': const Color(0xffFAFDFF), 'nameColor': const Color(0xff023047)};
      case 16:
        return {'border': const Color(0xff624BA1), 'background': const Color(0x0ffdfcff), 'nameColor': const Color(0xff624BA1)};
      case 18:
        return {'border': const Color(0xffE0D2AA), 'background': const Color(0xffFAF3E0), 'nameColor': const Color(0xffE64425)};
      case 19:
        return {'border': const Color(0xffF9CC46), 'background': const Color(0xffFDFAF1), 'nameColor': const Color(0xff029447)};
      case 20:
        return {'border': const Color(0xffE31E22), 'background': const Color(0xffFFDCDD), 'nameColor': const Color(0xffE31E22)};
      case 21:
        return {'border': const Color(0xff0D9488), 'background': const Color(0xffF0FDFA), 'nameColor': const Color(0xff0D9488)};
      case 22:
        return {'border': const Color(0xffEA580C), 'background': const Color(0xffFFF7ED), 'nameColor': const Color(0xffEA580C)};
      case 23:
        return {'border': const Color(0xff4338CA), 'background': const Color(0xffEEF2FF), 'nameColor': const Color(0xff4338CA)};
      case 24:
        return {'border': const Color(0xffDB2777), 'background': const Color(0xffFDF2F8), 'nameColor': const Color(0xffDB2777)};
      case 25:
        return {'border': const Color(0xff4D7C0F), 'background': const Color(0xffF7FEE7), 'nameColor': const Color(0xff4D7C0F)};
      case 26:
        return {'border': const Color(0xff0E7490), 'background': const Color(0xffECFEFF), 'nameColor': const Color(0xff0E7490)};
      case 27:
        return {'border': const Color(0xffBE123C), 'background': const Color(0xffFFF1F2), 'nameColor': const Color(0xffBE123C)};
      case 28:
        return {'border': const Color(0xffB45309), 'background': const Color(0xffFEF3C7), 'nameColor': const Color(0xffB45309)};
      case 29:
        return {'border': const Color(0xff047857), 'background': const Color(0xffECFDF5), 'nameColor': const Color(0xff047857)};
      case 30:
        return {'border': const Color(0xff6D28D9), 'background': const Color(0xffF5F3FF), 'nameColor': const Color(0xff6D28D9)};
      case 31:
        return {'border': const Color(0xff0369A1), 'background': const Color(0xffF0F9FF), 'nameColor': const Color(0xff0369A1)};
      case 32:
        return {'border': const Color(0xffA21CAF), 'background': const Color(0xffFDF4FF), 'nameColor': const Color(0xffA21CAF)};
      case 33:
        return {'border': const Color(0xff78350F), 'background': const Color(0xffFDF6EC), 'nameColor': const Color(0xff78350F)};
      case 34:
        return {'border': const Color(0xff475569), 'background': const Color(0xffF8FAFC), 'nameColor': const Color(0xff475569)};
      default:
        return {'border': const Color(0xffE0D2AA), 'background': Colors.white, 'nameColor': const Color(0xffE64425)};
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'booked':
        return AppTheme.accent;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isVorbestellen(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year != now.year ||
        date.month != now.month ||
        date.day != now.day;
  }

  List<MapEntry<Reservations, String>> get _currentReservations {
    if (selectedStore != null) {
      return (selectedStore!.reservations ?? [])
          .map((r) => MapEntry(r, selectedStore!.storeName ?? ''))
          .toList();
    }
    return stores
        .expand((s) => (s.reservations ?? <Reservations>[]).map((r) => MapEntry(r, s.storeName ?? '')))
        .toList();
  }

  // ── Same look as the Super Admin reservation screen ───────────────────
  Widget _pill(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String? status) {
    final color = _statusColor(status);
    final icon = status == 'booked'
        ? Icons.check_circle_rounded
        : status == 'pending'
            ? Icons.access_time_rounded
            : status == 'cancelled'
                ? Icons.cancel_rounded
                : Icons.help_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text((status ?? '-').capitalizeFirst ?? '-',
              style: TextStyle(fontFamily: 'Sora', color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  // "Today" / "Tomorrow", otherwise the full date.
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'day_today'.tr;
    if (days == 1) return 'day_tomorrow'.tr;
    return DateFormat('dd.MM.yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: back, title, date, total, refresh (pinned) ───
            Padding(
              padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 12, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.accentDark),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reservations',
                            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.accentDark)),
                        const SizedBox(height: 2),
                        Text(DateFormat('d MMMM, y').format(selectedDate),
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (!_isToday)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _pill(Icons.today_rounded, 'Today', onTap: _goToToday),
                            ),
                          _pill(Icons.history_rounded, 'History', onTap: _pickDate),
                        ],
                      ),
                      if (total != null) ...[
                        const SizedBox(height: 5),
                        _pill(Icons.event_note_rounded, 'Total: $total'),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  InkWell(onTap: getReservation, child: const Icon(Icons.refresh_rounded)),
                ],
              ),
            ),
            // ─── Store cards ───
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(7, 10, 7, 0),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  final colors = _storeColors(store.storeId);
                  final isSelected = selectedStore?.storeId == store.storeId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => selectedStore = isSelected ? null : store),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.36,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.accent : colors['border']!, width: isSelected ? 2 : 1.2),
                        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: colors['background'], borderRadius: BorderRadius.circular(6)),
                            child: Text('ID : ${store.storeId}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Sora', color: colors['nameColor'])),
                          ),
                          Text(store.storeName ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Sora', color: colors['nameColor'])),
                          Text('Total : ${store.total ?? 0}  •  Booked : ${store.booked ?? 0}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Sora')),
                          if ((store.pending ?? 0) > 0 || (store.cancelled ?? 0) > 0)
                            Text(
                                [
                                  if ((store.pending ?? 0) > 0) 'Pending : ${store.pending}',
                                  if ((store.cancelled ?? 0) > 0) 'Cancelled : ${store.cancelled}',
                                ].join('  •  '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Sora', color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedStore != null
                          ? '${selectedStore!.storeName}  •  ${_currentReservations.length} reservation'
                          : 'All stores  •  ${_currentReservations.length} reservation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Sora', fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (selectedStore != null)
                    _pill(Icons.layers_clear_rounded, 'Show All', onTap: () => setState(() => selectedStore = null)),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true))
                  : _currentReservations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset('assets/animations/empty.json', height: 150, width: 150),
                              const Text('No reservations found',
                                  style: TextStyle(fontFamily: 'Sora', color: Colors.black45, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: _currentReservations.length,
                          itemBuilder: (context, index) {
                            final entry = _currentReservations[index];
                            return _reservationCard(entry.key, entry.value);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationCard(Reservations res, String storeName) {
    final reservedFor = res.reservedFor != null ? DateTime.tryParse(res.reservedFor!) : null;
    final createdAt = res.createdAt != null ? DateTime.tryParse(res.createdAt!) : null;
    final name = (res.customerName ?? '').trim();

    return GestureDetector(
      onTap: () async {
        await Get.to(() => ReservationDetails(res.id.toString()));
        getReservation();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Reserved-for time block
                Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6D5DF6), Color(0xFF4F8DF7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(reservedFor == null ? '' : _dayLabel(reservedFor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(reservedFor == null ? '--:--' : DateFormat('HH:mm').format(reservedFor),
                          style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, height: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name.isEmpty ? '-' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.accentDark)),
                          ),
                          _statusChip(res.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(res.customerPhone ?? '',
                          style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black54)),
                      if (storeName.isNotEmpty)
                        Text(storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text('${res.guestCount ?? '-'}',
                              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.accentDark)),
                          const SizedBox(width: 14),
                          const Icon(Icons.tag_rounded, size: 15, color: Colors.black38),
                          Text('${res.id}', style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black54)),
                          const Spacer(),
                          const Icon(Icons.schedule_rounded, size: 14, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text(createdAt == null ? '--:--' : DateFormat('HH:mm').format(createdAt),
                              style: const TextStyle(fontFamily: 'Sora', fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isVorbestellen(reservedFor))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Vorbestellen',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Sora', fontSize: 11)),
                ),
              ),
            if (res.note != null && res.note!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_outlined, size: 13, color: Colors.black38),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(res.note!,
                          style: const TextStyle(fontSize: 11, fontFamily: 'Sora', color: Colors.black54, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> getReservation() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final model = await CallService().getAllReservationForStore(_formattedApiDate);

      if (!mounted) return;
      setState(() {
        stores = model.stores ?? [];
        total = model.total;
        selectedStore = null;
        isLoading = false;
      });
    } catch (e) {
      print('Error getting Store Owner Reservation: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      Get.snackbar('Error', 'Failed to load Reservations',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _SingleDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _SingleDatePickerDialog({required this.initialDate});

  @override
  State<_SingleDatePickerDialog> createState() => _SingleDatePickerDialogState();
}

class _SingleDatePickerDialogState extends State<_SingleDatePickerDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                Navigator.of(context).pop(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Sora',
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
