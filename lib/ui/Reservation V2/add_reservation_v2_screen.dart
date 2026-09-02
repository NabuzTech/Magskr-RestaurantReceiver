import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/Reservation V2/get_today_slot_reservationV2.dart';
import '../../models/Reservation V2/reservation_v2_settings_model.dart';
import '../../utils/global.dart';
import '../../utils/my_application.dart';

const Color _kDarkGreen = Color(0xFF163C2C);
const Color _kAccentGreen = Color(0xFF16A34A);
const Color _kAccentGreenLight = Color(0xFFDCFCE7);
const Color _kGoldLabel = Color(0xFFC7D39B);

/// Opens the v2 "new reservation" step wizard as a bottom sheet.
/// Returns `true` if a reservation was created so the caller can refresh.
Future<bool?> showAddReservationV2Flow(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddReservationV2Screen(),
  );
}

class AddReservationV2Screen extends StatefulWidget {
  const AddReservationV2Screen({super.key});

  @override
  State<AddReservationV2Screen> createState() => _AddReservationV2ScreenState();
}

class _AddReservationV2ScreenState extends State<AddReservationV2Screen> {
  static const _stepIcons = [
    Icons.people_outline,
    Icons.calendar_today_outlined,
    Icons.access_time_rounded,
    Icons.person_outline,
  ];
  static const _monthKeys = [
    '', 'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'
  ];
  static const _weekdayKeys = [
    'weekday_sun', 'weekday_mon', 'weekday_tue', 'weekday_wed',
    'weekday_thu', 'weekday_fri', 'weekday_sat'
  ];
  static const _guestPresets = [1, 2, 3, 4, 5, 6, 7, 8, 10];

  List<String> get _stepTitles => [
        'party_size_label'.tr,
        'select_date'.tr,
        'available_times_label'.tr,
        'your_details_label'.tr,
      ];
  List<String> get _weekLabels => _weekdayKeys.map((k) => k.tr).toList();
  List<String> get _monthNames => _monthKeys.map((k) => k.isEmpty ? '' : k.tr).toList();

  int _step = 0;
  double _stepDirection = 1.0;
  final List<GlobalKey> _stepKeys = List.generate(4, (_) => GlobalKey());
  final ScrollController _stepScrollController = ScrollController();
  String? _storeId;
  String _storeName = 'Restaurant';
  GetReservationV2SettingsModel? _settings;

  int? _selectedGuests;
  final TextEditingController _customGuestController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late int _calMonth;
  late int _calYear;

