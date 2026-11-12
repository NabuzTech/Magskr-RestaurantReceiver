import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../models/Booking V2/get_today_booking_V2_model.dart';
import '../../models/Booking V2/get_today_received_bookingV2_model.dart'
    as received;
import '../../utils/booking_v2_mapper.dart';
import '../../utils/my_application.dart';
import '../../constants/constant.dart';
import '../../constants/common_colors.dart';
import 'booking_details.dart';
import 'edit_booking_sheet.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;

  static const Color backgroundColor = Color(0xFF304B7DFF);

  static const Color acceptedColor = Color(0xFF2E9B63);
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color declinedColor = Color(0xFFEF5350);

  // ============================================================
  // STATE
  // ============================================================

  String selectedStatus = 'All';
  String selectedSource = 'Today';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;
  List<Bookings> bookings = [];
  // Per-status counts from the API's `summary` (tab label → count)
  Map<String, int?> statusCounts = {};

  final Set<int> _updatingIds = {};
  // Which of the updating ids are declines — so the spinner shows on the
  // button that was actually tapped
  final Set<int> _decliningIds = {};

  Worker? _bookingRefreshWorker;

  @override
  void initState() {
    super.initState();
    _loadBookings();

    // New-booking push notification — merge that one booking silently,
    // no full reload / loader
    _bookingRefreshWorker = ever(app.appController.newBookingV2Event, (_) {
      final id = app.appController.lastNewBookingV2Id;
      if (mounted && id != null) _mergeNewBooking(id);
    });
  }

  Future<void> _mergeNewBooking(int id) async {
    try {
      final detail = await CallService().getBookingV2Details('$id');
      final booking = bookingV2ToBookings(detail);

      // 'Today' shows bookings scheduled for today; 'Today Received' shows
      // bookings created today.
      final belongsHere = selectedSource == 'Today Received'
          ? isSameLocalDay(booking.createdAt, DateTime.now())
          : isSameLocalDay(booking.startAt, DateTime.now());

      if (!mounted) return;
      setState(() {
        final idx = bookings.indexWhere((b) => b.id == booking.id);
        if (!belongsHere) {
          // e.g. date changed to another day — take it off this list
          if (idx != -1) bookings = [...bookings]..removeAt(idx);
        } else if (idx == -1) {
          bookings = [booking, ...bookings];
        } else {
          bookings[idx] = booking;
        }
      });
    } catch (e) {
      // Best-effort silent merge — a manual pull-to-refresh still recovers
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _bookingRefreshWorker?.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString(valueShared_STORE_KEY) ?? '';

      final List<Bookings> data;
      final Map<String, int?> counts;
      if (selectedSource == 'Today') {
        final result = await CallService().todayBookingV2(storeId);
        data = result.bookings ?? [];
        final s = result.summary;
        counts = {
          'All': s?.total,
          'Pending': s?.pending,
          'Accepted': s?.booked,
          'Declined': s?.cancelled,
        };
      } else {
        final result = await CallService().todayReceivedBookingV2(storeId);
        data = (result.bookings ?? []).map(_bookingFromReceived).toList();
        final s = result.summary;
        counts = {
          'All': s?.total,
          'Pending': s?.pending,
          'Accepted': s?.booked,
          'Declined': s?.cancelled,
        };
      }

      if (!mounted) return;
      setState(() {
        bookings = data;
        statusCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Data not found. Please try again.';
        isLoading = false;
      });
    }
  }

  Bookings _bookingFromReceived(received.Booking b) {
    return Bookings(
      id: b.id,
      storeId: b.storeId,
      userId: b.userId,
      serviceId: b.serviceId,
      resourceId: b.resourceId,
      reference: b.reference,
      startAt: b.startAt,
      endAt: b.endAt,
      blockedUntil: b.blockedUntil,
      durationMinutes: b.durationMinutes,
      partySize: b.partySize,
      units: b.units,
      status: b.status,
      paymentStatus: b.paymentStatus,
      customerName: b.customerName,
      customerPhone: b.customerPhone,
      customerEmail: b.customerEmail,
      note: b.note,
      priceTotal: b.priceTotal?.toInt(),
      depositAmount: b.depositAmount,
      currency: b.currency,
      createdAt: b.createdAt,
    );
  }

  void _onSourceChanged(String source) {
    if (selectedSource == source) return;
    setState(() => selectedSource = source);
    _loadBookings();
  }

  // ============================================================
  // ACCEPT / DECLINE
  // ============================================================

  Future<void> _acceptBooking(Bookings booking) async {
    final id = booking.id;
    if (id == null) return;

    setState(() => _updatingIds.add(id));

    try {
      await CallService().updateBookingV2Details({'status': 'booked'}, '$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted successfully')),
      );
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingIds.remove(id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to accept booking')));
    }
  }

  void _showDeclineDialog(Bookings booking) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: "Sora"),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.lightBlue),
            ),
            title: const Text(
              'Decline Booking?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontFamily: "Sora",
                color: Color(0xFF263238),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to decline this booking?'),
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
                    filled: true,
                    fillColor: veryLightGreen.withOpacity(.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.lightBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.lightBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: "Sora",
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final message = messageController.text.trim();
                  Navigator.pop(dialogContext);
                  _declineBooking(booking, message);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: declinedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: "Sora",
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _declineBooking(Bookings booking, String message) async {
    final id = booking.id;
    if (id == null) return;

    setState(() {
      _updatingIds.add(id);
      _decliningIds.add(id);
    });

    try {
      await CallService().updateBookingV2Details({
        'status': 'cancelled',
        'customer_message': message.isNotEmpty ? message : '',
      }, '$id');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking declined')));
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _updatingIds.remove(id);
        _decliningIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline booking')),
      );
    }
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String _displayStatus(String? apiStatus) {
    switch ((apiStatus ?? '').toLowerCase()) {
      case 'booked':
        return 'Accepted';
      case 'cancelled':
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String displayStatus) {
    switch (displayStatus) {
      case 'Accepted':
        return acceptedColor;
      case 'Pending':
        return pendingColor;
      case 'Declined':
        return declinedColor;
      default:
        return Colors.grey;
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

  // ============================================================
  // FILTERED BOOKINGS
  // ============================================================

  List<Bookings> get filteredBookings {
    return bookings.where((booking) {
        final displayStatus = _displayStatus(booking.status);

        final matchesStatus =
            selectedStatus == 'All' || displayStatus == selectedStatus;

        final query = searchQuery.toLowerCase();

        final matchesSearch =
            query.isEmpty ||
            (booking.customerName ?? '').toLowerCase().contains(query) ||
            (booking.customerPhone ?? '').toLowerCase().contains(query) ||
            (booking.reference ?? '').toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList()
      // Newest (highest id) first
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: "Sora"),
        child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildSourceTabs(),
                  //
                  // _buildSearchSection(),
                  SizedBox(height: 12,),
                  _buildStatusTabs(),

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          )
                        : errorMessage != null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            color: primaryGreen,
                            onRefresh: _loadBookings,
                            child: _buildBookingsList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            Text(
              errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontWeight: FontWeight.w600,fontFamily: "Sora",),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry', style: TextStyle(fontFamily: "Sora",color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SOURCE TABS (Today / Today Received)
  // ============================================================

  Widget _buildSourceTabs() {
    final sources = ['Today', 'Today Received'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: sources.map((source) {
          final isSelected = selectedSource == source;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onSourceChanged(source),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [primaryGreen, secondaryGreen],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  source,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SEARCH SECTION
  // ============================================================

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Container(
        height: 50,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: Colors.lightBlue),

          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: TextField(
          controller: searchController,

          style: const TextStyle(fontFamily: "Sora"),

          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },

          decoration: InputDecoration(
            border: InputBorder.none,

            prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen),

            hintText: 'Search booking or customer',

            hintStyle: TextStyle(
              fontSize: 12,
              fontFamily: "Sora",
              color: Colors.grey.shade500,
            ),

            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      searchController.clear();

                      setState(() {
                        searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : null,

            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS TABS
  // ============================================================

  Widget _buildStatusTabs() {
    final tabs = ['All', 'Pending', 'Accepted', 'Declined'];

    return SizedBox(
      height: 40,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        itemCount: tabs.length,

        separatorBuilder: (_, __) => const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final title = tabs[index];
          final isSelected = selectedStatus == title;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedStatus = title;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [primaryGreen, secondaryGreen],
                      )
                    : null,

                color: isSelected ? null : Colors.white,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.lightBlue,
                ),
              ),

              child: Text(
                statusCounts[title] == null
                    ? title
                    : '$title (${statusCounts[title]})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BOOKINGS LIST
  // ============================================================

  Widget _buildBookingsList() {
    final items = filteredBookings;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [_buildEmptyState()],
      );
    }

    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        itemCount: items.length + 1,

        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                selectedSource.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.black,
                ),
              ),
            );
          }

          final booking = items[index - 1];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _bookingCard(booking),
          );
        },
      ),
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  bool _canEdit(Bookings booking) =>
      (booking.status ?? '').toLowerCase() == 'booked';

  Future<void> _editBooking(Bookings booking) async {
    final saved = await showEditBookingV2Sheet(
      context,
      EditableBookingV2(
        id: '${booking.id}',
        serviceId: booking.serviceId,
        customerName: booking.customerName,
        customerPhone: booking.customerPhone,
        customerEmail: booking.customerEmail,
        partySize: booking.partySize,
        note: booking.note,
        startAt: booking.startAt,
      ),
    );

    if (saved && booking.id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully')),
      );
      _loadBookings();
    }
  }

  Widget _bookingCard(Bookings booking) {
    final displayStatus = _displayStatus(booking.status);
    final statusColor = _getStatusColor(displayStatus);

    final card = GestureDetector(
      onTap: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(bookingId: '${booking.id}'),
          ),
        );

        if (refresh == true) {
          _loadBookings();
        }
      },

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: Colors.lightBlue),

          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // REFERENCE + STATUS
            // ------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.reference ?? 'Booking #${booking.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),

                _statusBadge(displayStatus, statusColor),
              ],
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------
            // CUSTOMER
            // ------------------------------------------------
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF1E6), Color(0xFFFFD9B8)],
                    ),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        booking.customerPhone ?? '-',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Divider(height: 1, color: Colors.grey.withOpacity(.10)),

            const SizedBox(height: 13),

            // ------------------------------------------------
            // DATE / TIME / GUESTS
            // ------------------------------------------------
            Row(
              children: [
                _infoItem(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(booking.startAt),
                ),

                const SizedBox(width: 16),

                _infoItem(
                  icon: Icons.access_time_rounded,
                  text: _formatTime(booking.startAt),
                ),

                const Spacer(),

                _infoItem(
                  icon: Icons.groups_outlined,
                  text: '${booking.partySize ?? 0}',
                ),
              ],
            ),

            if ((booking.paymentStatus ?? '').toLowerCase() !=
                'not_required') ...[
              const SizedBox(height: 8),

              _infoItem(
                icon: Icons.payment_outlined,
                text:
                    'Payment: ${(booking.paymentStatus ?? 'pending').toUpperCase()}',
              ),
            ],

            if (displayStatus == 'Pending') ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _declineButton(booking)),
                  const SizedBox(width: 10),
                  Expanded(child: _acceptButton(booking)),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!_canEdit(booking)) return card;

    return Slidable(
      key: ValueKey('booking_${booking.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.24,
        children: [
          Builder(builder: (ctx) => GestureDetector(
            onTap: () {
              Slidable.of(ctx)?.close();
              _editBooking(booking);
            },
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
      child: card,
    );
  }

  // ============================================================
  // ACCEPT / DECLINE BUTTONS
  // ============================================================

  Widget _acceptButton(Bookings booking) {
    final isUpdating = _updatingIds.contains(booking.id);

    return GestureDetector(
      onTap: isUpdating ? null : () => _acceptBooking(booking),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryGreen, secondaryGreen],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: isUpdating && !_decliningIds.contains(booking.id)
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _declineButton(Bookings booking) {
    final isUpdating = _updatingIds.contains(booking.id);

    return GestureDetector(
      onTap: isUpdating ? null : () => _showDeclineDialog(booking),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: declinedColor.withOpacity(.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: declinedColor.withOpacity(.35)),
        ),
        child: Center(
          child: _decliningIds.contains(booking.id)
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: declinedColor,
                    strokeWidth: 2.2,
                  ),
                )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, color: declinedColor, size: 18),
              SizedBox(width: 5),
              Text(
                'Decline',
                style: TextStyle(
                  color: declinedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status, Color color) {
    IconData icon;

    if (status == 'Accepted') {
      icon = Icons.check_circle_rounded;
    } else if (status == 'Pending') {
      icon = Icons.access_time_filled_rounded;
    } else {
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),

          const SizedBox(width: 4),

          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryGreen),

        const SizedBox(width: 5),

        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,

              decoration: const BoxDecoration(
                color: veryLightGreen,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.event_busy_outlined,
                size: 38,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No bookings found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 6),

            Text(
              'Try changing your filters or search.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
