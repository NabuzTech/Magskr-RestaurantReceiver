import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/Reservation V2/get_today_received_reservationV2_superAdmin.dart';

class AllStoreReservationV2 extends StatefulWidget {
  const AllStoreReservationV2({super.key});

  @override
  State<AllStoreReservationV2> createState() => _AllStoreReservationV2State();
}

class _AllStoreReservationV2State extends State<AllStoreReservationV2> {
  bool isLoading = false;
  List<Stores> stores = [];
  Totals? totals;
  Stores? selectedStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getReservation();
    });
  }

  Map<String, Color> _storeColors(int? storeId) {
    switch (storeId) {
      case 12:
        return {'border': const Color(0xff029543), 'background': const Color(0xffEBFAF2), 'nameColor': const Color(0xff029543)};
      case 13:
        return {'border': const Color(0xffE4121E), 'background': const Color(0xffFCF6F7), 'nameColor': const Color(0xffE4121E)};
      case 14:
        return {'border': const Color(0xff841D1C), 'background': const Color(0xffF6EDED), 'nameColor': const Color(0xff841D1C)};
      case 15:
        return {'border': const Color(0xff023047), 'background': const Color(0xffFAFDFF), 'nameColor': const Color(0xff023047)};
      case 16:
        return {'border': const Color(0xff624BA1), 'background': const Color(0x0ffdfcff), 'nameColor': const Color(0xff624BA1)};
      case 18:
        return {'border': const Color(0xffE0D2AA), 'background': const Color(0xffFAF3E0), 'nameColor': const Color(0xffE64425)};
      case 19:
        return {'border': const Color(0xffF9CC46), 'background': const Color(0xffFDFAF1), 'nameColor': const Color(0xff029447)};
      case 20:
        return {'border': const Color(0xffE31E22), 'background': const Color(0xffFFDCDD), 'nameColor': const Color(0xffE31E22)};
      case 21:
        return {'border': const Color(0xff0D9488), 'background': const Color(0xffF0FDFA), 'nameColor': const Color(0xff0D9488)};
      case 22:
        return {'border': const Color(0xffEA580C), 'background': const Color(0xffFFF7ED), 'nameColor': const Color(0xffEA580C)};
      case 23:
        return {'border': const Color(0xff4338CA), 'background': const Color(0xffEEF2FF), 'nameColor': const Color(0xff4338CA)};
      case 24:
        return {'border': const Color(0xffDB2777), 'background': const Color(0xffFDF2F8), 'nameColor': const Color(0xffDB2777)};
      case 25:
        return {'border': const Color(0xff4D7C0F), 'background': const Color(0xffF7FEE7), 'nameColor': const Color(0xff4D7C0F)};
      case 26:
        return {'border': const Color(0xff0E7490), 'background': const Color(0xffECFEFF), 'nameColor': const Color(0xff0E7490)};
      case 27:
        return {'border': const Color(0xffBE123C), 'background': const Color(0xffFFF1F2), 'nameColor': const Color(0xffBE123C)};
      case 28:
        return {'border': const Color(0xffB45309), 'background': const Color(0xffFEF3C7), 'nameColor': const Color(0xffB45309)};
      case 29:
        return {'border': const Color(0xff047857), 'background': const Color(0xffECFDF5), 'nameColor': const Color(0xff047857)};
      case 30:
        return {'border': const Color(0xff6D28D9), 'background': const Color(0xffF5F3FF), 'nameColor': const Color(0xff6D28D9)};
      case 31:
        return {'border': const Color(0xff0369A1), 'background': const Color(0xffF0F9FF), 'nameColor': const Color(0xff0369A1)};
      case 32:
        return {'border': const Color(0xffA21CAF), 'background': const Color(0xffFDF4FF), 'nameColor': const Color(0xffA21CAF)};
      case 33:
        return {'border': const Color(0xff78350F), 'background': const Color(0xffFDF6EC), 'nameColor': const Color(0xff78350F)};
      case 34:
        return {'border': const Color(0xff475569), 'background': const Color(0xffF8FAFC), 'nameColor': const Color(0xff475569)};
      default:
        return {'border': const Color(0xffE0D2AA), 'background': Colors.white, 'nameColor': const Color(0xffE64425)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = selectedStore?.summary ?? totals;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey, width: 1),
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Icon(Icons.arrow_back_ios, size: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Received Reservations Today',
                            style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (totals?.total != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.green, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Total: ${totals!.total}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 165,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(left: 5),
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      final colors = _storeColors(store.storeId);
                      final isSelected = selectedStore?.storeId == store.storeId;
                      final summary = store.summary;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedStore = isSelected ? null : store;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(width: isSelected ? 2 : 1, color: colors['border']!),
                            color: colors['background'],
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colors['border']!.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID : ${store.storeId}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Mulish'),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: Text(
                                  store.storeName ?? '',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Mulish', color: colors['nameColor']),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Total : ${summary?.total ?? 0}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
                              ),
                              Text(
                                'Booked : ${summary?.booked ?? 0}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
                              ),
                              if ((summary?.pending ?? 0) > 0)
                                Text(
                                  'Pending : ${summary?.pending}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Mulish', color: Colors.orange),
                                ),
                              if ((summary?.cancelled ?? 0) > 0)
                                Text(
                                  'Cancelled : ${summary?.cancelled}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Mulish', color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedStore != null ? selectedStore!.storeName ?? '' : 'All stores',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                      ),
                      if (selectedStore != null)
                        GestureDetector(
                          onTap: () => setState(() => selectedStore = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                            child: const Text(
                              'Show All',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Mulish', fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true))
                : stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No reservations found',
                              style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Mulish', fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _summaryCard(detail),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Mulish', fontSize: 13, fontWeight: FontWeight.w600)),
          Text(
            '${value ?? 0}',
            style: TextStyle(fontFamily: 'Mulish', fontSize: 13, fontWeight: FontWeight.w800, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(Totals? detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedStore != null ? '${selectedStore!.storeName} Summary' : 'All Stores Summary',
            style: const TextStyle(fontFamily: 'Mulish', fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const Divider(),
          _statRow('Total', detail?.total),
          _statRow('Booked', detail?.booked, color: Colors.green),
          _statRow('Pending', detail?.pending, color: Colors.orange),
          _statRow('Cancelled', detail?.cancelled, color: Colors.red),
          _statRow('Active Total', detail?.activeTotal),
          _statRow('Booked Covers', detail?.bookedCovers),
          _statRow('Pending Covers', detail?.pendingCovers),
          _statRow('Active Covers', detail?.activeCovers),
          if ((detail?.upcomingTotal ?? 0) > 0) ...[
            const Divider(),
            _statRow('Upcoming Total', detail?.upcomingTotal),
            _statRow('Upcoming Booked', detail?.upcomingBooked),
            _statRow('Upcoming Pending', detail?.upcomingPending),
          ],
        ],
      ),
    );
  }

  Future<void> getReservation() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final model = await CallService().gettingTodayReceivedReservationV2SuperAdmin();

      if (!mounted) return;
      setState(() {
        stores = model.stores ?? [];
        totals = model.totals;
        selectedStore = null;
        isLoading = false;
      });
    } catch (e) {
      print('Error getting Store Reservation V2: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      Get.snackbar('Error', 'Failed to load Store Reservations',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
