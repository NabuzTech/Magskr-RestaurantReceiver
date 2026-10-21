import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../models/Reservation V2/get_today_reservation_V2_of_store.dart';

/// Reservation details body (hero card, stats, reservation/customer/note/created sections).
/// Shared by the store dashboard details screen and the super admin details popup.
class ReservationDetailsView extends StatelessWidget {
  final Reservations booking;

  const ReservationDetailsView({super.key, required this.booking});

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'booked':
        return AppTheme.accent;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBackground(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'booked':
        return const Color(0xFFEFFAF3);
      case 'pending':
        return const Color(0xFFFFF8E7);
      case 'cancelled':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
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

  String _orDash(String? s) => (s ?? '').trim().isEmpty ? '-' : s!;

  @override
  Widget build(BuildContext context) {
    final status = (booking.status ?? '').toLowerCase();
    final statusColor = _statusColor(booking.status);
    final statusBg = _statusBackground(booking.status);
    final customerName = _orDash(booking.customerName);
    final guests = booking.partySize ?? 0;
    final duration = booking.durationMinutes ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER / BOOKING CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      '#${booking.id ?? '-'}',
                      style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text(
                          _titleCase(booking.status ?? '-'),
                          style: TextStyle(fontFamily: 'Sora', color: statusColor, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                status == 'booked'
                    ? 'Reservation confirmed'
                    : status == 'pending'
                        ? 'Reservation awaiting confirmation'
                        : status == 'cancelled'
                            ? 'Reservation cancelled'
                            : 'Reservation details',
                style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.62), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _heroInfo(icon: Icons.calendar_today_rounded, label: 'DATE', value: _formatDate(booking.reservedFor))),
                  Container(width: 1, height: 42, color: Colors.white.withOpacity(0.10)),
                  Expanded(child: _heroInfo(icon: Icons.access_time_rounded, label: 'TIME', value: _formatTime(booking.reservedFor))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // QUICK STATS
        Row(
          children: [
            Expanded(child: _quickInfoCard(icon: Icons.people_alt_outlined, title: 'Guests', value: '$guests')),
            const SizedBox(width: 12),
            Expanded(child: _quickInfoCard(icon: Icons.timelapse_rounded, title: 'Duration', value: '$duration min')),
          ],
        ),
        const SizedBox(height: 24),

        // RESERVATION
        _sectionTitle(icon: Icons.event_note_rounded, title: 'Reservation'),
        const SizedBox(height: 10),
        _sectionCard(children: [
          _modernDetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'reservation_date'.tr,
            value: '${_formatDate(booking.reservedFor)}  ${_formatTime(booking.reservedFor)}',
          ),
          _modernDivider(),
          _modernDetailRow(icon: Icons.timer_outlined, label: 'duration_min_label'.tr, value: '$duration ${'min_unit'.tr}'),
          _modernDivider(),
          _modernDetailRow(icon: Icons.people_outline_rounded, label: 'guest'.tr, value: '$guests'),
        ]),
        const SizedBox(height: 24),

        // CUSTOMER
        _sectionTitle(icon: Icons.person_outline_rounded, title: 'Customer'),
        const SizedBox(height: 10),
        _sectionCard(children: [
          _modernDetailRow(icon: Icons.person_outline_rounded, label: 'customer'.tr, value: customerName),
          _modernDivider(),
          _modernDetailRow(icon: Icons.phone_outlined, label: 'phone'.tr, value: _orDash(booking.customerPhone)),
          _modernDivider(),
          _modernDetailRow(icon: Icons.email_outlined, label: 'email_address'.tr, value: _orDash(booking.customerEmail)),
        ]),

        // NOTE
        if ((booking.note ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(icon: Icons.sticky_note_2_outlined, title: 'Note'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notes_rounded, size: 18, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.note!,
                    style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF78350F), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],

        // CREATED INFO
        if ((booking.createdAt ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(icon: Icons.history_rounded, title: 'Booking Information'),
          const SizedBox(height: 10),
          _sectionCard(children: [
            _modernDetailRow(
              icon: Icons.access_time_rounded,
              label: 'date'.tr,
              value: '${_formatDate(booking.createdAt)}  ${_formatTime(booking.createdAt)}',
            ),
          ]),
        ],
      ],
    );
  }

  Widget _heroInfo({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.45), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: const Color(0xFF334155)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: const Color(0xFF111827).withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF111827)),
        ),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }

  Widget _modernDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Sora', color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernDivider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
}
