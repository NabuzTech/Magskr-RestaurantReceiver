import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/Reservation V2/get_reservation_of_store_byDate.dart';
import '../../models/Reservation V2/get_today_reservation_V2_of_store.dart';
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
  Summary? summary;
  GetTodaySlotOfReservation? timeSlotData;
  DateTime _selectedDate = DateTime.now();
  String? storeID;
  Worker? _syncWorker;
  int? _highlightedReservationId;
  Color? _highlightedColor;
  final ScrollController _coversScrollController = ScrollController();
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
  }

  @override
  void dispose() {
    _syncWorker?.dispose();
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
    getTodayTimeSlot(id, showLoader: false);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openCalendar() async {
    final id = storeID;
    if (id == null) return;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _ReservationCalendarDialog(initialDate: _selectedDate),
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
                floating: true,
                snap: true,
                pinned: false,
                elevation: 1,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                title: GestureDetector(
                  onTap: _openCalendar,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('reserv'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          Text(_todayLabel(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
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
              child: Column(
                children: [
                  _coversFilledCard(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        _todaysBookingsCard(),
                      ],
                    ),
                  ),
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
  Map<String, List<_SlotBooking>> _bucketBySlot(List<Reservations> list) {
    final sorted = [...list]
      ..sort((a, b) => (a.reservedFor ?? '').compareTo(b.reservedFor ?? ''));
    final Map<String, List<_SlotBooking>> map = {};
    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final dt = DateTime.tryParse(r.reservedFor ?? '');
      if (dt == null) continue;
      final label = DateFormat('HH:mm').format(dt);
      final color = (r.status ?? '').toLowerCase() == 'cancelled'
          ? _statusColor(r.status)
          : _bookingColors[i % _bookingColors.length];
      map.putIfAbsent(label, () => []).add(_SlotBooking(r, color));
    }
    return map;
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
    final buckets = _bucketBySlot(reservationsData ?? []);
    final allBookings = buckets.values.expand((e) => e).toList()
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
                            .map((s) => _slotColumn(s, buckets[s.time] ?? []))
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

  Widget _slotColumn(Slots slot, List<_SlotBooking> bookings) {
    const segmentHeight = 22.0;
    return Padding(
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

  // -------------------- TODAY'S BOOKINGS --------------------
  Widget _todaysBookingsCard() {
    final bookings = reservationsData ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            _todayLabel(),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month_outlined,
                  size: 20, color: Colors.green),
              onPressed: _openCalendar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('no_bookings_today'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            for (final booking in bookings) ...[
              _bookingTile(booking),
              const SizedBox(height: 8),
            ],
        ],
      ),
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
        borderRadius: BorderRadius.circular(16),
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

              const Spacer(),

              _statusChip(_titleCase(booking.status ?? '-')),
            ],
          ),

          const SizedBox(height: 7),

          /// CUSTOMER NAME
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  (booking.customerName?.isNotEmpty ?? false)
                      ? booking.customerName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
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
            ],
          ),

          const SizedBox(height: 7),

          /// BOOKING INFO
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _bookingInfoItem(
                    icon: Icons.people_outline_rounded,
                    label: 'guests'.tr,
                    value: '${booking.partySize ?? 0}',
                  ),
                ),

                Container(
                  height: 30,
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                ),

                Expanded(
                  child: _bookingInfoItem(
                    icon: Icons.timer_outlined,
                    label: 'duration_label'.tr,
                    value: '${booking.durationMinutes ?? 0} ${'min_unit'.tr}',
                  ),
                ),
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
            )
          else if ((booking.status ?? '').toLowerCase() != 'cancelled')
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _showEditReservationDialog(booking),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                ),
                label: Text(
                  'edit_booking'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(
                    color: Color(0xFFBFDBFE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingInfoItem({
    required IconData icon,
    required String label,
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
          ),
        ),
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
        reservationsData = reservation.reservations ?? [];
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
          .toList();

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
      setState(() {
        timeSlotData = timeSlot;
        isLoading = false;
        print('Time Slot Reservation V2: ${timeSlotData?.slots?.length ?? 0} slots');
      });
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'booked' ? 'booking_accepted'.tr : 'booking_declined'.tr),
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
  const _ReservationCalendarDialog({required this.initialDate});

  @override
  State<_ReservationCalendarDialog> createState() => _ReservationCalendarDialogState();
}

class _ReservationCalendarDialogState extends State<_ReservationCalendarDialog> {
  late int _month;
  late int _year;

  static const _monthKeys = ['', 'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'];
  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
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
                  onPressed: () => setState(() {
                    if (_month == 1) {
                      _month = 12;
                      _year--;
                    } else {
                      _month--;
                    }
                  }),
                ),
                Text('${_monthKeys[_month].tr} $_year',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    if (_month == 12) {
                      _month = 1;
                      _year++;
                    } else {
                      _month++;
                    }
                  }),
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
                        child: Center(
                          child: Text(
                            isCurrentMonth ? '$day' : '',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
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