  bool _loadingSlots = false;
  GetTodaySlotOfReservation? _timeSlotData;
  Slots? _selectedSlot;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _noteFocus = FocusNode();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calMonth = _selectedDate.month;
    _calYear = _selectedDate.year;
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _storeId = prefs.getString(valueShared_STORE_KEY);
    final name = await getStoreName();
    if (!mounted) return;
    setState(() => _storeName = name);
    if (_storeId != null) {
      try {
        final settings = await CallService().getSettingsReservationV2(_storeId!);
        if (mounted) setState(() => _settings = settings);
      } catch (e) {
        print('Reservation V2 settings load failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _customGuestController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _noteFocus.dispose();
    _stepScrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _stepDirection = step >= _step ? 1.0 : -1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepKeys[step].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.5);
      }
    });
  }

  void _selectGuests(int guests) {
    FocusScope.of(context).unfocus();
    _goToStep(1);
    setState(() {
      _selectedGuests = guests;
      _step = 1;
    });
  }

  void _submitCustomGuests() {
    final value = int.tryParse(_customGuestController.text.trim());
    if (value == null || value <= 0) return;
    FocusScope.of(context).unfocus();
    _goToStep(1);
    setState(() {
      _selectedGuests = value;
      _step = 1;
    });
  }

  Future<void> _goToTimesStep() async {
    _goToStep(2);
    setState(() {
      _step = 2;
      _selectedSlot = null;
      _loadingSlots = true;
      _timeSlotData = null;
    });
    final storeId = _storeId;
    if (storeId == null) {
      setState(() => _loadingSlots = false);
      return;
    }
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await CallService().gettingTimeSlotReservationV2(
        storeId,
        dateStr,
        partySize: _selectedGuests ?? 2,
      );
      if (!mounted) return;
      setState(() {
        _timeSlotData = result;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSlots = false);
      _showMessage('time_slots_load_failed'.tr, isError: true);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      setState(() => _error = 'fill'.tr);
      return;
    }
    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailValid) {
      setState(() => _error = 'invalid_email_label'.tr);
      return;
    }
    final storeId = int.tryParse(_storeId ?? '');
    final slot = _selectedSlot;
    if (storeId == null || slot?.datetime == null || _selectedGuests == null) {
      setState(() => _error = 'missing_info_label'.tr);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      final duration = _settings?.defaultDurationMinutes ?? 90;
      final reservedFor = DateTime.parse(slot!.datetime!);
      final reservedUntil = reservedFor.add(Duration(minutes: duration));
      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

      final body = {
        'store_id': storeId,
        'party_size': _selectedGuests,
        'reserved_for': fmt.format(reservedFor),
        'reserved_until': fmt.format(reservedUntil),
        'duration_minutes': duration,
        'status': 'booked',
        'customer_name': name,
        'customer_phone': phone,
        'customer_email': email,
        'note': _noteController.text.trim(),
      };

      debugPrint('Create V2 Reservation body is $body');
      await CallService().createReservationV2(body);

      if (!mounted) return;
      // Close the sheet before firing the refresh triggers below — the
      // dashboard opens its own loading dialog on these, and doing that
      // first would push it above this sheet, so `pop` would close that
      // dialog instead of the sheet, leaving this stuck on "please wait".
      Navigator.of(context).pop(true);

      app.appController.updateSyncTime();
      app.appController.triggerReservationV2Created();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'create_reserv'.tr;
      });
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _kAccentGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return isWide ? _wideLayout() : _narrowLayout();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            left: 0,
            top: -30,
            child: Center(child: _closeButtonCircle()),
          ),
        ],
      ),
    );
  }

  Widget _closeButtonCircle() {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
     // padding: const EdgeInsets.all(5),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.black54),
        onPressed: () => Navigator.of(context).pop(false),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 7, child: _content()),
        Container(
          width: 280,
          color: _kDarkGreen,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: _sidebar(vertical: true),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _kDarkGreen,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: _sidebar(vertical: false),
        ),
        Expanded(child: _content()),
      ],
    );
  }

  Widget _content() {
    return Column(
      children: [
    //    _closeButtonRow(),
        _stepIndicator(),
        const SizedBox(height: 8),
        Expanded(child: _stepBody()),
      ],
    );
  }

  Widget _stepIndicator() {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        controller: _stepScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: List.generate(_stepTitles.length * 2 - 1, (i) {
            if (i.isOdd) {
              final leftDone = (i - 1) ~/ 2 < _step;
              return Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: leftDone ? _kAccentGreen : const Color(0xFFE5E7EB),
              );
            }
            final idx = i ~/ 2;
            final done = idx < _step;
            final current = idx == _step;
            return Row(
              key: _stepKeys[idx],
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || current ? _kAccentGreen : Colors.white,
                    border: Border.all(
                      color: done || current ? _kAccentGreen : const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: current ? Colors.white : Colors.grey.shade500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _stepTitles[idx],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: done || current ? _kAccentGreen : Colors.grey.shade500,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _stepBody() {
    Widget child;
    switch (_step) {
      case 0:
        child = _guestsStep();
        break;
      case 1:
        child = _dateStep();
        break;
      case 2:
        child = _timesStep();
        break;
      default:
        child = _detailsStep();
    }
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_stepDirection, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [...previousChildren, if (currentChild != null) currentChild],
        ),
        child: KeyedSubtree(key: ValueKey(_step), child: child),
      ),
    );
  }

  Widget _stepHeader(int icon, String title, String subtitle) => _stepHeaderIcon(
        _stepIcons[icon],
        title,
        subtitle,
      );

  Widget _stepHeaderIcon(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: _kAccentGreenLight, shape: BoxShape.circle),
          child: Icon(icon, color: _kAccentGreen, size: 26),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }

  // ---------------- STEP 1: GUESTS ----------------
  Widget _guestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _stepHeader(0, 'guests_step_title'.tr, 'guests_step_subtitle'.tr),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: [
              for (final g in _guestPresets) _guestTile(g),
              _guestTile(12, label: '12+'),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('custom_guest_count_label'.tr,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customGuestController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _submitCustomGuests(),
                  decoration: InputDecoration(
                    hintText: 'custom_guest_hint'.tr,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _submitCustomGuests,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kAccentGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guestTile(int value, {String? label}) {
    final selected = _selectedGuests == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectGuests(value),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? _kAccentGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _kAccentGreen : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label ?? '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- STEP 2: DATE ----------------
  Widget _dateStep() {
    final firstDay = DateTime(_calYear, _calMonth, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(_calYear, _calMonth + 1, 0).day;
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final maxDate = todayOnly.add(Duration(days: _settings?.bookingWindowDays ?? 90));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              children: [
                _stepHeader(1, 'select_date'.tr, '${_monthNames[_calMonth]} $_calYear'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        if (_calMonth == 1) {
                          _calMonth = 12;
                          _calYear--;
                        } else {
                          _calMonth--;
                        }
                      }),
                    ),
                    Text('${_monthNames[_calMonth]} $_calYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() {
                        if (_calMonth == 12) {
                          _calMonth = 1;
                          _calYear++;
                        } else {
                          _calMonth++;
                        }
                      }),
                    ),
                  ],
                ),
                Row(
                  children: _weekLabels
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 12)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                ...List.generate(totalCells ~/ 7, (week) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = week * 7 + dayIndex;
                      final day = cellIndex - startWeekday + 1;
                      final isCurrentMonth = day >= 1 && day <= totalDays;
                      final cellDate = isCurrentMonth ? DateTime(_calYear, _calMonth, day) : null;
                      final isSelected = cellDate != null &&
                          cellDate.year == _selectedDate.year &&
                          cellDate.month == _selectedDate.month &&
                          cellDate.day == _selectedDate.day;
                      final isPast = cellDate != null && cellDate.isBefore(todayOnly);
                      final isTooFar = cellDate != null && cellDate.isAfter(maxDate);
                      final disabled = cellDate == null || isPast || isTooFar;

                      return Expanded(
                        child: GestureDetector(
                          onTap: disabled ? null : () => setState(() => _selectedDate = cellDate),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? _kAccentGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isCurrentMonth ? '$day' : '',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : disabled
                                          ? Colors.grey.shade300
                                          : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        ),
        _navButtons(
          onBack: () {
            _goToStep(0);
            setState(() => _step = 0);
          },
          onNext: _goToTimesStep,
        ),
      ],
    );
  }

  // ---------------- STEP 3: TIMES ----------------
  Widget _timesStep() {
    final slots = _timeSlotData?.slots ?? [];
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              children: [
                _stepHeader(2, 'available_times_label'.tr, '$dateLabel · ${_selectedGuests ?? 0} ${'guests'.tr}'),
                const SizedBox(height: 10),
                if (_loadingSlots)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: _kAccentGreen),
                  )
                else if (slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('no_time_slots_for_date'.tr,
                        style: TextStyle(color: Colors.grey.shade600)),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: slots.map((s) => _slotTile(s)).toList(),
                  ),
              ],
            ),
          ),
        ),
        _navButtons(
          onBack: () {
            _goToStep(1);
            setState(() => _step = 1);
          },
          onNext: _selectedSlot == null
              ? null
              : () {
                  _goToStep(3);
                  setState(() => _step = 3);
                },
        ),
      ],
    );
  }

  Widget _slotTile(Slots s) {
    final bookable = s.bookable ?? (s.available ?? 0) > 0;
    final selected = _selectedSlot?.time == s.time && _selectedSlot?.datetime == s.datetime;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: bookable ? () => setState(() => _selectedSlot = s) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _kAccentGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kAccentGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant,
                    size: 16, color: !bookable ? Colors.grey.shade400 : (selected ? Colors.white : Colors.black54)),
                const SizedBox(width: 4),
                Text(
                  s.time ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: bookable ? null : TextDecoration.lineThrough,
                    color: !bookable ? Colors.grey.shade400 : (selected ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            Text(
              bookable ? '${s.available ?? 0} ${'slots_free_label'.tr}' : 'fully_booked_label'.tr,
              style: TextStyle(
                fontSize: 12,
                decoration: bookable ? null : TextDecoration.lineThrough,
                color: !bookable ? Colors.grey.shade400 : (selected ? Colors.white : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 4: DETAILS ----------------
  Widget _detailsStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                _stepHeader(3, 'your_details_label'.tr, 'almost_done_label'.tr),
                const SizedBox(height: 24),
                _detailsField('customer_name'.tr, _nameController, 'Max Mustermann',
                    required: true,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(_phoneFocus)),
                _detailsField('phone_number'.tr, _phoneController, '+49 170 1234567',
                    required: true,
                    keyboardType: TextInputType.phone,
                    focusNode: _phoneFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(_emailFocus)),
                _detailsField('email_address'.tr, _emailController, 'max.mustermann@email.com',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(_noteFocus)),
                _detailsField('special_note'.tr, _noteController, 'Geburtstagsfeier',
                    maxLines: 3,
                    focusNode: _noteFocus,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      _noteFocus.unfocus();
                      if (!_submitting) _submit();
                    }),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        _navButtons(
          onBack: _submitting
              ? null
              : () {
                  _goToStep(2);
                  setState(() => _step = 2);
                },
          onNext: _submitting ? null : _submit,
          nextLabel: _submitting ? 'please_wait_label'.tr : 'complete_reservation_label'.tr,
        ),
      ],
    );
  }

  Widget _detailsField(String label, TextEditingController controller, String hint,
      {bool required = false,
      int maxLines = 1,
      TextInputType? keyboardType,
      FocusNode? focusNode,
      TextInputAction? textInputAction,
      VoidCallback? onEditingComplete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              children: required
                  ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onEditingComplete: onEditingComplete,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SHARED NAV BUTTONS ----------------
  Widget _navButtons({VoidCallback? onBack, VoidCallback? onNext, String? nextLabel}) {
    nextLabel ??= 'next'.tr;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('back_label'.tr, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentGreen,
                disabledBackgroundColor: _kAccentGreen.withOpacity(0.4),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SIDEBAR ----------------
  Widget _sidebar({required bool vertical}) {
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);
    final timeLabel = _selectedSlot?.time;

    if (!vertical) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('table_reservation_label'.tr,
                    style: const TextStyle(color: _kGoldLabel, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_storeName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Row(
            children: [
              _sidebarChip(Icons.people_outline, '${_selectedGuests ?? '-'}'),
              const SizedBox(width: 8),
              _sidebarChip(Icons.calendar_today_outlined, DateFormat('d.MM').format(_selectedDate)),
              const SizedBox(width: 8),
              _sidebarChip(Icons.access_time_rounded, timeLabel ?? '—'),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('table_reservation_label'.tr,
            style: const TextStyle(color: _kGoldLabel, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(_storeName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const Spacer(),
        _sidebarRow(Icons.people_outline, 'party_size_label'.tr.toUpperCase(),
            _selectedGuests == null ? '—' : '$_selectedGuests ${'guests'.tr}'),
        const SizedBox(height: 20),
        _sidebarRow(Icons.calendar_today_outlined, 'select_date'.tr.toUpperCase(), dateLabel),
        const SizedBox(height: 20),
        _sidebarRow(Icons.access_time_rounded, 'time'.tr.toUpperCase(), timeLabel ?? '—'),
      ],
    );
  }

  Widget _sidebarRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
