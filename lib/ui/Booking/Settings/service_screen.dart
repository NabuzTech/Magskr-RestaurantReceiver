import 'dart:io';

import 'keyboard_safe_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/Booking V2/get_service_model.dart';
import '../../../models/Booking V2/get_resource_booking_v2_model.dart';
import '../../../constants/constant.dart';
import '../../../constants/common_colors.dart';
import 'settings_header.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryGreen = CommonColors.darkBlue;
  static const Color secondaryGreen = CommonColors.lightBlue;
  static const Color veryLightGreen = CommonColors.skyBlue;
  static const Color backgroundColor = Color(0xFFF3F8FF);

  static const Color acceptedColor = Color(0xFF2E9B63);
  static const Color declinedColor = Color(0xFFEF5350);

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  String? errorMessage;
  String storeId = '';
  List<GetServiceModel> services = [];
  List<GetResourceBookingV2Model> resources = [];
  String? storeName;
  String? storeImageUrl;

  final Set<int> _busyIds = {};

  String selectedTab = 'All';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List<GetServiceModel> get filteredServices {
    return services.where((s) {
      final isActive = s.isActive ?? true;
      final matchesTab = selectedTab == 'All' ||
          (selectedTab == 'Active' && isActive) ||
          (selectedTab == 'Inactive' && !isActive);

      final query = searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          (s.name ?? '').toLowerCase().contains(query) ||
          (s.description ?? '').toLowerCase().contains(query);

      return matchesTab && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadStoreInfo();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(valueShared_STORE_KEY) ?? '';

      final data = await CallService().resourceBookingV2(id);

      if (!mounted) return;
      setState(() => resources = data);
    } catch (e) {
      // resource dropdown stays empty on failure
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadServices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      storeId = prefs.getString(valueShared_STORE_KEY) ?? '';

      final data = await CallService().getBookingV2StoreServices(storeId);

      if (!mounted) return;
      setState(() {
        services = data;
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () => _showServiceForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: "Sora"),
        child: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Services'),

            _buildSearchSection(),

            _buildStatusTabs(),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
                  : errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadServices,
                child: filteredServices.isEmpty
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [_buildEmptyState()],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _serviceCard(filteredServices[index]),
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
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen),
            hintText: 'Search services...',
            hintStyle: TextStyle(
              fontSize: 12,
              fontFamily: "Sora",
              color: Colors.grey.shade500,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
              onPressed: () {
                searchController.clear();
                setState(() => searchQuery = '');
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
    final tabs = {
      'All': services.length,
      'Active': services.where((s) => s.isActive ?? true).length,
      'Inactive': services.where((s) => !(s.isActive ?? true)).length,
    };

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final title = tabs.keys.elementAt(index);
          final count = tabs.values.elementAt(index);
          final isSelected = selectedTab == title;

          return GestureDetector(
            onTap: () => setState(() => selectedTab = title),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              child: Text(
                '$title ($count)',
                style: TextStyle(
                  fontSize: 12,
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
            Text(
              errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadServices,
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
                Icons.design_services_outlined,
                size: 38,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No services yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to add your first service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  Widget _serviceCard(GetServiceModel service) {
    final isBusy = _busyIds.contains(service.id);
    final isActive = service.isActive ?? true;

    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _serviceThumbnail(service),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name ?? 'Service #${service.id}',
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
                    if ((service.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _infoItem(Icons.timer_outlined, '${service.durationMinutes ?? 0} min'),
              _infoItem(Icons.groups_outlined,
                  '${service.minParty ?? 0}-${service.maxParty ?? 0} guests'),
              if (service.price != null)
                _infoItem(Icons.currency_pound_rounded, '${service.price}'),
            ],
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: Colors.grey.withOpacity(.10)),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: primaryGreen,
                  onTap: isBusy ? null : () => _showServiceForm(service: service),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isBusy
                    ? const SizedBox(
                  height: 38,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: declinedColor,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                )
                    : _actionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: declinedColor,
                  onTap: () => _confirmDelete(service),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Uploaded URLs carry a presigned S3 query string (?X-Amz-...) that expires;
  // the image still loads without it, so strip it before display.
  String _trimmedImageUrl(String url) {
    final queryIndex = url.indexOf('?');
    return queryIndex == -1 ? url : url.substring(0, queryIndex);
  }

  Widget _serviceThumbnail(GetServiceModel service) {
    final imageUrl = service.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: veryLightGreen,
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: _trimmedImageUrl(imageUrl),
          fit: BoxFit.cover,
          memCacheWidth: 200,
          errorWidget: (_, __, ___) =>
          const Icon(Icons.design_services_outlined, color: primaryGreen),
        )
            : const Icon(Icons.design_services_outlined, color: primaryGreen, size: 26),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(GetServiceModel service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Service?', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'This will permanently delete "${service.name ?? 'this service'}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteService(service);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: declinedColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(GetServiceModel service) async {
    final id = service.id;
    if (id == null) return;

    setState(() => _busyIds.add(id));

    final error = await CallService().deleteService(id);

    if (!mounted) return;
    setState(() => _busyIds.remove(id));

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted')),
      );
      _loadServices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  // ============================================================
  // CREATE / EDIT FORM
  // ============================================================

  void _showServiceForm({GetServiceModel? service}) {
    final isEditing = service != null;

    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController =
    TextEditingController(text: service?.description ?? '');
    File? pickedImage;
    String? uploadedImageUrl = service?.imageUrl;
    int? selectedResourceId = service?.resourceId;
    final durationController =
    TextEditingController(text: '${service?.durationMinutes ?? 60}');
    final bufferController =
    TextEditingController(text: '${service?.bufferMinutes ?? 0}');
    final minPartyController =
    TextEditingController(text: '${service?.minParty ?? 1}');
    final maxPartyController =
    TextEditingController(text: '${service?.maxParty ?? 1}');
    const validPriceModes = ['flat', 'none', 'per_person'];
    String priceMode = validPriceModes.contains(service?.priceMode)
        ? service!.priceMode!
        : 'flat';
    final priceController = TextEditingController(text: '${service?.price ?? 0}');
    final depositAmountController =
    TextEditingController(text: '${service?.depositAmount ?? 0}');
    final slotIntervalController =
    TextEditingController(text: '${service?.slotIntervalMinutes ?? 0}');
    final leadTimeController =
    TextEditingController(text: '${service?.leadTimeMinutes ?? 0}');
    final bookingWindowController =
    TextEditingController(text: '${service?.bookingWindowDays ?? 0}');
    final sortOrderController =
    TextEditingController(text: '${service?.sortOrder ?? 0}');
    bool isActive = service?.isActive ?? true;
    bool requirePayment = service?.requirePayment ?? false;
    bool isSubmitting = false;

    final optionRows = <_ServiceOptionRow>[
      if (service?.options != null)
        for (final o in service!.options!) _ServiceOptionRow.fromOption(o),
    ];
    final hourRows = <_ServiceHourRow>[
      if (service?.hours != null)
        for (final h in service!.hours!) _ServiceHourRow.fromHour(h),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a service name')),
                );
                return;
              }
              if (selectedResourceId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a resource')),
                );
                return;
              }

              setModalState(() => isSubmitting = true);

              if (pickedImage != null) {
                try {
                  final uploaded = await CallService().uploadImage(pickedImage!);
                  uploadedImageUrl = uploaded.url;
                } catch (e) {
                  setModalState(() => isSubmitting = false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to upload image')),
                  );
                  return;
                }
              }

              final body = {
                'store_id': int.tryParse(storeId) ?? 0,
                'resource_id': selectedResourceId,
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
                'image_url': uploadedImageUrl ?? '',
                'duration_minutes': int.tryParse(durationController.text) ?? 0,
                'buffer_minutes': int.tryParse(bufferController.text) ?? 0,
                'min_party': int.tryParse(minPartyController.text) ?? 0,
                'max_party': int.tryParse(maxPartyController.text) ?? 0,
                'price_mode': priceMode,
                'price': int.tryParse(priceController.text) ?? 0,
                'deposit_amount': int.tryParse(depositAmountController.text) ?? 0,
                'require_payment': requirePayment,
                'slot_interval_minutes': int.tryParse(slotIntervalController.text) ?? 0,
                'lead_time_minutes': int.tryParse(leadTimeController.text) ?? 0,
                'booking_window_days': int.tryParse(bookingWindowController.text) ?? 0,
                'is_active': isActive,
                'sort_order': int.tryParse(sortOrderController.text) ?? 0,
                'options': optionRows.map((o) => o.toJson()).toList(),
                'hours': hourRows.map((h) => h.toJson()).toList(),
              };

              try {
                if (isEditing) {
                  await CallService().updateService(body, '${service.id}');
                } else {
                  await CallService().createService(body);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Service updated successfully'
                        : 'Service created successfully'),
                  ),
                );
                _loadServices();
              } catch (e) {
                print('Service form submit error: $e');
                setModalState(() => isSubmitting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Failed to update service'
                        : 'Failed to create service'),
                  ),
                );
              }
            }

            return DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: "Sora"),
              child: AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Service' : 'Create Service',
                            style: const TextStyle(
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
                          Center(
                            child: _imagePicker(
                              pickedImage: pickedImage,
                              existingUrl: uploadedImageUrl,
                              onPick: () => _pickServiceImage(setModalState, (file) {
                                pickedImage = file;
                              }),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _formField('Service Name', nameController),
                          const SizedBox(height: 14),
                          _formField('Description (optional)', descriptionController,
                              maxLines: 3),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdownField<int>('Resource',
                                  selectedResourceId,
                                  [
                                    ...resources.where((r) => r.id != null && ((r.isActive ?? true) || r.id == selectedResourceId)).map(
                                          (r) => DropdownMenuItem(
                                        value: r.id,
                                        child: Text(r.name ?? 'Resource #${r.id}'),
                                      ),
                                    ),
                                    if (selectedResourceId != null &&
                                        !resources.any((r) => r.id == selectedResourceId))
                                      DropdownMenuItem(
                                        value: selectedResourceId,
                                        child: Text('Resource #$selectedResourceId'),
                                      ),
                                  ],
                                  (v) => setModalState(() => selectedResourceId = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _formField('Sort Order', sortOrderController,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _formField('Duration (min)', durationController,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formField('Buffer (min)', bufferController,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _formField('Min Party', minPartyController,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formField('Max Party', maxPartyController,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdownField<String>(
                                  'Price Mode',
                                  priceMode,
                                  validPriceModes
                                      .map((m) =>
                                      DropdownMenuItem(value: m, child: Text(m)))
                                      .toList(),
                                  (v) => setModalState(() => priceMode = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formField('Price', priceController,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _formField('Deposit Amount', depositAmountController,
                              isNumber: true),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _formField(
                                    'Slot Interval (min)', slotIntervalController,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formField('Lead Time (min)', leadTimeController,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _formField('Booking Window (days)', bookingWindowController,
                              isNumber: true,
                              textInputAction: TextInputAction.done),
                          const SizedBox(height: 10),
                          _switchRow(
                            'Require Payment',
                            requirePayment,
                                (v) => setModalState(() => requirePayment = v),
                          ),
                          _switchRow(
                            'Active',
                            isActive,
                                (v) => setModalState(() => isActive = v),
                          ),

                          const SizedBox(height: 22),

                          _sectionTitle('Options', () {
                            setModalState(() => optionRows.add(_ServiceOptionRow()));
                          }),
                          const SizedBox(height: 10),
                          if (optionRows.isEmpty)
                            Text(
                              'No options added.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            )
                          else
                            for (int i = 0; i < optionRows.length; i++) ...[
                              _optionRowCard(
                                optionRows[i],
                                    () => setModalState(() => optionRows.removeAt(i)),
                                setModalState,
                              ),
                              const SizedBox(height: 10),
                            ],

                          const SizedBox(height: 12),

                          _sectionTitle('Hours', () {
                            setModalState(() => hourRows.add(_ServiceHourRow()));
                          }),
                          const SizedBox(height: 10),
                          if (hourRows.isEmpty)
                            Text(
                              'No hours added.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            )
                          else
                            for (int i = 0; i < hourRows.length; i++) ...[
                              _hourRowCard(
                                hourRows[i],
                                    () => setModalState(() => hourRows.removeAt(i)),
                                setModalState,
                              ),
                              const SizedBox(height: 10),
                            ],

                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: isSubmitting ? null : submit,
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
                                    : Text(
                                  isEditing ? 'Save Changes' : 'Create Service',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _imagePicker({
    required File? pickedImage,
    required String? existingUrl,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: veryLightGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.lightBlue),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: pickedImage != null
              ? Image.file(pickedImage, fit: BoxFit.cover)
              : (existingUrl != null && existingUrl.isNotEmpty)
              ? CachedNetworkImage(
            imageUrl: _trimmedImageUrl(existingUrl),
            fit: BoxFit.cover,
            memCacheWidth: 200,
            errorWidget: (_, __, ___) =>
            const Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 26),
          )
              : const Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 26),
        ),
      ),
    );
  }

  Future<void> _pickServiceImage(
      StateSetter setModalState, ValueChanged<File> onPicked) async {
    final picker = ImagePicker();

    Future<void> pick(ImageSource source) async {
      Navigator.pop(context);
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setModalState(() => onPicked(File(image.path)));
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: primaryGreen),
              title: const Text('Camera'),
              onTap: () => pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: primaryGreen),
              title: const Text('Gallery'),
              onTap: () => pick(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        TextInputAction textInputAction = TextInputAction.next,
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
          maxLines: maxLines,
          // iOS' numeric keypad has no return/next key, so use the normal
          // text keyboard and restrict input to digits instead.
          keyboardType: isNumber ? TextInputType.text : keyboardType,
          inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          textInputAction: textInputAction,
          style: const TextStyle(fontFamily: "Sora"),
          decoration: InputDecoration(
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

  Widget _dropdownField<T>(String label, T? value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged,) {
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
        KeyboardSafeDropdown(
          builder: (focusNode) => DropdownButtonFormField<T>(
          focusNode: focusNode,
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(
            fontFamily: "Sora",
            color: Color(0xFF263238),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          items: items,
          onChanged: onChanged,
        ),
        ),
      ],
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
        Switch(value: value, activeColor: primaryGreen, onChanged: onChanged),
      ],
    );
  }

  Widget _sectionTitle(String title, VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: veryLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: primaryGreen),
                SizedBox(width: 3),
                Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionRowCard(
      _ServiceOptionRow row,
      VoidCallback onRemove,
      StateSetter setModalState,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _formField('Option Name', row.nameController)),
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline_rounded,
                      color: declinedColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _formField('Price Delta', row.priceDeltaController,
                    isNumber: true, textInputAction: TextInputAction.done),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdownField<String>(
                  'Price Mode',
                  row.priceMode,
                  const ['flat', 'none', 'per_person']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  (v) => setModalState(() => row.priceMode = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _switchRow(
                  'Default',
                  row.isDefault,
                      (v) => setModalState(() => row.isDefault = v),
                ),
              ),
              Expanded(
                child: _switchRow(
                  'Active',
                  row.isActive,
                      (v) => setModalState(() => row.isActive = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // day_of_week convention across the app: 0 = Monday ... 6 = Sunday
  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Widget _hourRowCard(
      _ServiceHourRow row,
      VoidCallback onRemove,
      StateSetter setModalState,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: row.dayOfWeek,
                    isExpanded: true,
                    items: List.generate(
                      7,
                          (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          _weekdayNames[i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Sora",
                          ),
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setModalState(() => row.dayOfWeek = v);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline_rounded,
                      color: declinedColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timeField('Start Time', row.startTime, (t) {
                  setModalState(() => row.startTime = t);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeField('End Time', row.endTime, (t) {
                  setModalState(() => row.endTime = t);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay value, ValueChanged<TimeOfDay> onPicked) {
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
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: value);
            if (picked != null) onPicked(picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.lightBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: primaryGreen),
                const SizedBox(width: 7),
                Text(
                  value.format(context),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// OPTION / HOUR ROW MODELS (form-local, not persisted directly)
// ============================================================

class _ServiceOptionRow {
  final TextEditingController nameController;
  final TextEditingController priceDeltaController;
  String priceMode;
  bool isDefault;
  bool isActive;

  _ServiceOptionRow({
    String name = '',
    int priceDelta = 0,
    this.priceMode = 'flat',
    this.isDefault = false,
    this.isActive = true,
  })  : nameController = TextEditingController(text: name),
        priceDeltaController = TextEditingController(text: '$priceDelta');

  factory _ServiceOptionRow.fromOption(ServiceOption o) => _ServiceOptionRow(
    name: o.name ?? '',
    priceDelta: o.priceDelta ?? 0,
    priceMode: const ['flat', 'none', 'per_person'].contains(o.priceMode)
        ? o.priceMode!
        : 'flat',
    isDefault: o.isDefault ?? false,
    isActive: o.isActive ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': nameController.text.trim(),
    'price_delta': int.tryParse(priceDeltaController.text) ?? 0,
    'price_mode': priceMode,
    'is_default': isDefault,
    'is_active': isActive,
    'sort_order': 0,
  };
}

class _ServiceHourRow {
  int dayOfWeek;
  TimeOfDay startTime;
  TimeOfDay endTime;

  _ServiceHourRow({
    this.dayOfWeek = 0,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  })  : startTime = startTime ?? const TimeOfDay(hour: 9, minute: 0),
        endTime = endTime ?? const TimeOfDay(hour: 17, minute: 0);

  factory _ServiceHourRow.fromHour(ServiceHour h) {
    return _ServiceHourRow(
      dayOfWeek: h.dayOfWeek ?? 0,
      startTime: _parseTime(h.startTime) ?? const TimeOfDay(hour: 9, minute: 0),
      endTime: _parseTime(h.endTime) ?? const TimeOfDay(hour: 17, minute: 0),
    );
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'start_time': _fmt(startTime),
    'end_time': _fmt(endTime),
  };
}
