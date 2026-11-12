import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/repository/api_repository.dart';
import '../../models/Booking V2/check_availability_slot_model.dart';
import '../../constants/common_colors.dart';
import 'common_calendar_dialog.dart';

// Minimal, model-agnostic view of a booking — Home/Bookings/History each
// carry their own near-identical booking model, so callers map to this
// instead of the sheet depending on any one of them.
class EditableBookingV2 {
  final String id;
  final int? serviceId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? partySize;
  final String? note;
  final String? startAt;

  const EditableBookingV2({
    required this.id,
    this.serviceId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.partySize,
    this.note,
    this.startAt,
  });
}

/// Opens the booking edit bottom sheet and saves changes via
/// updateBookingV2Details. Returns true if the booking was updated.
Future<bool> showEditBookingV2Sheet(
  BuildContext context,
  EditableBookingV2 booking,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditBookingSheet(booking: booking),
  );
  return result ?? false;
}

/// Confirm dialog with an optional customer message. Returns the message
/// ('' if left empty) on confirm, null if dismissed. Shared by both edit sheets.
Future<String?> showCancelBookingDialog(BuildContext context) {
  final messageController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Cancel Booking?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to cancel this booking?'),
          const SizedBox(height: 14),
          TextField(
            controller: messageController,
            maxLines: 3,
            style: const TextStyle(fontFamily: "Sora"),
            decoration: InputDecoration(
              hintText: 'Message to customer (optional)',
              hintStyle: TextStyle(
                fontSize: 12,
                fontFamily: "Sora",
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, messageController.text.trim()),
          child: const Text(
            'Cancel Booking',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Red outlined "Cancel Booking" button used under Save Changes in both edit sheets.
class CancelBookingButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CancelBookingButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
            SizedBox(width: 9),
            Text(
              'Cancel Booking',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a popup showing the available time slots (fetched from
/// bookings/v2/availability) inside a scrollable, height-capped box.
/// Tapping a bookable slot pops it back; used by both the edit-booking
/// sheet and the booking-details edit sheet so the slot picker only
/// lives in one place.
Future<Slots?> showTimeSlotsPicker({
  required BuildContext context,
  required int? serviceId,
  required DateTime date,
  required int partySize,
  Slots? currentSlot,
}) {
  return showModalBottomSheet<Slots>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TimeSlotsPickerSheet(
      serviceId: serviceId,
      date: date,
      partySize: partySize,
      currentSlot: currentSlot,
    ),
  );
}

class _TimeSlotsPickerSheet extends StatefulWidget {
  final int? serviceId;
  final DateTime date;
  final int partySize;
  final Slots? currentSlot;

  const _TimeSlotsPickerSheet({
    required this.serviceId,
    required this.date,
    required this.partySize,
    this.currentSlot,
  });

  @override
  State<_TimeSlotsPickerSheet> createState() => _TimeSlotsPickerSheetState();
}

class _TimeSlotsPickerSheetState extends State<_TimeSlotsPickerSheet> {
  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;

  bool isLoading = false;
  String? error;
  CheckAvailabilitySlotModel? availability;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _isoDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  Future<void> _load() async {
    final serviceId = widget.serviceId;
    if (serviceId == null || widget.partySize <= 0) {
      setState(() => error = 'No time slots available for this booking.');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await CallService().checkAvailabilitySlot(
        serviceId,
        _isoDate(widget.date),
        widget.partySize,
      );
      if (!mounted) return;
      setState(() {
        availability = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Failed to load available time slots';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: "Sora"),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Time Slot',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: veryLightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: primaryGreen,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _content(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (widget.serviceId != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }
    final slots = availability?.slots ?? [];
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No time slots available for this date.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: slots.map(_slotTile).toList(),
    );
  }

  Widget _slotTile(Slots s) {
    final bookable = s.bookable ?? (s.available ?? 0) > 0;
    final selected = widget.currentSlot?.datetime == s.datetime &&
        widget.currentSlot?.time == s.time;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: bookable ? () => Navigator.pop(context, s) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [primaryGreen, secondaryGreen])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.lightBlue,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: !bookable
                      ? Colors.grey.shade400
                      : (selected ? Colors.white : primaryGreen),
                ),
                const SizedBox(width: 5),
                Text(
                  s.time ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: bookable ? null : TextDecoration.lineThrough,
                    color: !bookable
                        ? Colors.grey.shade400
                        : (selected ? Colors.white : const Color(0xFF263238)),
                  ),
                ),
              ],
            ),
            Text(
              bookable ? '${s.available ?? 0} left' : 'Full',
              style: TextStyle(
                fontSize: 10,
                decoration: bookable ? null : TextDecoration.lineThrough,
                color: !bookable
                    ? Colors.grey.shade400
                    : (selected ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBookingSheet extends StatefulWidget {
  final EditableBookingV2 booking;

  const _EditBookingSheet({required this.booking});

  @override
  State<_EditBookingSheet> createState() => _EditBookingSheetState();
}

class _EditBookingSheetState extends State<_EditBookingSheet> {
  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;
  static const Color backgroundColor = Color(0xFFF3F8FF);

  late final TextEditingController nameController = TextEditingController(
    text: widget.booking.customerName ?? '',
  );
  late final TextEditingController phoneController = TextEditingController(
    text: widget.booking.customerPhone ?? '',
  );
  late final TextEditingController emailController = TextEditingController(
    text: widget.booking.customerEmail ?? '',
  );
  late final TextEditingController guestsController = TextEditingController(
    text: '${widget.booking.partySize ?? 0}',
  );
  late final TextEditingController notesController = TextEditingController(
    text: widget.booking.note ?? '',
  );

  DateTime? selectedDate;
  Slots? selectedSlot;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final startAt = DateTime.tryParse(widget.booking.startAt ?? '')?.toLocal();
    selectedDate = startAt;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    guestsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String _formatDate(String? iso) {
    final dt = DateTime.tryParse(iso ?? '')?.toLocal();
    if (dt == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);

    DateTime startAt;
    if (selectedSlot?.datetime != null) {
      startAt = DateTime.parse(selectedSlot!.datetime!);
    } else {
      final baseDate =
          selectedDate ??
          DateTime.tryParse(widget.booking.startAt ?? '')?.toLocal() ??
          DateTime.now();
      final original = DateTime.tryParse(widget.booking.startAt ?? '')?.toLocal();
      startAt = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        original?.hour ?? 0,
        original?.minute ?? 0,
      );
    }

    final body = {
      'start_at': startAt.toIso8601String(),
      'party_size':
          int.tryParse(guestsController.text.trim()) ??
          widget.booking.partySize ??
          0,
      'customer_name': nameController.text.trim(),
      'customer_phone': phoneController.text.trim(),
      'customer_email': emailController.text.trim(),
      'note': notesController.text.trim(),
    };

    try {
      await CallService().updateBookingV2Details(body, widget.booking.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update booking')));
    }
  }

  Future<void> _cancelBooking() async {
    final msg = await showCancelBookingDialog(context);
    if (msg == null) return;
    setState(() => isSubmitting = true);
    try {
      await CallService().updateBookingV2Details({
        'status': 'cancelled',
        'customer_message': msg,
      }, widget.booking.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to cancel booking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: "Sora"),
      child: Container(
      height: MediaQuery.of(context).size.height * .78,
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Booking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: veryLightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Customer Name', nameController, Icons.person_outline),
                  const SizedBox(height: 14),
                  _field(
                    'Phone Number',
                    phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Email Address',
                    emailController,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _dateField()),
                      const SizedBox(width: 12),
                      Expanded(child: _timeField()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Number of Guests',
                    guestsController,
                    Icons.groups_outlined,
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontFamily: "Sora"),
                    decoration: InputDecoration(
                      hintText: 'Add booking notes...',
                      hintStyle:
                          const TextStyle(fontFamily: "Sora"),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.lightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.lightBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: isSubmitting ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryGreen, secondaryGreen],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CancelBookingButton(onTap: isSubmitting ? null : _cancelBooking),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          // iOS' numeric keypad has no return/next key, so use the normal
          // text keyboard and restrict input to digits instead.
          keyboardType: isNumber ? TextInputType.text : keyboardType,
          inputFormatters:
              isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontFamily: "Sora"),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryGreen, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.lightBlue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.lightBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () async {
            final picked = await showCommonCalendarDialog(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime(DateTime.now().year + 2),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
                selectedSlot = null;
              });
            }
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.lightBlue),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: primaryGreen,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? _formatDate(widget.booking.startAt)
                        : _formatDate(selectedDate!.toIso8601String()),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '')?.toLocal();
    if (dt == null) return '--:--';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _timeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () async {
            final guests =
                int.tryParse(guestsController.text.trim()) ??
                widget.booking.partySize ??
                1;
            final date =
                selectedDate ??
                DateTime.tryParse(widget.booking.startAt ?? '')?.toLocal() ??
                DateTime.now();
            final picked = await showTimeSlotsPicker(
              context: context,
              serviceId: widget.booking.serviceId,
              date: date,
              partySize: guests,
              currentSlot: selectedSlot,
            );
            if (picked != null) setState(() => selectedSlot = picked);
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.lightBlue),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: primaryGreen,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    selectedSlot?.time ?? _formatTime(widget.booking.startAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
