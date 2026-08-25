import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/Reservation V2/get_reservation_of_store_byDate.dart';
import '../../models/Reservation V2/get_today_reservation_V2_of_store.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/Reservation V2/get_today_slot_reservationV2.dart';

import '../../utils/my_application.dart';
import 'reservation_settings_screen.dart';
class ReservationDashboardV2 extends StatefulWidget {
  const ReservationDashboardV2({super.key});

  @override
  State<ReservationDashboardV2> createState() => _ReservationDashboardV2State();
}

class _ReservationDashboardV2State extends State<ReservationDashboardV2> {
  bool isLoading=false;
  List<Reservations>? reservationsData=[];
  List<Reservations>? receivedReservationsData=[];
  int _bookingTabIndex = 0;
  Summary? summary;
  GetTodaySlotOfReservation? timeSlotData;
  DateTime _selectedDate = DateTime.now();
  String? storeID;
  Worker? _syncWorker;
  int? _highlightedReservationId;
  Color? _highlightedColor;
  final ScrollController _coversScrollController = ScrollController();
  final Map<int, GlobalKey> _slotKeys = {};
  Timer? _slotClockTimer;
  OverlayEntry? _bookingOverlay;

  static const List<Color> _bookingColors = [
    Color(0xFF3B82F6), // blue
    Color(0xFF14B8A6), // teal
    Color(0xFFF59E0B), // orange
    Color(0xFF16A34A), // green
    Color(0xFF6366F1), // indigo
    Color(0xFFEF4444), // red
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayReservations();
    _syncWorker = ever(app.appController.syncTimeUpdated, (_) => _refreshForNotification());
    _slotClockTimer = Timer.periodic(const Duration(minutes: 1), (_) => _scrollToCurrentSlot());
  }

  @override
  void dispose() {
    _syncWorker?.dispose();
    _slotClockTimer?.cancel();
    _coversScrollController.dispose();
    _dismissBookingPopup();
    super.dispose();
  }

