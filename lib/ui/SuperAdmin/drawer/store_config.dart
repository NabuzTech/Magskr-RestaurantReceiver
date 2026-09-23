import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/admin/store_config_model.dart';
import 'add_edit_store_config.dart';

class StoreConfig extends StatefulWidget {
  const StoreConfig({super.key});

  @override
  State<StoreConfig> createState() => _StoreConfigState();
}

class _StoreConfigState extends State<StoreConfig> {
  List<GetStoreConfigModel> configs = [];
  List<GetStoreConfigModel> filtered = [];
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int offset = 0;
  static const int limit = 20;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(_filter);
    scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!hasMore || isLoadingMore || isLoading) return;
    if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _filter() {
    final q = searchCtrl.text.toLowerCase();
    setState(() {
      filtered = q.isEmpty
          ? configs
          : configs.where((c) {
              return (c.appName ?? '').toLowerCase().contains(q) ||
                  (c.domain ?? '').toLowerCase().contains(q) ||
                  (c.storeId?.toString() ?? '').contains(q);
            }).toList();
    });
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      offset = 0;
      hasMore = true;
    });
    try {
      final list = await CallService().getStoreConfig(limit: limit, offset: 0);
      list.sort((a, b) => (a.storeId ?? 0).compareTo(b.storeId ?? 0));
      setState(() {
        configs = list;
        offset = list.length;
        hasMore = list.length >= limit;
      });
      _filter();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load store configs: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => isLoadingMore = true);
    try {
      final list = await CallService().getStoreConfig(limit: limit, offset: offset);
      if (list.length < limit) hasMore = false;
      configs.addAll(list);
      configs.sort((a, b) => (a.storeId ?? 0).compareTo(b.storeId ?? 0));
      offset += list.length;
      _filter();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more configs: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoadingMore = false);
    }
  }

  Future<void> _openForm({GetStoreConfigModel? existing}) async {
    final result = await Get.to(() => AddEditStoreConfig(existing: existing));
    if (result == true) _load();
  }

  void _confirmDelete(GetStoreConfigModel c) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Config'),
        content: Text('Delete config for "${c.appName ?? c.domain}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              _delete(c);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(GetStoreConfigModel c) async {
    if (c.domain == null) return;
    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 100, height: 100)),
      barrierDismissible: false,
    );
    final ok = await CallService().deleteStoreConfig(c.domain!);
    if (Get.isDialogOpen ?? false) Get.back();
    if (ok) {
      Get.snackbar('Deleted', 'Config removed', backgroundColor: Colors.green, colorText: Colors.white);
      _load();
    } else {
      Get.snackbar('Error', 'Failed to delete config', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String _link(GetStoreConfigModel c) {
    if (c.subdomain != null && c.subdomain!.isNotEmpty) {
      return '${c.domain}/${c.subdomain}/';
    }
    return c.domain ?? '';
  }

  Widget _tag(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Mulish')),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Mulish')),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Store Domain Config', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search configs...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No configs found', style: TextStyle(fontFamily: 'Mulish')))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final c = filtered[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '#${c.storeId ?? '-'}  ${c.appName ?? ''}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            GestureDetector(
                                              onTap: () => launchUrl(Uri.parse('https://${_link(c)}'), mode: LaunchMode.externalApplication),
                                              child: Text(
                                                _link(c),
                                                style: const TextStyle(color: Colors.orange, fontFamily: 'Mulish', fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () => _openForm(existing: c),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                            onPressed: () => _confirmDelete(c),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      _tag('Base Route', c.appBaseRoute ?? '-'),
                                      _tag('Country', c.country ?? '-'),
                                      _tag('Distance Delivery', (c.useDistanceDelivery ?? false) ? 'Yes' : 'No'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
