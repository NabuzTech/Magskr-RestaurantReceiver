import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/repository/api_repository.dart';
import '../../models/Booking V2/check_availability_slot_model.dart';
import '../../models/Booking V2/get_bookingV2_detail_model.dart';
import '../../constants/constant.dart';
import '../../constants/common_colors.dart';



import 'common_calendar_dialog.dart';
import 'edit_booking_sheet.dart' show showTimeSlotsPicker, showCancelBookingDialog, CancelBookingButton;

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;

  // Only the edit-booking bottom sheet's own background now (Scaffold uses
  // Colors.white directly) — a light blue tint instead of the old cream.
  static const Color backgroundColor = Color(0xFFF0F6FF);

  static const Color acceptedColor = Color(0xFF2E9B63);
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color declinedColor = Color(0xFFEF5350);

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isUpdating = false;
  bool changed = false;
  String? errorMessage;

  BookingV2DetailsModel? booking;
  String? serviceName;

  // ============================================================
  // EDIT CONTROLLERS
  // ============================================================

  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editPhoneController = TextEditingController();
  final TextEditingController editEmailController = TextEditingController();
  final TextEditingController editGuestsController = TextEditingController();
  final TextEditingController editNotesController = TextEditingController();

  DateTime? editSelectedDate;
  Slots? editSelectedSlot;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }


  @override
  void dispose() {
    editNameController.dispose();
    editPhoneController.dispose();
    editEmailController.dispose();
    editGuestsController.dispose();
    editNotesController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await CallService().getBookingV2Details(widget.bookingId);
      if (!mounted) return;
      setState(() {
        booking = data;
        isLoading = false;
      });
      _loadServiceName(data.serviceId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load booking details';
        isLoading = false;
      });
    }
  }

  Future<void> _loadServiceName(int? serviceId) async {
    if (serviceId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString(valueShared_STORE_KEY) ?? '';
      final services = await CallService().getBookingV2StoreServices(storeId);
      final match = services.where((s) => s.id == serviceId);
      if (!mounted || match.isEmpty) return;
      setState(() => serviceName = match.first.name);
    } catch (_) {
      // service name is a nice-to-have; keep showing the rest of the details
    }
  }

  void _copyReference() {
    final ref = booking?.reference ?? 'Booking #${widget.bookingId}';
    Clipboard.setData(ClipboardData(text: ref));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied')),
    );
  }

  Future<void> _callCustomer() async {
    final phone = booking?.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsappCustomer() async {
    final phone = booking?.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String get bookingStatus {
    switch ((booking?.status ?? '').toLowerCase()) {
      case 'booked':
        return 'Accepted';
      case 'cancelled':
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  String _formatTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '')?.toLocal();
    if (dt == null) return '--:--';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(String? iso) {
    final dt = DateTime.tryParse(iso ?? '')?.toLocal();
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        body: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: "Sora"),
          child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                )
                    : errorMessage != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingStatusCard(),
                      const SizedBox(height: 16),
                      _buildCustomerCard(),
                      const SizedBox(height: 16),
                      _buildBookingInformationCard(),
                      if ((booking?.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesCard(),
                      ],
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),

        bottomNavigationBar:
        isLoading || errorMessage != null
            ? null
            : DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: "Sora"),
                child: _buildBottomAction(),
              ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: primaryGreen),
            const SizedBox(height: 12),
            Text(errorMessage ?? 'Something went wrong'),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildBookingStatusCard() {
    final statusColor = _getStatusColor();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(.14),
            statusColor.withOpacity(.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: statusColor.withOpacity(.25),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'BOOKING REFERENCE',

            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              Expanded(
                child: Text(
                  booking?.reference ?? 'Booking #${widget.bookingId}',

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263238),
                  ),
                ),
              ),

              GestureDetector(
                onTap: _copyReference,
                child: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _statusIcon(),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    bookingStatus.toUpperCase(),

                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _getStatusMessage(),

                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER CARD
  // ============================================================

  Widget _buildCustomerCard() {
    return _sectionCard(
      title: 'Customer Information',

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFF1E6),
                      Color(0xFFFFD9B8),
                    ],
                  ),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_outline_rounded,
                  color: primaryGreen,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      booking?.customerName ?? 'Guest',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF263238),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Customer',

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _phoneRow(),

          const SizedBox(height: 15),

          _infoRow(
            icon: Icons.email_outlined,
            title: 'Email Address',
            value: booking?.customerEmail ?? '-',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE ROW (with call / WhatsApp quick actions)
  // ============================================================

  Widget _phoneRow() {
    final phone = booking?.customerPhone;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: veryLightGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_outlined, color: primaryGreen, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 3),
              Text(
                phone ?? '-',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
        if (hasPhone) ...[
          GestureDetector(
            onTap: _callCustomer,
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: acceptedColor.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: acceptedColor, size: 16),
            ),
          ),
          GestureDetector(
            onTap: _whatsappCustomer,
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: acceptedColor.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_rounded, color: acceptedColor, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // BOOKING INFORMATION
  // ============================================================

  Widget _buildBookingInformationCard() {
    return _sectionCard(
      title: 'Booking Information',

      child: Column(
        children: [
          if (serviceName != null) ...[
            _infoRow(
              icon: Icons.design_services_outlined,
              title: 'Service',
              value: serviceName!,
            ),
            const SizedBox(height: 18),
          ],

          _infoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Booking Date',
            value: _formatDate(booking?.startAt),
          ),

          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.access_time_rounded,
            title: 'Booking Time',
            value: _formatTime(booking?.startAt),
          ),

          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.groups_outlined,
            title: 'Number of Guests',
            value: '${booking?.partySize ?? 0} Guests',
          ),

          if ((booking?.paymentStatus ?? '').toLowerCase() != 'not_required') ...[
            const SizedBox(height: 18),

            _infoRow(
              icon: Icons.payment_outlined,
              title: 'Payment Status',
              value: (booking?.paymentStatus ?? 'Pending').toUpperCase(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesCard() {
    return _sectionCard(
      title: 'Customer Notes',

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color: veryLightGreen.withOpacity(.45),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Text(
          booking?.note ?? '',

          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: Colors.lightBlue,
        ),

        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,

          decoration: const BoxDecoration(
            color: veryLightGreen,
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color: primaryGreen,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction() {
    if (bookingStatus == 'Pending') {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),

        decoration: const BoxDecoration(
          color: Colors.white,

          border: Border(
            top: BorderSide(color: Colors.lightBlue),
          ),
        ),

        child: Row(
          children: [
            Expanded(child: _declineButton()),
            const SizedBox(width: 12),
            Expanded(child: _acceptButton()),
          ],
        ),
      );
    }

    if (bookingStatus == 'Accepted') {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),

        decoration: const BoxDecoration(
          color: Colors.white,

          border: Border(
            top: BorderSide(color: Colors.lightBlue),
          ),
        ),

        child: _editBookingButton(),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Widget _acceptButton() {
    return GestureDetector(
      onTap: isUpdating ? null : _acceptBooking,

      child: Container(
        height: 52,

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryGreen, secondaryGreen],
          ),

          borderRadius: BorderRadius.circular(13),
        ),

        child: Center(
          child: isUpdating
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.4,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.white),
              SizedBox(width: 7),
              Text(
                'Accept Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptBooking() async {
    setState(() => isUpdating = true);

    try {
      final result = await CallService()
          .updateBookingV2Details({'status': 'booked'}, widget.bookingId);

      if (!mounted) return;
      setState(() {
        booking = result;
        changed = true;
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept booking')),
      );
    }
  }

  // ============================================================
  // DECLINE
  // ============================================================

  Widget _declineButton() {
    return GestureDetector(
      onTap: isUpdating ? null : _showDeclineDialog,

      child: Container(
        height: 52,

        decoration: BoxDecoration(
          color: declinedColor.withOpacity(.06),

          borderRadius: BorderRadius.circular(13),

          border: Border.all(color: declinedColor.withOpacity(.35)),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close_rounded, color: declinedColor),
            SizedBox(width: 6),
            Text(
              'Decline',
              style: TextStyle(
                color: declinedColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeclineDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Decline Booking?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to decline this booking?',
              ),
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
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                final message = messageController.text.trim();
                Navigator.pop(dialogContext);
                _declineBooking(message);
              },

              child: const Text(
                'Decline',
                style: TextStyle(
                  color: declinedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _declineBooking(String customerMessage) async {
    setState(() => isUpdating = true);

    try {
      final result = await CallService().updateBookingV2Details({
        'status': 'cancelled',
        'customer_message': customerMessage.isNotEmpty ? customerMessage : '',
      }, widget.bookingId);

      if (!mounted) return;
      setState(() {
        booking = result;
        changed = true;
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking declined')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline booking')),
      );
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Widget _editBookingButton() {
    return GestureDetector(
      onTap: _showEditBookingSheet,

      child: Container(
        width: double.infinity,
        height: 54,

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryGreen, secondaryGreen],
          ),

          borderRadius: BorderRadius.circular(14),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBookingSheet() {
    editNameController.text = booking?.customerName ?? '';
    editPhoneController.text = booking?.customerPhone ?? '';
    editEmailController.text = booking?.customerEmail ?? '';
    editGuestsController.text = '${booking?.partySize ?? 0}';
    editNotesController.text = booking?.note ?? '';

    final startAt = DateTime.tryParse(booking?.startAt ?? '')?.toLocal();
    editSelectedDate = startAt;
    editSelectedSlot = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: "Sora"),
              child: Container(
              height: MediaQuery.of(context).size.height * .88,

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
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: veryLightGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: primaryGreen,
                            ),
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
                          _editSectionTitle(
                            'Customer Information',
                            Icons.person_outline,
                          ),

                          const SizedBox(height: 16),

                          _editTextField(
                            controller: editNameController,
                            label: 'Customer Name',
                            icon: Icons.person_outline,
                          ),

                          const SizedBox(height: 14),

                          _editTextField(
                            controller: editPhoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 14),

                          _editTextField(
                            controller: editEmailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 25),

                          _editSectionTitle(
                            'Booking Information',
                            Icons.calendar_month_outlined,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _editDateField(setModalState),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _editTimeField(setModalState),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          _editSectionTitle(
                            'Guest Information',
                            Icons.groups_outlined,
                          ),

                          const SizedBox(height: 16),

                          _editTextField(
                            controller: editGuestsController,
                            label: 'Number of Guests',
                            icon: Icons.groups_outlined,
                            isNumber: true,
                          ),

                          const SizedBox(height: 25),

                          _editSectionTitle(
                            'Additional Notes',
                            Icons.notes_outlined,
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: editNotesController,
                            maxLines: 4,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(fontFamily: "Sora"),
                            decoration: InputDecoration(
                              hintText: 'Add booking notes...',
                              hintStyle: const TextStyle(fontFamily: "Sora"),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                const BorderSide(color: Colors.lightBlue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                const BorderSide(color: Colors.lightBlue),
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

                          const SizedBox(height: 28),

                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await _saveBookingChanges();
                            },

                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primaryGreen, secondaryGreen],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          CancelBookingButton(
                            onTap: () async {
                              final msg = await showCancelBookingDialog(context);
                              if (msg == null) return;
                              if (context.mounted) Navigator.pop(context);
                              await _declineBooking(msg);
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _editSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: veryLightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: primaryGreen),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  Widget _editTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _editDateField(StateSetter setModalState) {
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
            final pickedDate = await showCommonCalendarDialog(
              context: context,
              initialDate: editSelectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime(DateTime.now().year + 2),
            );

            if (pickedDate != null) {
              setModalState(() {
                editSelectedDate = pickedDate;
                editSelectedSlot = null;
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
                    editSelectedDate == null
                        ? _formatDate(booking?.startAt)
                        : _formatDate(editSelectedDate!.toIso8601String()),
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

  Widget _editTimeField(StateSetter setModalState) {
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
            final guests = int.tryParse(editGuestsController.text.trim()) ??
                booking?.partySize ??
                1;
            final date = editSelectedDate ??
                DateTime.tryParse(booking?.startAt ?? '')?.toLocal() ??
                DateTime.now();
            final picked = await showTimeSlotsPicker(
              context: context,
              serviceId: booking?.serviceId,
              date: date,
              partySize: guests,
              currentSlot: editSelectedSlot,
            );

            if (picked != null) {
              setModalState(() {
                editSelectedSlot = picked;
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
                  Icons.access_time_rounded,
                  size: 18,
                  color: primaryGreen,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    editSelectedSlot?.time ?? _formatTime(booking?.startAt),
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

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveBookingChanges() async {
    setState(() => isUpdating = true);

    DateTime startAt;
    if (editSelectedSlot?.datetime != null) {
      startAt = DateTime.parse(editSelectedSlot!.datetime!);
    } else {
      final baseDate = editSelectedDate ??
          DateTime.tryParse(booking?.startAt ?? '')?.toLocal() ??
          DateTime.now();
      final original = DateTime.tryParse(booking?.startAt ?? '')?.toLocal();
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
      'party_size': int.tryParse(editGuestsController.text.trim()) ??
          booking?.partySize ??
          0,
      'customer_name': editNameController.text.trim(),
      'customer_phone': editPhoneController.text.trim(),
      'customer_email': editEmailController.text.trim(),
      'note': editNotesController.text.trim(),
    };

    try {
      final result =
      await CallService().updateBookingV2Details(body, widget.bookingId);

      if (!mounted) return;
      setState(() {
        booking = result;
        changed = true;
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking')),
      );
    }
  }

  // ============================================================
  // STATUS ICON / COLOR / MESSAGE
  // ============================================================

  Widget _statusIcon() {
    final color = _getStatusColor();

    IconData icon;
    if (bookingStatus == 'Accepted') {
      icon = Icons.check_circle_rounded;
    } else if (bookingStatus == 'Pending') {
      icon = Icons.access_time_filled_rounded;
    } else {
      icon = Icons.cancel_rounded;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }

  Color _getStatusColor() {
    switch (bookingStatus) {
      case 'Accepted':
        return acceptedColor;
      case 'Declined':
        return declinedColor;
      default:
        return pendingColor;
    }
  }

  String _getStatusMessage() {
    switch (bookingStatus) {
      case 'Accepted':
        return 'This booking has been accepted';
      case 'Declined':
        return 'This booking has been declined';
      default:
        return 'Waiting for your confirmation';
    }
  }
}
