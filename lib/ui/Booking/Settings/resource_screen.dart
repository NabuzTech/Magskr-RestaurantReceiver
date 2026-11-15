import 'package:flutter/material.dart';
import 'keyboard_safe_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/Booking V2/get_resource_booking_v2_model.dart';
import '../../../constants/constant.dart';
import '../../../constants/common_colors.dart';
import 'settings_header.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
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
  String? storeName;
  String? storeImageUrl;
  List<GetResourceBookingV2Model> resources = [];

  final Set<int> _busyIds = {};

  String selectedTab = 'All';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List<GetResourceBookingV2Model> get filteredResources {
    return resources.where((r) {
      final isActive = r.isActive ?? true;
      final matchesTab = selectedTab == 'All' ||
          (selectedTab == 'Active' && isActive) ||
          (selectedTab == 'Inactive' && !isActive);

      final query = searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty || (r.name ?? '').toLowerCase().contains(query);

      return matchesTab && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadResources();
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
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadResources() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      storeId = prefs.getString(valueShared_STORE_KEY) ?? '';

      final data = await CallService().resourceBookingV2(storeId);

      if (!mounted) return;
      setState(() {
        resources = data;
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
        onPressed: () => _showResourceForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: "Sora"),
        child: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Resources'),

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
                onRefresh: _loadResources,
                child: filteredResources.isEmpty
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
                  itemCount: filteredResources.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _resourceCard(filteredResources[index]),
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
            hintText: 'Search resources...',
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
      'All': resources.length,
      'Active': resources.where((r) => r.isActive ?? true).length,
      'Inactive': resources.where((r) => !(r.isActive ?? true)).length,
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
              onPressed: _loadResources,
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
                Icons.chair_alt_outlined,
                size: 38,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No resources yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to add your first resource.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESOURCE CARD
  // ============================================================

  Widget _resourceCard(GetResourceBookingV2Model resource) {
    final isBusy = _busyIds.contains(resource.id);
    final isActive = resource.isActive ?? true;

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
              _resourceThumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resource.name ?? 'Resource #${resource.id}',
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
                        _infoItem(Icons.groups_outlined,
                            'Capacity: ${resource.capacity ?? 0}'),
                        if ((resource.capacityMode ?? '').isNotEmpty)
                          _infoItem(Icons.tune_rounded, resource.capacityMode!),
                        _infoItem(Icons.sort_rounded,
                            'Order: ${resource.sortOrder ?? 0}'),
                      ],
                    ),
                  ],
                ),
              ),
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
                  onTap: isBusy ? null : () => _showResourceForm(resource: resource),
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
                  onTap: () => _confirmDelete(resource),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resourceThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: veryLightGreen,
        child: const Icon(Icons.chair_alt_outlined, color: primaryGreen, size: 26),
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

  void _confirmDelete(GetResourceBookingV2Model resource) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Resource?', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'This will permanently delete "${resource.name ?? 'this resource'}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteResource(resource);
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

  Future<void> _deleteResource(GetResourceBookingV2Model resource) async {
    final id = resource.id;
    if (id == null) return;

    setState(() => _busyIds.add(id));

    final error = await CallService().deleteResource(id);

    if (!mounted) return;
    setState(() => _busyIds.remove(id));

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted')),
      );
      _loadResources();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  // ============================================================
  // CREATE / EDIT FORM
  // ============================================================

  void _showResourceForm({GetResourceBookingV2Model? resource}) {
    final isEditing = resource != null;

    final nameController = TextEditingController(text: resource?.name ?? '');
    final capacityController =
    TextEditingController(text: '${resource?.capacity ?? 1}');
    String capacityMode =
        (resource?.capacityMode == 'exclusive' || resource?.capacityMode == 'pooled')
            ? resource!.capacityMode!
            : 'exclusive';
    final sortOrderController =
    TextEditingController(text: '${resource?.sortOrder ?? 0}');
    bool isActive = resource?.isActive ?? true;
    bool isSubmitting = false;

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
                  const SnackBar(content: Text('Please enter a resource name')),
                );
                return;
              }

              setModalState(() => isSubmitting = true);

              final body = {
                'store_id': int.tryParse(storeId) ?? 0,
                'name': nameController.text.trim(),
                'capacity': int.tryParse(capacityController.text) ?? 0,
                'capacity_mode': capacityMode,
                'is_active': isActive,
                'sort_order': int.tryParse(sortOrderController.text) ?? 0,
              };

              try {
                if (isEditing) {
                  await CallService().updateResource(body, '${resource.id}');
                } else {
                  await CallService().createResource(body);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Resource updated successfully'
                        : 'Resource created successfully'),
                  ),
                );
                _loadResources();
              } catch (e) {
                print('Resource form submit error: $e');
                setModalState(() => isSubmitting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Failed to update resource'
                        : 'Failed to create resource'),
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
              height: MediaQuery.of(context).size.height * .6,
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
                            isEditing ? 'Edit Resource' : 'Create Resource',
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
                          _formField('Resource Name', nameController),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _formField('Capacity', capacityController,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dropdownField(
                                  'Capacity Mode',
                                  capacityMode,
                                  const ['exclusive', 'pooled'],
                                  (v) => setModalState(() => capacityMode = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _formField('Sort Order', sortOrderController,
                              isNumber: true,
                              textInputAction: TextInputAction.done),
                          const SizedBox(height: 10),
                          _switchRow(
                            'Active',
                            isActive,
                                (v) => setModalState(() => isActive = v),
                          ),

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
                                  isEditing ? 'Save Changes' : 'Create Resource',
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

  Widget _dropdownField(
      String label,
      String value,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
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
          builder: (focusNode) => DropdownButtonFormField<String>(
          focusNode: focusNode,
          initialValue: value,
          style: const TextStyle(
            fontFamily: "Sora",
            color: Color(0xFF263238),
          ),
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
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
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
}
