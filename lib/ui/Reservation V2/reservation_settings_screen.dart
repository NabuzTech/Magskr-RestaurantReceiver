import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/Reservation V2/reservation_v2_settings_model.dart';

class ReservationSettingsScreen extends StatefulWidget {
  const ReservationSettingsScreen({super.key});

  @override
  State<ReservationSettingsScreen> createState() => _ReservationSettingsScreenState();
}

class _ReservationSettingsScreenState extends State<ReservationSettingsScreen> {
  bool isLoading = false;
  bool _dirty = false;
  String? storeID;

  bool _enabled = true;
  final _maxCoversController = TextEditingController();
  final _slotIntervalController = TextEditingController();
  final _defaultDurationController = TextEditingController();
  final _maxPartySizeController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _bookingWindowController = TextEditingController();

  late final _fieldControllers = [
    _maxCoversController,
    _slotIntervalController,
    _defaultDurationController,
    _maxPartySizeController,
    _leadTimeController,
    _bookingWindowController,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _fieldControllers) {
      c.addListener(_onFieldChanged);
    }
    _loadSettings();
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(valueShared_STORE_KEY);
    if (id == null || id.isEmpty) return;
    storeID = id;

    setState(() => isLoading = true);
    try {
      final settings = await CallService().getSettingsReservationV2(id);
      _applySettings(settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'load_settings_failed'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applySettings(GetReservationV2SettingsModel settings) {
    _enabled = settings.enabled ?? true;
    _maxCoversController.text = '${settings.maxCovers ?? 0}';
    _slotIntervalController.text = '${settings.slotIntervalMinutes ?? 0}';
    _defaultDurationController.text = '${settings.defaultDurationMinutes ?? 0}';
    _maxPartySizeController.text = '${settings.maxPartySize ?? 0}';
    _leadTimeController.text = '${settings.leadTimeMinutes ?? 0}';
    _bookingWindowController.text = '${settings.bookingWindowDays ?? 0}';
    setState(() => _dirty = false);
  }

  Future<void> _saveSettings() async {
    final id = storeID;
    if (id == null) return;

    Get.dialog(
      Center(
        child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true),
      ),
      barrierDismissible: false,
    );

    final body = {
      "enabled": _enabled,
      "max_covers": int.tryParse(_maxCoversController.text) ?? 0,
      "slot_interval_minutes": int.tryParse(_slotIntervalController.text) ?? 0,
      "default_duration_minutes": int.tryParse(_defaultDurationController.text) ?? 0,
      "max_party_size": int.tryParse(_maxPartySizeController.text) ?? 0,
      "lead_time_minutes": int.tryParse(_leadTimeController.text) ?? 0,
      "booking_window_days": int.tryParse(_bookingWindowController.text) ?? 0,
    };

    try {
      final updated = await CallService().updateSettingsReservationV2(body, id);
      if (Get.isDialogOpen ?? false) Get.back();
      _applySettings(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('setting_update'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_update'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text('reservation_settings_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('reserv'.tr,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          Switch(
                            value: _enabled,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) => setState(() {
                              _enabled = v;
                              _dirty = true;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.0,
                        children: [
                          _settingField('max_covers_label'.tr, _maxCoversController),
                          _settingField('slot_interval_label'.tr, _slotIntervalController),
                          _settingField('default_duration_label'.tr, _defaultDurationController),
                          _settingField('max_party_size_label'.tr, _maxPartySizeController),
                          _settingField('lead_time_label'.tr, _leadTimeController),
                          _settingField('booking_window_label'.tr, _bookingWindowController),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _dirty ? _saveSettings : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'save_settings_label'.tr,
                            style: TextStyle(
                              color: _dirty ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _settingField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
