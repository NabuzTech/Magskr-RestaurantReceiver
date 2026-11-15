import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/Booking V2/get_store_config_model.dart';
import '../../../constants/constant.dart';
import '../../../constants/common_colors.dart';
import 'settings_header.dart';

class StoreConfigScreen extends StatefulWidget {
  const StoreConfigScreen({super.key});

  @override
  State<StoreConfigScreen> createState() => _StoreConfigScreenState();
}

class _StoreConfigScreenState extends State<StoreConfigScreen> {
  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;

  static const Color acceptedColor = Color(0xFF2E9B63);
  static const Color declinedColor = Color(0xFFEF5350);

  bool isLoading = true;
  bool isSaving = false;
  bool _dirty = false;
  String? errorMessage;
  String? storeId;
  String? storeName;
  String? storeImageUrl;

  bool _enabled = false;
  bool _requirePayment = false;
  bool _autoAccept = false;

  final _slotIntervalController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _bookingWindowController = TextEditingController();
  final _currencyController = TextEditingController();

  late final _fieldControllers = [
    _slotIntervalController,
    _leadTimeController,
    _bookingWindowController,
    _currencyController,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _fieldControllers) {
      c.addListener(_onFieldChanged);
    }
    _loadSettings();
    _loadStoreInfo();
  }

  // Store name/logo is fetched once on Home and cached — every other screen
  // just reads it back instead of hitting the API again.
  Future<void> _loadStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      storeName = prefs.getString(valueShared_STORE_NAME);
      storeImageUrl = prefs.getString(valueShared_STORE_LOGO);
    });
  }

  @override
  void dispose() {
    for (final c in _fieldControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      storeId = prefs.getString(valueShared_STORE_KEY) ?? '';

      final data = await CallService().getBookingV2StoreConfig(storeId!);

      if (!mounted) return;
      _applySettings(data);
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load settings';
        isLoading = false;
      });
    }
  }

  void _applySettings(BookingStoreConfigModel config) {
    _enabled = config.enabled ?? false;
    _requirePayment = config.requirePayment ?? false;
    _autoAccept = config.autoAccept ?? false;
    _slotIntervalController.text = '${config.slotIntervalMinutes ?? 0}';
    _leadTimeController.text = '${config.leadTimeMinutes ?? 0}';
    _bookingWindowController.text = '${config.bookingWindowDays ?? 0}';
    _currencyController.text = config.currency ?? '';
    setState(() => _dirty = false);
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveSettings() async {
    final id = storeId;
    if (id == null) return;

    Get.dialog(
      Center(
        child: Lottie.asset('assets/animations/burger.json',
            width: 150, height: 150, repeat: true),
      ),
      barrierDismissible: false,
    );

    setState(() => isSaving = true);

    final body = {
      'enabled': _enabled,
      'slot_interval_minutes': int.tryParse(_slotIntervalController.text) ?? 0,
      'lead_time_minutes': int.tryParse(_leadTimeController.text) ?? 0,
      'booking_window_days': int.tryParse(_bookingWindowController.text) ?? 0,
      'currency': _currencyController.text.trim(),
      'require_payment': _requirePayment,
      'auto_accept': _autoAccept,
    };

    try {
      final updated = await CallService().updateBookingV2StoreConfig(body, id);

      if (Get.isDialogOpen == true) Get.back();
      if (!mounted) return;

      _applySettings(updated);
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings updated successfully'),
          backgroundColor: acceptedColor,
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      if (!mounted) return;
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: $e'),
          backgroundColor: declinedColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: "Sora"),
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'Store Settings'),

              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                )
                    : errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                  color: primaryGreen,
                  onRefresh: _loadSettings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsCard(),
                  ),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "Sora",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.lightBlue),
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
          const Text(
            'Store Booking Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 4),

          _switchRow(
            'Bookings Enabled',
            _enabled,
                (v) => setState(() {
              _enabled = v;
              _dirty = true;
            }),
          ),

          const Divider(height: 24, color: Colors.lightBlue),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _editableTile('Slot Interval (min)', _slotIntervalController,
                  keyboardType: TextInputType.number),
              _editableTile('Lead Time (min)', _leadTimeController,
                  keyboardType: TextInputType.number),
              _editableTile('Booking Window (days)', _bookingWindowController,
                  keyboardType: TextInputType.number),
              _editableTile('Currency', _currencyController),
            ],
          ),

          const SizedBox(height: 4),

          _switchRow(
            'Require Payment',
            _requirePayment,
                (v) => setState(() {
              _requirePayment = v;
              _dirty = true;
            }),
          ),

          _switchRow(
            'Auto Accept Bookings',
            _autoAccept,
                (v) => setState(() {
              _autoAccept = v;
              _dirty = true;
            }),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_dirty && !isSaving) ? _saveSettings : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Settings',
                style: TextStyle(
                  color: _dirty ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Sora",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263238),
            ),
          ),
        ),
        Switch(
          value: value,
          activeColor: primaryGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _editableTile(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: veryLightGreen.withOpacity(.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: "Sora",
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
