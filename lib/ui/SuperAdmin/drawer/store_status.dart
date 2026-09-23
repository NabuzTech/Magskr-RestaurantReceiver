import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/admin/store_status_model.dart';

class StoreStatus extends StatefulWidget {
  const StoreStatus({super.key});

  @override
  State<StoreStatus> createState() => _StoreStatusState();
}

class _StoreStatusState extends State<StoreStatus> {
  List<storeStatusModel> stores = [];
  bool isLoading = true;
  String selectedTab = 'all';
  final Set<int> updatingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final list = await CallService().getActiveStore();
      setState(() => stores = list);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stores: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<storeStatusModel> get _filtered {
    switch (selectedTab) {
      case 'visible':
        return stores.where((s) => s.isActive == true).toList();
      case 'hidden':
        return stores.where((s) => s.isActive != true).toList();
      default:
        return stores;
    }
  }

  Future<void> _toggle(storeStatusModel store, bool value) async {
    if (store.id == null || updatingIds.contains(store.id)) return;
    final previous = store.isActive;
    setState(() {
      store.isActive = value;
      updatingIds.add(store.id!);
    });
    try {
      await CallService().updateStoreActive({'is_active': value}, store.id.toString());
    } catch (e) {
      setState(() => store.isActive = previous);
      Get.snackbar('Error', 'Failed to update store status: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => updatingIds.remove(store.id));
    }
  }

  Widget _tabButton(String key, String label) {
    final selected = selectedTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: selected ? Colors.orange : Colors.transparent, width: 1.4),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Store Status', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffF3F3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _tabButton('all', 'All'),
                  _tabButton('visible', 'Visible'),
                  _tabButton('hidden', 'Hidden'),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('No stores found', style: TextStyle(fontFamily: 'Mulish')))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final s = list[index];
                            final isActive = s.isActive ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFFF1E8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.storefront_outlined, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.name ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 14)),
                                        Text('ID: ${s.id ?? '-'}',
                                            style: const TextStyle(fontFamily: 'Mulish', fontSize: 12, color: Colors.blueGrey)),
                                        if ((s.address ?? '').isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Row(
                                              children: [
                                                Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade600),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    s.address ?? '',
                                                    style: TextStyle(fontFamily: 'Mulish', fontSize: 11, color: Colors.grey.shade600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? 'Visible' : 'Hidden',
                                          style: const TextStyle(fontFamily: 'Mulish', fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      updatingIds.contains(s.id)
                                          ? const SizedBox(
                                              height: 24,
                                              width: 36,
                                              child: Center(
                                                child: SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            )
                                          : Switch(
                                              value: isActive,
                                              activeColor: Colors.green,
                                              onChanged: (v) => _toggle(s, v),
                                            ),
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