  Future<void> _loadTodayReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(valueShared_STORE_KEY);
    if (id == null || id.isEmpty) return;
    storeID = id;
    await Future.wait([
      getReservationV2(id),
      getTodayReceivedReservationV2(id, showLoader: false),
      getTodayTimeSlot(id, showLoader: false),
    ]);
  }

  void _refreshForNotification() {
    final id = storeID;
    if (id == null) return;
    if (_isSameDay(_selectedDate, DateTime.now())) {
      getReservationV2(id, showLoader: false);
    } else {
      reservationV2History(showLoader: false);
    }
    getTodayReceivedReservationV2(id, showLoader: false);
    getTodayTimeSlot(id, showLoader: false);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openCalendar() async {
    final id = storeID;
    if (id == null) return;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _ReservationCalendarDialog(initialDate: _selectedDate, storeId: id),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    if (_isSameDay(picked, DateTime.now())) {
      await Future.wait([
        getReservationV2(id, showLoader: true),
        getTodayTimeSlot(id, showLoader: false),
      ]);
    } else {
      await Future.wait([
        reservationV2History(),
        getTodayTimeSlot(id, showLoader: false),
      ]);
    }
  }

  Widget _todayChip() {
    return GestureDetector(
      onTap: _goToToday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today, size: 14, color: Colors.blue),
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
    );
  }

  Future<void> _goToToday() async {
    final id = storeID;
    if (id == null) return;
    setState(() => _selectedDate = DateTime.now());
    await Future.wait([
      getReservationV2(id, showLoader: true),
      getTodayReceivedReservationV2(id, showLoader: false),
      getTodayTimeSlot(id, showLoader: false),
    ]);
  }

  void _openReservationSettings() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ReservationSettingsScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: ()=> _loadTodayReservations(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              _dismissBookingPopup();
            }
            return false;
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: false,
                snap: false,
                pinned: true,
                elevation: 1,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('reserv'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openCalendar,
                          child: Row(
                            children: [
                              Text(_todayLabel(),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                        if (!_isSameDay(_selectedDate, DateTime.now())) ...[
                          const SizedBox(width: 8),
                          _todayChip(),
                        ],
                      ],
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _loadTodayReservations(),
                        child: const Icon(Icons.refresh_rounded, color: Colors.green),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: GestureDetector(
                        onTap: _openReservationSettings,
                        child: const Icon(Icons.settings_rounded, color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: _todaysOverviewCard(),
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _coversFilledCard(),
                  const SizedBox(height: 12),
                  _todaysBookingsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- CARD WRAPPER --------------------
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, {String? subtitle, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle,
                      style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // -------------------- TODAY'S OVERVIEW --------------------
  Widget _todaysOverviewCard() {
    final total = summary?.total ?? 0;
    final booked = summary?.booked ?? 0;
    final pending = summary?.pending ?? 0;
    final cancelled = summary?.cancelled ?? 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('todays_overview'.tr, subtitle: _todayLabel()),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _DonutPainter(
                    total: total,
                    booked: booked,
                    pending: pending,
                    cancelled: cancelled,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$total',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('tables_label'.tr,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(const Color(0xFF16A34A), 'booked_label'.tr, booked),
                    const SizedBox(height: 8),
                    _legendRow(const Color(0xFFF59E0B), 'pending'.tr, pending),
                    const SizedBox(height: 8),
                    _legendRow(const Color(0xFFEF4444), 'cancelled_label'.tr, cancelled),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    return DateFormat('EEE, d MMMM yyyy').format(_selectedDate);
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (e) {
      return '--:--';
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (e) {
      return '-';
    }
  }

  Widget _legendRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13))),
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'booked':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(label),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // -------------------- COVERS FILLED --------------------
  // A booking occupies every slot its [reservedFor, reservedUntil) window overlaps,
  // not just its start slot — a 16:00 booking lasting 60 min still holds the table
  // at 16:30, so it must still show up in that slot's bar.
  Map<String, List<_SlotBooking>> _bucketBySlot(List<Slots> slots, List<Reservations> list) {
    final sorted = [...list]
      ..sort((a, b) => (a.reservedFor ?? '').compareTo(b.reservedFor ?? ''));
    final Map<String, List<_SlotBooking>> map = {};
    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final start = DateTime.tryParse(r.reservedFor ?? '');
      if (start == null) continue;
      final end = DateTime.tryParse(r.reservedUntil ?? '') ??
          start.add(Duration(minutes: r.durationMinutes ?? 0));
      final color = (r.status ?? '').toLowerCase() == 'cancelled'
          ? _statusColor(r.status)
          : _bookingColors[i % _bookingColors.length];
      for (final slot in slots) {
        final slotDt = _slotDateTime(slot);
        if (slotDt == null) continue;
        if (!slotDt.isBefore(start) && slotDt.isBefore(end)) {
          map.putIfAbsent(slot.time ?? '', () => []).add(_SlotBooking(r, color));
        }
      }
    }
    return map;
  }

  DateTime? _slotDateTime(Slots slot) {
    final fromDatetime = DateTime.tryParse(slot.datetime ?? '')?.toLocal();
    if (fromDatetime != null) return fromDatetime;
    final parts = (slot.time ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, h, m);
  }

  void _scrollToCurrentSlot() {
    if (!_isSameDay(_selectedDate, DateTime.now())) return;
    final slots = timeSlotData?.slots;
    if (slots == null || slots.isEmpty) return;
    final now = DateTime.now();
    int bestIndex = 0;
    Duration bestDiff = const Duration(days: 9999);
    for (int i = 0; i < slots.length; i++) {
      final dt = _slotDateTime(slots[i]);
      if (dt == null) continue;
      final diff = dt.difference(now).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_coversScrollController.hasClients ||
          _coversScrollController.position.isScrollingNotifier.value) {
        return;
      }
      final renderObject = _slotKeys[bestIndex]?.currentContext?.findRenderObject();
      if (renderObject != null) {
        // Scoped to _coversScrollController's own position only — the static
        // Scrollable.ensureVisible walks every ancestor Scrollable, including
        // the outer page scroll, which was yanking the whole screen up.
        _coversScrollController.position.ensureVisible(
          renderObject,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  void _nudgeScroll(double direction) {
    if (!_coversScrollController.hasClients) return;
    final target = (_coversScrollController.offset + direction * 160)
        .clamp(0.0, _coversScrollController.position.maxScrollExtent);
    _coversScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _coversFilledCard() {
    final slots = timeSlotData?.slots ?? [];
    final buckets = _bucketBySlot(slots, reservationsData ?? []);
    final seenBookingIds = <int?>{};
    final allBookings = buckets.values.expand((e) => e).where((b) {
      final id = b.reservation.id;
      if (id != null && !seenBookingIds.add(id)) return false;
      return true;
    }).toList()
      ..sort((a, b) => (a.reservation.reservedFor ?? '')
          .compareTo(b.reservation.reservedFor ?? ''));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('covers_filled'.tr,
              subtitle: '${reservationsData?.length ?? 0} ${'bookings_count_label'.tr}'),
          const SizedBox(height: 16),
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('no_time_slots_for_date'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else ...[
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _nudgeScroll(-1),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _coversScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(4),
                    child: SingleChildScrollView(
                      controller: _coversScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: slots
                            .asMap()
                            .entries
                            .map((e) => _slotColumn(e.key, e.value, buckets[e.value.time] ?? []))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _nudgeScroll(1),
                ),
              ],
            ),
            if (allBookings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: allBookings.map(_legendChip).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _slotColumn(int index, Slots slot, List<_SlotBooking> bookings) {
    const segmentHeight = 22.0;
    return Padding(
      key: _slotKeys.putIfAbsent(index, () => GlobalKey()),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${bookings.length}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (bookings.isEmpty)
            Container(width: 26, height: 4, color: const Color(0xFFE5E7EB))
          else
            Column(
              children: bookings
                  .map((b) => GestureDetector(
                        onTapDown: (details) =>
                            _showBookingPopup(b.reservation, b.color, details.globalPosition),
                        child: Container(
                          width: 26,
                          height: segmentHeight,
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(color: b.color),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 6),
          Text(slot.time ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _legendChip(_SlotBooking b) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('${b.reservation.customerName ?? '-'}  ${_formatTime(b.reservation.reservedFor)}',
            style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  void _showBookingPopup(Reservations r, Color color, Offset tapPosition) {
    _dismissBookingPopup();
    setState(() {
      _highlightedReservationId = r.id;
      _highlightedColor = color;
    });

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const cardWidth = 220.0;
    double left = tapPosition.dx - cardWidth / 2;
    left = left.clamp(12.0, screenSize.width - cardWidth - 12);
    double top = tapPosition.dy + 12;
    if (top + 160 > screenSize.height) top = tapPosition.dy - 172;

    _bookingOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismissBookingPopup,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: _bookingPopupCard(r, color),
          ),
        ],
      ),
    );
    overlay.insert(_bookingOverlay!);
  }

  void _showTopSnackBar(String message,
      {required Color backgroundColor, required Color textColor}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopSnackBar(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _dismissBookingPopup() {
    _bookingOverlay?.remove();
    _bookingOverlay = null;
    if (mounted && _highlightedReservationId != null) {
      setState(() {
        _highlightedReservationId = null;
        _highlightedColor = null;
      });
    }
  }

  Widget _bookingPopupCard(Reservations r, Color color) {
    final start = _formatTime(r.reservedFor);
    final duration = r.durationMinutes ?? 0;
    final end = _addMinutes(r.reservedFor, duration);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withOpacity(0.12), Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.4),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.customerName ?? '-',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Icon(Icons.calendar_month, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            _popupRow(Icons.access_time, '$start – $end  ·  $duration min', color),
            const SizedBox(height: 8),
            _popupRow(Icons.people_outline, '${r.partySize ?? 0} ${'guests'.tr}', color),
            const SizedBox(height: 8),
            _popupRow(Icons.schedule, _titleCase(r.status ?? '-'), color),
            if (!['pending', 'cancelled'].contains((r.status ?? '').toLowerCase())) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _dismissBookingPopup();
                    _showEditReservationDialog(r);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('edit_booking'.tr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _popupRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _addMinutes(String? iso, int minutes) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).add(Duration(minutes: minutes));
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _bookingTabsRow() {
    return Row(
      children: [
        _bookingTab('today_booking'.tr, 0),
        const SizedBox(width: 16),
        _bookingTab('today_received_booking'.tr, 1),
      ],
    );
  }

  Widget _bookingTab(String label, int index) {
    final selected = _bookingTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bookingTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            )),
      ),
    );
  }

  // -------------------- TODAY'S BOOKINGS --------------------
  Widget _todaysBookingsCard() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final bookings = isToday && _bookingTabIndex == 1
        ? (receivedReservationsData ?? [])
        : (reservationsData ?? []);
    final calendarActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isToday) ...[
          _todayChip(),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined,
              size: 20, color: Colors.green),
          onPressed: _openCalendar,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isToday)
            Row(
              children: [
                Expanded(child: _bookingTabsRow()),
                calendarActions,
              ],
            )
          else
            _cardTitle(_todayLabel(), trailing: calendarActions),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('no_bookings_today'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            SlidableAutoCloseBehavior(
              child: Column(
                children: [
                  for (final booking in bookings) ...[
                    _bookingSlidable(booking),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingSlidable(Reservations booking) {
    final status = (booking.status ?? '').toLowerCase();
    final canEdit = status != 'pending' && status != 'cancelled';
    if (!canEdit) return _bookingTile(booking);

    return Slidable(
      key: ValueKey('booking_${booking.id}_${booking.reservedFor}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.28,
        children: [
          GestureDetector(
            onTap: () {
              Slidable.of(context)?.close();
              _showEditReservationDialog(booking);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text('edit_booking'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      child: _bookingTile(booking),
    );
  }

  Widget _bookingTile(Reservations booking) {
    final isHighlighted =
        booking.id != null && booking.id == _highlightedReservationId;
    final highlightColor = _highlightedColor ?? const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Color.alphaBlend(highlightColor.withOpacity(0.08), Colors.white)
            : Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: Border.all(
          color: isHighlighted
              ? highlightColor
              : const Color(0xFFE5E7EB),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TOP : TIME + STATUS
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6,),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatTime(booking.reservedFor),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  booking.customerName ?? 'Unknown Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),


              _statusChip(_titleCase(booking.status ?? '-')),
            ],
          ),

          const SizedBox(height: 7),

          /// BOOKING INFO
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _bookingInfoItem(
                  icon: Icons.people_outline_rounded,
                  label: 'guests'.tr,
                  value: '${booking.partySize ?? 0}',
                ),
                SizedBox(width: 10,),
                Container(
                  height: 30,
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                ),
                SizedBox(width: 10,),
                _bookingInfoItem(
                  icon: Icons.timer_outlined,
                 // label: 'duration_label'.tr,
                  value: '${booking.durationMinutes ?? 0} ${'min_unit'.tr}',
                ),
                Expanded(
                  child: Text(
                    _formatDate(booking.reservedFor),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 6),

          /// ACTION BUTTON(S)
          if ((booking.status ?? '').toLowerCase() == 'pending')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: booking.id == null
                          ? null
                          : () => updateReservationV2(booking.id.toString(), 'booked'),
                      icon: const Icon(Icons.check_circle_outline, size: 17),
                      label: Text(
                        'accept'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: booking.id == null
                          ? null
                          : () => updateReservationV2(booking.id.toString(), 'cancelled'),
                      icon: const Icon(Icons.cancel_outlined, size: 17),
                      label: Text(
                        'decline'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bookingInfoItem({
    required IconData icon,
    String?label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> getReservationV2(String storeID,{bool showLoader = true}) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
        Get.dialog(
          Center(
              child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      }
      GetTodayReservationV2OfStore reservation= await CallService().getTodayReservationV2(storeID);
      setState(() {
        summary = reservation.summary;
        reservationsData = (reservation.reservations ?? [])
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        isLoading = false;
        print('Today Reservation V2: ${reservationsData!.length}');
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    } catch (e) {
      print('Error getting Today Reservation V2: $e');
      setState(() {
        isLoading = false;
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    }
  }

  Future<void> getTodayReceivedReservationV2(String storeID, {bool showLoader = true}) async {
    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
        Get.dialog(
          Center(
              child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      }
      GetTodayReservationV2OfStore received =
          await CallService().getTodayReceivedReservationV2(storeID);
      setState(() {
        receivedReservationsData = (received.reservations ?? [])
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        print('Today Received Reservation V2: ${receivedReservationsData!.length}');
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    } catch (e) {
      print('Error getting Today Received Reservation V2: $e');
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    }
  }

  Summary _summaryFromReservations(List<Reservations> list) {
    int booked = 0, pending = 0, cancelled = 0;
    for (final r in list) {
      switch ((r.status ?? '').toLowerCase()) {
        case 'booked':
          booked++;
          break;
        case 'pending':
          pending++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }
    return Summary(total: list.length, booked: booked, pending: pending, cancelled: cancelled);
  }

  Future<void> reservationV2History({bool showLoader = true}) async {
    setState(() {
      isLoading = true;
    });

    final targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storeIdString = prefs.getString(valueShared_STORE_KEY);
    final storeId = storeIdString != null && storeIdString.isNotEmpty
        ? int.tryParse(storeIdString)
        : null;

    if (storeId == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('store_not_found'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var map = {
      "store_id": storeId,
      "target_date": targetDate,
      "offset": 0
    };

    print("Getting History Map Value Is $map");

    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
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
      }

      List<GetReservationV2OfStoreByDate> orders = await CallService().getReservationV2History(map);

      print('Number of orders received: ${orders.length}');

      final mapped = orders
          .map((e) => Reservations(
                id: e.id,
                storeId: e.storeId,
                partySize: e.partySize,
                reservedFor: e.reservedFor,
                reservedUntil: e.reservedUntil,
                durationMinutes: e.durationMinutes,
                status: e.status,
                customerName: e.customerName,
                customerPhone: e.customerPhone,
                customerEmail: e.customerEmail,
                note: e.note,
                createdAt: e.createdAt,
              ))
          .toList()
        ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

      setState(() {
        reservationsData = mapped;
        summary = _summaryFromReservations(mapped);
        isLoading = false;
      });

      if (showLoader && (Get.isDialogOpen ?? false)) {
        Navigator.of(Get.overlayContext!).pop();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (showLoader && (Get.isDialogOpen ?? false)) {
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

  Future<void> getTodayTimeSlot(String storeID,{bool showLoader = true}) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
        Get.dialog(
          Center(
              child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      GetTodaySlotOfReservation timeSlot= await CallService().gettingTimeSlotReservationV2(storeID, dateStr);
      _slotKeys.clear();
      setState(() {
        timeSlotData = timeSlot;
        isLoading = false;
        print('Time Slot Reservation V2: ${timeSlotData?.slots?.length ?? 0} slots');
      });
      _scrollToCurrentSlot();
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    } catch (e) {
      print('Error getting Time Slot V2: $e');
      setState(() {
        isLoading = false;
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    }
  }

  Future<void> updateReservationV2(String reservationId, String status) async {
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

    try {
      final body = {"status": status};
      await CallService().updateReservationV2(body, reservationId);

      if (Get.isDialogOpen ?? false) Get.back();

      // Update the local lists right away so the status chip/buttons flip
      // instantly instead of waiting on the refetch below to land.
      final numericId = int.tryParse(reservationId);
      if (numericId != null && mounted) {
        setState(() {
          for (final r in [...?reservationsData, ...?receivedReservationsData]) {
            if (r.id == numericId) r.status = status;
          }
        });
      }

      if (mounted) {
        final isDeclined = status != 'booked';
        _showTopSnackBar(
          isDeclined ? 'booking_declined'.tr : 'booking_accepted'.tr,
          backgroundColor: isDeclined ? const Color(0xFFFEE2E2) : const Color(0xFF16A34A),
          textColor: isDeclined ? const Color(0xFFB91C1C) : Colors.white,
        );
      }

      final id = storeID;
      if (id != null) {
        if (_isSameDay(_selectedDate, DateTime.now())) {
          await Future.wait([
            getReservationV2(id, showLoader: false),
            getTodayReceivedReservationV2(id, showLoader: false),
          ]);
        } else {
          await reservationV2History(showLoader: false);
        }
        await getTodayTimeSlot(id, showLoader: false);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'reservation_status_update_failed'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showEditReservationDialog(Reservations booking) async {
    if (booking.id == null) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditReservationDialog(booking: booking),
    );
    if (saved != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reserv_update'.tr),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final id = storeID;
    if (id != null) {
      if (_isSameDay(_selectedDate, DateTime.now())) {
        await getReservationV2(id, showLoader: false);
      } else {
        await reservationV2History(showLoader: false);
      }
      await getTodayTimeSlot(id, showLoader: false);
    }
  }

}

// -------------------- TOP SNACKBAR --------------------
// SnackBar is always bottom-anchored to the Scaffold; this drops in from the
// top via Overlay instead, since the app wants top-positioned toasts.
class _TopSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onDismiss;
  const _TopSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- MODELS --------------------
class _SlotBooking {
  final Reservations reservation;
  final Color color;
  _SlotBooking(this.reservation, this.color);
}

// -------------------- EDIT RESERVATION DIALOG --------------------
class _EditReservationDialog extends StatefulWidget {
  final Reservations booking;
  const _EditReservationDialog({required this.booking});

  @override
  State<_EditReservationDialog> createState() => _EditReservationDialogState();
}

class _EditReservationDialogState extends State<_EditReservationDialog> {
  late final TextEditingController _partySizeController;
  late final TextEditingController _durationController;
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  late final int _originalPartySize;
  late final int _originalDuration;
  late final DateTime _originalDateTime;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _originalPartySize = b.partySize ?? 0;
    _originalDuration = b.durationMinutes ?? 0;
    _originalDateTime = DateTime.tryParse(b.reservedFor ?? '') ?? DateTime.now();

    _partySizeController = TextEditingController(text: '$_originalPartySize');
    _durationController = TextEditingController(text: '$_originalDuration');
    _date = DateTime(_originalDateTime.year, _originalDateTime.month, _originalDateTime.day);
    _time = TimeOfDay(hour: _originalDateTime.hour, minute: _originalDateTime.minute);

    _partySizeController.addListener(_onFieldChanged);
    _durationController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _partySizeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> _computeChanges() {
    final body = <String, dynamic>{};

    final partySize = int.tryParse(_partySizeController.text) ?? _originalPartySize;
    if (partySize != _originalPartySize) body['party_size'] = partySize;

    final duration = int.tryParse(_durationController.text) ?? _originalDuration;
    if (duration != _originalDuration) body['duration_minutes'] = duration;

    final newDateTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final originalDateTimeMinute = DateTime(_originalDateTime.year, _originalDateTime.month,
        _originalDateTime.day, _originalDateTime.hour, _originalDateTime.minute);
    if (newDateTime != originalDateTimeMinute) {
      body['reserved_for'] = '${newDateTime.toIso8601String()}Z';
    }

    return body;
  }

  bool get _hasChanges => _computeChanges().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final body = _computeChanges();

    if (body.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await CallService().updateReservationV2(body, widget.booking.id.toString());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'reserv_update_failed'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
        Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'edit_reservation'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Update reservation details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// BODY
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    /// BOOKING DETAILS
                    _sectionTitle(
                      icon: Icons.groups_outlined,
                      title: 'Booking Details',
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _labeledField(
                            label: 'party_size_label'.tr,
                            child: TextField(
                              controller: _partySizeController,
                              keyboardType:
                              TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final n = int.tryParse(newValue.text);
                                  return (n != null && n > 100) ? oldValue : newValue;
                                }),
                              ],
                              decoration: _fieldDecoration(
                                hint: '0',
                                icon:
                                Icons.people_outline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _labeledField(
                            label: 'duration_min_label'.tr,
                            child: TextField(
                              controller: _durationController,
                              keyboardType:
                              TextInputType.number,
                              decoration: _fieldDecoration(
                                hint: '60',
                                icon:
                                Icons.timer_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    /// DATE & TIME
                    _sectionTitle(
                      icon:
                      Icons.calendar_month_outlined,
                      title: 'Reservation Schedule',
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [

                        /// DATE
                        Expanded(
                          child: _labeledField(
                            label: 'date'.tr,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius:
                              BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration:
                                _fieldDecoration(
                                  icon: Icons
                                      .calendar_today_outlined,
                                ),
                                child: Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(_date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        /// TIME
                        Expanded(
                          child: _labeledField(
                            label: 'time'.tr,
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius:
                              BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration:
                                _fieldDecoration(
                                  icon: Icons
                                      .access_time_rounded,
                                ),
                                child: Text(
                                  _time.format(context),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// DIVIDER
                    const Divider(
                      color: Color(0xFFF0F0F0),
                    ),

                    const SizedBox(height: 16),

                    /// ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            style:
                            OutlinedButton.styleFrom(
                              minimumSize:
                              const Size(0, 48),
                              foregroundColor:
                              const Color(0xFF374151),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: (_saving || !_hasChanges) ? null : _save,
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 19,
                            ),
                            label: Text(
                              'saved'.tr,
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                            style:
                            ElevatedButton.styleFrom(
                              minimumSize:
                              const Size(0, 48),
                              elevation: 0,
                              backgroundColor:
                              const Color(0xFF16A34A),
                              foregroundColor:
                              Colors.white,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
          if (_saving)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/burger.json',
                    width: 120,
                    height: 120,
                    repeat: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _labeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  InputDecoration _fieldDecoration({
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
      ),

      prefixIcon: icon != null
          ? Icon(
        icon,
        size: 18,
        color: const Color(0xFF6B7280),
      )
          : null,

      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),

      filled: true,
      fillColor: const Color(0xFFF9FAFB),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF16A34A),
          width: 1.5,
        ),
      ),
    );
  }
}

// -------------------- CALENDAR DIALOG --------------------
class _ReservationCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? storeId;
  const _ReservationCalendarDialog({required this.initialDate, this.storeId});

  @override
  State<_ReservationCalendarDialog> createState() => _ReservationCalendarDialogState();
}

class _ReservationCalendarDialogState extends State<_ReservationCalendarDialog> {
  late int _month;
  late int _year;
  Set<int> _daysWithBooking = {};
  // Cached per "year-month" so flipping back and forth doesn't refetch.
  final Map<String, Set<int>> _monthCache = {};

  static const _monthKeys = ['', 'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'];
  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
    _loadMonthBookings();
  }

  Future<void> _loadMonthBookings() async {
    final storeId = int.tryParse(widget.storeId ?? '');
    if (storeId == null) return;
    final requestedYear = _year;
    final requestedMonth = _month;
    final key = '$requestedYear-$requestedMonth';
    final cached = _monthCache[key];
    if (cached != null) {
      if (mounted) setState(() => _daysWithBooking = cached);
      return;
    }

    final totalDays = DateTime(requestedYear, requestedMonth + 1, 0).day;
    final results = await Future.wait(List.generate(totalDays, (i) async {
      final day = i + 1;
      final dateStr =
          DateFormat('yyyy-MM-dd').format(DateTime(requestedYear, requestedMonth, day));
      try {
        final list = await CallService()
            .getReservationV2History({"store_id": storeId, "target_date": dateStr, "offset": 0});
        return list.isNotEmpty ? day : null;
      } catch (e) {
        return null;
      }
    }));

    final days = results.whereType<int>().toSet();
    _monthCache[key] = days;
    // Only apply if the user hasn't already flipped to a different month.
    if (mounted && _year == requestedYear && _month == requestedMonth) {
      setState(() => _daysWithBooking = days);
    }
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
                      _daysWithBooking = {};
                    });
                    _loadMonthBookings();
                  },
                ),
                Text('${_monthKeys[_month].tr} $_year',
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
                      _daysWithBooking = {};
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
                  final isSelected = cellDate != null &&
                      cellDate.year == widget.initialDate.year &&
                      cellDate.month == widget.initialDate.month &&
                      cellDate.day == widget.initialDate.day;
                  final isToday = cellDate != null &&
                      cellDate.year == today.year &&
                      cellDate.month == today.month &&
                      cellDate.day == today.day;
                  final hasBooking = isCurrentMonth && _daysWithBooking.contains(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: cellDate == null ? null : () => Navigator.pop(context, cellDate),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF16A34A) : null,
                          border: isToday && !isSelected
                              ? Border.all(color: const Color(0xFF16A34A))
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCurrentMonth ? '$day' : '',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight:
                                    isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 5,
                              width: 5,
                              child: hasBooking
                                  ? DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF16A34A),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
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

// -------------------- DONUT CHART PAINTER --------------------
class _DonutPainter extends CustomPainter {
  final int total;
  final int booked;
  final int pending;
  final int cancelled;

  _DonutPainter({required this.total, required this.booked, required this.pending, required this.cancelled});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final bg = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * 3.14159265, false, bg);

    if (total == 0) return;

    final bookedSweep = 2 * 3.14159265 * (booked / total);
    final pendingSweep = 2 * 3.14159265 * (pending / total);

    final bookedPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -3.14159265 / 2, bookedSweep, false, bookedPaint);

    if (pending > 0) {
      final pendingPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
          rect, -3.14159265 / 2 + bookedSweep, pendingSweep, false, pendingPaint);
    }

    if (cancelled > 0) {
      final cancelledSweep = 2 * 3.14159265 * (cancelled / total);
      final cancelledPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, -3.14159265 / 2 + bookedSweep + pendingSweep,
          cancelledSweep, false, cancelledPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.booked != booked ||
        oldDelegate.pending != pending ||
        oldDelegate.cancelled != cancelled;
  }
}