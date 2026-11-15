import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/Booking V2/blackouts_booking_v2_model.dart';
import '../../../models/Booking V2/get_service_model.dart';
import '../../../constants/constant.dart';
import '../../../constants/common_colors.dart';
import 'settings_header.dart';

class TimeManagementScreen extends StatefulWidget {
  const TimeManagementScreen({super.key});

  @override
  State<TimeManagementScreen> createState() => _TimeManagementScreenState();
}

class _TimeManagementScreenState extends State<TimeManagementScreen> {
  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;
  static const Color backgroundColor = Color(0xFFF3F8FF);
  static const Color acceptedColor = Color(0xFF2E9B63);
  static const Color declinedColor = Color(0xFFEF5350);

  static const List<String> dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  String? storeName;
  String? storeImageUrl;
  String storeId = '';
  List<GetServiceModel> services = [];
  GetServiceModel? selectedService;
  int selectedDay = 0; // Monday = 0 ... Sunday = 6

  bool isLoading = true;
  String? errorMessage;
  List<BlackoutsBookingV2Model> blackouts = [];

  bool isSelecting = false;
  final Set<int> selectedIds = {};
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    _init();
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

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString(valueShared_STORE_KEY) ?? '';
    try {
      final svcs = (await CallService().getBookingV2StoreServices(storeId))
          .where((s) => s.isActive ?? true)
          .toList();
      if (!mounted) return;
      setState(() {
        services = svcs;
        selectedService = svcs.isNotEmpty ? svcs.first : null;
      });
      if (selectedService != null) {
        await _loadBlackouts();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load services';
        isLoading = false;
      });
    }
  }

  Future<void> _loadBlackouts() async {
    if (selectedService?.id == null) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      isSelecting = false;
      selectedIds.clear();
    });
    try {
      final data = await CallService().blackoutsBookingV2(
        int.tryParse(storeId) ?? 0,
        selectedService!.id!,
        selectedDay,
      );
      if (!mounted) return;
      setState(() {
        blackouts = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load blackout slots';
        isLoading = false;
      });
    }
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  TimeOfDay _parseTime(String? s) {
    if (s == null || s.isEmpty) return TimeOfDay.now();
    final clean = s.split('.').first;
    final parts = clean.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTimeForApi(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00.000Z';
  }

  String _formatTimeForDisplay(String? s) {
    final t = _parseTime(s);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isSelecting
          ? null
          : FloatingActionButton(
              backgroundColor: primaryGreen,
              onPressed: _showBlackoutForm,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: "Sora"),
        child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildServiceSelector(),
            _buildDaySelector(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryGreen))
                  : errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          color: primaryGreen,
                          onRefresh: _loadBlackouts,
                          child: blackouts.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  children: [_buildEmptyState()],
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: blackouts.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _blackoutCard(blackouts[index]),
                                  ),
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
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    if (isSelecting) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF263238)),
              onPressed: () => setState(() {
                isSelecting = false;
                selectedIds.clear();
              }),
            ),
            Expanded(
              child: Text(
                '${selectedIds.length} selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ),
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: declinedColor, strokeWidth: 2.2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: primaryGreen),
                    onPressed: selectedIds.isEmpty ? null : _confirmDeleteSelected,
                  ),
          ],
        ),
      );
    }
    return const SettingsHeader(title: 'Time Management');
  }

  // ============================================================
  // SERVICE / DAY SELECTORS
  // ============================================================

  Widget _buildServiceSelector() {
    if (services.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.lightBlue),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<GetServiceModel>(
            isExpanded: true,
            value: selectedService,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: primaryGreen),
            items: services
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.name ?? 'Service #${s.id}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ))
                .toList(),
            onChanged: (s) {
              setState(() => selectedService = s);
              _loadBlackouts();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        itemCount: dayLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedDay == index;
          return GestureDetector(
            onTap: () {
              setState(() => selectedDay = index);
              _loadBlackouts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [primaryGreen, secondaryGreen])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.lightBlue,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                dayLabels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
  // ERROR / EMPTY STATE
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
            Text(errorMessage ?? 'Something went wrong',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadBlackouts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white, fontFamily: "Sora")),
            ),
          ],
        ),
      ),
    );
  }

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
              decoration:
                  const BoxDecoration(color: veryLightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.block_outlined, size: 38, color: primaryGreen),
            ),
            const SizedBox(height: 16),
            const Text('No blackout slots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to block time for ${dayLabels[selectedDay]}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BLACKOUT CARD
  // ============================================================

  Widget _blackoutCard(BlackoutsBookingV2Model item) {
    final isActive = item.isActive ?? true;
    final isChecked = item.id != null && selectedIds.contains(item.id);

    return GestureDetector(
      onLongPress: () {
        if (item.id == null) return;
        setState(() {
          isSelecting = true;
          selectedIds.add(item.id!);
        });
      },
      onTap: () {
        if (isSelecting) {
          if (item.id == null) return;
          setState(() {
            if (isChecked) {
              selectedIds.remove(item.id);
              if (selectedIds.isEmpty) isSelecting = false;
            } else {
              selectedIds.add(item.id!);
            }
          });
        } else {
          _showBlackoutForm(existing: item);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChecked ? primaryGreen : Colors.lightBlue,
            width: isChecked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelecting) ...[
              Icon(
                isChecked ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isChecked ? primaryGreen : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name ?? 'Blackout #${item.id}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ),
                      _statusChip(isActive ? 'ACTIVE' : 'INACTIVE',
                          isActive ? acceptedColor : Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _infoItem(Icons.schedule_rounded,
                          '${_formatTimeForDisplay(item.startTime)} - ${_formatTimeForDisplay(item.endTime)}'),
                      _infoItem(Icons.sort_rounded, 'Order: ${item.sortOrder ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryGreen),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ============================================================
  // DELETE (multi-select)
  // ============================================================

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Blackout(s)?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('This will permanently delete ${selectedIds.length} slot(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteSelected();
            },
            child: const Text('Delete',
                style: TextStyle(color: declinedColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (selectedService?.id == null || selectedIds.isEmpty) return;
    setState(() => isDeleting = true);

    final error = await CallService().deleteBlackouts(
      int.tryParse(storeId) ?? 0,
      selectedIds.toList(),
      selectedService!.id!,
      selectedDay,
    );

    if (!mounted) return;
    setState(() => isDeleting = false);

    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Blackout slot(s) deleted')));
      _loadBlackouts();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // ============================================================
  // CREATE (multiple slots) / EDIT (single) FORM
  // ============================================================

  void _showBlackoutForm({BlackoutsBookingV2Model? existing}) {
    final isEditing = existing != null;

    if (!isEditing && selectedService?.id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a service first')));
      return;
    }

    final blocks = <_BlockDraft>[
      _BlockDraft(
        name: existing?.name ?? '',
        start: _parseTime(existing?.startTime),
        end: _parseTime(existing?.endTime ?? '11:00'),
        isActive: existing?.isActive ?? true,
        sortOrder: existing?.sortOrder ?? 0,
      ),
    ];

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              for (final b in blocks) {
                if (b.name.trim().isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Please enter a name for every slot')));
                  return;
                }
              }

              setModalState(() => isSubmitting = true);

              try {
                if (isEditing) {
                  final b = blocks.first;
                  final body = {
                    'name': b.name.trim(),
                    'service_id': selectedService!.id,
                    'day_of_week': selectedDay,
                    'start_time': _formatTimeForApi(b.start),
                    'end_time': _formatTimeForApi(b.end),
                    'is_active': b.isActive,
                    'sort_order': b.sortOrder,
                  };
                  await CallService().updateBlackout(body, '${existing.id}');
                } else {
                  final body = {
                    'store_id': int.tryParse(storeId) ?? 0,
                    'blocks': blocks
                        .map((b) => {
                              'name': b.name.trim(),
                              'service_id': selectedService!.id,
                              'day_of_week': selectedDay,
                              'start_time': _formatTimeForApi(b.start),
                              'end_time': _formatTimeForApi(b.end),
                              'is_active': b.isActive,
                              'sort_order': b.sortOrder,
                            })
                        .toList(),
                  };
                  await CallService().createBlackouts(body);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Blackout slot updated successfully'
                        : 'Blackout slot(s) created successfully'),
                  ),
                );
                _loadBlackouts();
              } catch (e) {
                setModalState(() => isSubmitting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Failed to update blackout slot'
                        : 'Failed to create blackout slot(s)'),
                  ),
                );
              }
            }

            return DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: "Sora"),
              child: Container(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .85),
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Blackout Slot' : 'Create Blackout Slot(s)',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration:
                                const BoxDecoration(color: veryLightGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${selectedService?.name ?? ''} · ${dayLabels[selectedDay]}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < blocks.length; i++) ...[
                            _blockDraftCard(
                              index: i,
                              draft: blocks[i],
                              canRemove: blocks.length > 1,
                              setModalState: setModalState,
                              onRemove: () => setModalState(() => blocks.removeAt(i)),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!isEditing)
                            GestureDetector(
                              onTap: () => setModalState(
                                  () => blocks.add(_BlockDraft(start: TimeOfDay.now(), end: TimeOfDay.now()))),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primaryGreen, style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, color: primaryGreen, size: 18),
                                    SizedBox(width: 6),
                                    Text('Add another slot',
                                        style: TextStyle(
                                            color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: isSubmitting ? null : submit,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [primaryGreen, secondaryGreen]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.4),
                                      )
                                    : Text(
                                        isEditing ? 'Save Changes' : 'Create Slot(s)',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ),
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

  Widget _blockDraftCard({
    required int index,
    required _BlockDraft draft,
    required bool canRemove,
    required void Function(void Function()) setModalState,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Slot ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.delete_outline_rounded, color: declinedColor, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _formField(
            'Name',
            initialValue: draft.name,
            onChanged: (v) => draft.name = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeField(
                  label: 'Start Time',
                  time: draft.start,
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: draft.start);
                    if (picked != null) setModalState(() => draft.start = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeField(
                  label: 'End Time',
                  time: draft.end,
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: draft.end);
                    if (picked != null) setModalState(() => draft.end = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _formField(
                  'Sort Order',
                  initialValue: '${draft.sortOrder}',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => draft.sortOrder = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _switchRow(
                  'Active',
                  draft.isActive,
                  (v) => setModalState(() => draft.isActive = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeField({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.lightBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: primaryGreen),
                const SizedBox(width: 8),
                Text(time.format(context), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formField(
    String label, {
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 7),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontFamily: "Sora"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.lightBlue)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.lightBlue)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF263238))),
        ),
        Switch(value: value, activeColor: primaryGreen, onChanged: onChanged),
      ],
    );
  }
}

class _BlockDraft {
  String name;
  TimeOfDay start;
  TimeOfDay end;
  bool isActive;
  int sortOrder;

  _BlockDraft({
    this.name = '',
    required this.start,
    required this.end,
    this.isActive = true,
    this.sortOrder = 0,
  });
}
