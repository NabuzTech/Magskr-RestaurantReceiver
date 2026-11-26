import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/common_colors.dart';
import '../../constants/constant.dart';
import '../../models/Booking V2/get_service_model.dart';
import '../../models/blocked_date_model.dart';
import '../Booking/Settings/settings_header.dart';
import '../Reservation V2/reservation_dashboard_v2.dart' show ReservationCalendarDialog;

const _appliesKeys = {
  'all': 'bd_applies_all',
  'reservation': 'bd_applies_reservation',
  'booking': 'bd_applies_booking',
};

String _display(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Runs an API call behind the app's full-screen burger loader.
Future<T> _withLoader<T>(Future<T> Function() task) async {
  Get.dialog(
    Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
    barrierDismissible: false,
  );
  try {
    return await task();
  } finally {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}

/// Whole days on which no reservation / booking can be made. Shared by the
/// Reservation V2 and Booking V2 settings.
class BlockedDatesScreen extends StatefulWidget {
  const BlockedDatesScreen({super.key});

  @override
  State<BlockedDatesScreen> createState() => _BlockedDatesScreenState();
}

class _BlockedDatesScreenState extends State<BlockedDatesScreen> {
  int _storeId = 0;
  List<BlockedDateModel> _items = [];
  List<GetServiceModel> _services = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 0;
    _loadServices();
    await _load();
  }

  // Packages are optional: stores without Booking V2 still get "All packages".
  Future<void> _loadServices() async {
    try {
      final services = await CallService().getBookingV2StoreServices('$_storeId');
      if (mounted) setState(() => _services = services);
    } catch (e) {
      debugPrint('Blocked dates: services load failed: $e');
    }
  }

  Future<void> _load() async {
    try {
      final items = await CallService().getBlockedDates(_storeId);
      items.sort((a, b) => a.startDate.compareTo(b.startDate));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('Blocked dates load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _setActive(BlockedDateModel item, bool value) async {
    debugPrint('[BlockedDates] toggle id=${item.id} is_active: ${item.isActive} -> $value');
    // Reload inside the loader so the switch is already updated when it closes.
    final error = await _withLoader(() async {
      final error = await CallService().updateBlockedDate(item.id!, {'is_active': value});
      await _load();
      return error;
    });
    if (mounted && error != null) _showError(error);
  }

  Future<void> _delete(BlockedDateModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('bd_delete_confirm'.tr),
        content: Text(_rangeText(item)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('bd_cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('bd_delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await _withLoader(() async {
      final error = await CallService().deleteBlockedDate(item.id!);
      await _load();
      return error;
    });
    if (mounted && error != null) _showError(error);
  }

  Future<void> _openForm([BlockedDateModel? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _BlockedDateForm(storeId: _storeId, services: _services, existing: existing),
    );
    if (saved == true && mounted) await _withLoader(_load);
  }

  String _rangeText(BlockedDateModel item) {
    String f(String iso) {
      final d = DateTime.tryParse(iso);
      return d == null ? iso : _display(d);
    }

    return item.startDate == item.endDate ? f(item.startDate) : '${f(item.startDate)} - ${f(item.endDate)}';
  }

  String _scopeText(BlockedDateModel item) {
    final scope = (_appliesKeys[item.appliesTo] ?? item.appliesTo).tr;
    if (item.serviceId == null) return scope;
    final service = _services.firstWhereOrNull((s) => s.id == item.serviceId);
    return '$scope · ${service?.name ?? '#${item.serviceId}'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: CommonColors.darkBlue,
        onPressed: _loading ? null : () => _openForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Sora'),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(title: 'bd_title'.tr),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          children: [
                            if (_failed || _items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(30),
                                child: Text((_failed ? 'bd_load_failed' : 'bd_empty').tr, textAlign: TextAlign.center),
                              )
                            else
                              for (final item in _items) _card(item),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BlockedDateModel item) {
    final name = item.name ?? '';
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.lightBlue),
      ),
      child: ListTile(
        onTap: () => _openForm(item),
        title: Text(name.isEmpty ? _rangeText(item) : name,
            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text('${name.isEmpty ? '' : '${_rangeText(item)}\n'}${_scopeText(item)}',
            style: const TextStyle(fontFamily: 'Sora', fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: item.isActive, onChanged: (v) => _setActive(item, v)),
            IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _delete(item)),
          ],
        ),
      ),
    );
  }
}

class _BlockedDateForm extends StatefulWidget {
  final int storeId;
  final List<GetServiceModel> services;
  final BlockedDateModel? existing;

  const _BlockedDateForm({required this.storeId, required this.services, this.existing});

  @override
  State<_BlockedDateForm> createState() => _BlockedDateFormState();
}

class _BlockedDateFormState extends State<_BlockedDateForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late DateTime? _start = DateTime.tryParse(widget.existing?.startDate ?? '');
  late DateTime? _end = DateTime.tryParse(widget.existing?.endDate ?? '');
  late bool _isRange = _start != _end;
  late String _appliesTo = widget.existing?.appliesTo ?? 'all';
  late int? _serviceId = widget.existing?.serviceId;
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // A running block may have started in the past; it must stay selectable.
    final earliest = _start != null && _start!.isBefore(today) ? _start! : today;
    final day = await showDialog<DateTime>(
      context: context,
      builder: (_) => ReservationCalendarDialog(
        initialDate: (isEnd ? _end ?? _start : _start) ?? today,
        firstDate: isEnd ? _start ?? earliest : earliest,
      ),
    );
    if (day == null) return;
    setState(() {
      if (isEnd) {
        _end = day;
      } else {
        _start = day;
        if (!_isRange || _end == null || _end!.isBefore(day)) _end = day;
      }
    });
  }

  Widget _dateButton(String labelKey, DateTime? date, {bool isEnd = false}) {
    return OutlinedButton.icon(
      onPressed: () => _pickDate(isEnd: isEnd),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(date == null ? labelKey.tr : _display(date)),
    );
  }

  Future<void> _save() async {
    if (_start == null) {
      setState(() => _error = 'bd_select_date'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = blockedDateBody(
      storeId: widget.storeId,
      name: _name.text,
      start: _start!,
      end: _isRange ? _end : null,
      appliesTo: _appliesTo,
      serviceId: _serviceId,
      isActive: _isActive,
    );
    final existing = widget.existing;
    final error = await _withLoader(() => existing == null
        ? CallService().createBlockedDate(body)
        : CallService().updateBlockedDate(existing.id!, body));

    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text((widget.existing == null ? 'bd_add' : 'bd_edit').tr,
              style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: 'bd_name'.tr, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text('bd_single_day'.tr)),
              ButtonSegment(value: true, label: Text('bd_range'.tr)),
            ],
            selected: {_isRange},
            onSelectionChanged: (v) => setState(() {
              _isRange = v.first;
              if (!_isRange) _end = _start;
            }),
          ),
          const SizedBox(height: 12),
          if (_isRange)
            Row(
              children: [
                Expanded(child: _dateButton('bd_start_date', _start)),
                const SizedBox(width: 10),
                Expanded(child: _dateButton('bd_end_date', _end, isEnd: true)),
              ],
            )
          else
            _dateButton('bd_select_date', _start),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _appliesTo,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'bd_applies_to'.tr, border: const OutlineInputBorder()),
            items: [
              for (final entry in _appliesKeys.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value.tr)),
            ],
            onChanged: (v) => setState(() => _appliesTo = v ?? 'all'),
          ),
          if (_appliesTo != 'reservation') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _serviceId,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'bd_package'.tr, border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: null, child: Text('bd_all_packages'.tr)),
                for (final s in widget.services)
                  DropdownMenuItem(value: s.id, child: Text(s.name ?? '#${s.id}')),
                // Keep a saved package selectable even if the list didn't load.
                if (_serviceId != null && !widget.services.any((s) => s.id == _serviceId))
                  DropdownMenuItem(value: _serviceId, child: Text('#$_serviceId')),
              ],
              onChanged: (v) => setState(() => _serviceId = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('bd_active'.tr),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: CommonColors.darkBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('bd_save'.tr),
          ),
        ],
      ),
    );
  }
}
