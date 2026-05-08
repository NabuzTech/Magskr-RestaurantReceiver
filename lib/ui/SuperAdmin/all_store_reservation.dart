import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../models/get_all_reservation_for_all_store.dart';

class AllStoreReservation extends StatefulWidget {
  const AllStoreReservation({super.key});

  @override
  State<AllStoreReservation> createState() => _AllStoreReservationState();
}

class _AllStoreReservationState extends State<AllStoreReservation> {
  bool isLoading = false;
  List<Stores> stores = [];
  int? total;
  DateTime selectedDate = DateTime.now();
  Stores? selectedStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getReservation();
    });
  }

  String get _formattedApiDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.green),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedStore = null;
      });
      getReservation();
    }
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
      case 20: return {'border': const Color(0xffE31E22), 'background': const Color(0xffFFDCDD), 'nameColor': const Color(0xffE31E22)};
      case 21: return {'border': const Color(0xff0D9488), 'background': const Color(0xffF0FDFA), 'nameColor': const Color(0xff0D9488)};
      case 22: return {'border': const Color(0xffEA580C), 'background': const Color(0xffFFF7ED), 'nameColor': const Color(0xffEA580C)};
      case 23: return {'border': const Color(0xff4338CA), 'background': const Color(0xffEEF2FF), 'nameColor': const Color(0xff4338CA)};
      case 24: return {'border': const Color(0xffDB2777), 'background': const Color(0xffFDF2F8), 'nameColor': const Color(0xffDB2777)};
      case 25: return {'border': const Color(0xff4D7C0F), 'background': const Color(0xffF7FEE7), 'nameColor': const Color(0xff4D7C0F)};
      case 26: return {'border': const Color(0xff0E7490), 'background': const Color(0xffECFEFF), 'nameColor': const Color(0xff0E7490)};
      case 27: return {'border': const Color(0xffBE123C), 'background': const Color(0xffFFF1F2), 'nameColor': const Color(0xffBE123C)};
      case 28: return {'border': const Color(0xffB45309), 'background': const Color(0xffFEF3C7), 'nameColor': const Color(0xffB45309)};
      case 29: return {'border': const Color(0xff047857), 'background': const Color(0xffECFDF5), 'nameColor': const Color(0xff047857)};
      case 30: return {'border': const Color(0xff6D28D9), 'background': const Color(0xffF5F3FF), 'nameColor': const Color(0xff6D28D9)};
      case 31: return {'border': const Color(0xff0369A1), 'background': const Color(0xffF0F9FF), 'nameColor': const Color(0xff0369A1)};
      case 32: return {'border': const Color(0xffA21CAF), 'background': const Color(0xffFDF4FF), 'nameColor': const Color(0xffA21CAF)};
      case 33: return {'border': const Color(0xff78350F), 'background': const Color(0xffFDF6EC), 'nameColor': const Color(0xff78350F)};
      case 34: return {'border': const Color(0xff475569), 'background': const Color(0xffF8FAFC), 'nameColor': const Color(0xff475569)};
      default:
        return {'border': const Color(0xffE0D2AA), 'background': Colors.white, 'nameColor': const Color(0xffE64425)};
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'booked':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<MapEntry<Reservations, String>> get _currentReservations {
    if (selectedStore != null) {
      return (selectedStore!.reservations ?? [])
          .map((r) => MapEntry(r, selectedStore!.storeName ?? ''))
          .toList();
    }
    return stores
        .expand((s) => (s.reservations ?? <Reservations>[]).map((r) => MapEntry(r, s.storeName ?? '')))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Sticky Header ──────────────────────────────────────────
          Container(

            color: Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: (){
                             Get.back();
                            },
                            child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey, width: 1),
                                ),
                                child: Center(child: Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: const Icon(Icons.arrow_back_ios, size: 16,),
                                ))
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Reservations',
                            style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          if (total != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.green, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Total: $total',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.lightGreen, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.green, size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    DateFormat('dd MMM yy').format(selectedDate),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Horizontal Store Cards ─────────────────────────
                SizedBox(
                  height: 165,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 5),
                    //padding: EdgeInsets.zero,
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      final colors = _storeColors(store.storeId);
                      final isSelected = selectedStore?.storeId == store.storeId;
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
                            border: Border.all(
                              width: isSelected ? 2 : 1,
                              color: colors['border']!,
                            ),
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                    color: colors['nameColor'],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Total : ${store.total ?? 0}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
                              ),
                              Text(
                                'Booked : ${store.booked ?? 0}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
                              ),
                              if ((store.pending ?? 0) > 0)
                                Text(
                                  'Pending : ${store.pending}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Mulish', color: Colors.orange),
                                ),
                              if ((store.cancelled ?? 0) > 0)
                                Text(
                                  'Cancelled : ${store.cancelled}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Mulish', color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Filter label + Show All button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        //width: MediaQuery.of(context).size.width*0.6,
                        child: Text(
                          selectedStore != null
                              ? '${selectedStore!.storeName}  •  \n${_currentReservations.length} reservation'
                              : 'All stores  •  ${_currentReservations.length} reservation',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (selectedStore != null)
                        GestureDetector(
                          onTap: () => setState(() => selectedStore = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
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

          // ── Reservation List ───────────────────────────────────────
          Expanded(
            child: _currentReservations.isEmpty
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
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _currentReservations.length,
                    itemBuilder: (context, index) {
                      final entry = _currentReservations[index];
                      return _reservationCard(entry.key, entry.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reservationCard(Reservations res, String storeName) {
    final reservedFor = res.reservedFor != null ? DateTime.tryParse(res.reservedFor!) : null;
    final createdAt = res.createdAt != null ? DateTime.tryParse(res.createdAt!) : null;
    final statusColor = _statusColor(res.status);

    Color cardBg() {
      switch (res.status) {
        case 'booked':
          return const Color(0xffEBFFF4);
        case 'pending':
          return const Color(0xffFFFBEB);
        case 'cancelled':
          return const Color(0xffFFEFEF);
        default:
          return Colors.white;
      }
    }

    Color borderColor() {
      switch (res.status) {
        case 'booked':
          return const Color(0xffC3F2D9);
        case 'pending':
          return const Color(0xffFFE0A3);
        case 'cancelled':
          return const Color(0xffFFD0D0);
        default:
          return Colors.grey;
      }
    }

    IconData statusIcon() {
      switch (res.status) {
        case 'booked':
          return Icons.check;
        case 'pending':
          return Icons.access_time;
        case 'cancelled':
          return Icons.close;
        default:
          return Icons.help;
      }
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg(),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor(), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: icon + name + time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: statusColor,
                      child: Image.asset('assets/images/reservation.png'),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            res.customerName ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Mulish'),
                          ),
                        ),
                        if (storeName.isNotEmpty)
                          Text(
                            storeName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Mulish', color: Colors.black45),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      createdAt != null ? DateFormat('hh:mm a').format(createdAt) : '-',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Mulish', fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: phone + ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    res.customerPhone ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Mulish', fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    const Text('ID : ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'Mulish')),
                    Text('#${res.id}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, fontFamily: 'Mulish')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 3: guests + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${res.guestCount ?? 0} guests',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Mulish', fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      (res.status ?? '').toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 13, color: statusColor),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: statusColor,
                      child: Icon(statusIcon(), color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 4: reserved for
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'For: ${reservedFor != null ? DateFormat('dd MMM yyyy, hh:mm a').format(reservedFor) : '-'}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'Mulish', fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // Note
            if (res.note != null && res.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      res.note!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Mulish', color: Colors.black54, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> getReservation() async {
    setState(() {
      isLoading = true;
    });

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      });

      final model = await CallService().getAllReservationForStore(_formattedApiDate);

      setState(() {
        stores = model.stores ?? [];
        total = model.total;
        selectedStore = null;
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) Get.back();
    } catch (e) {
      print('Error getting Store Reservation: $e');
      setState(() {
        isLoading = false;
      });
      if (Get.isDialogOpen ?? false) Get.back();
      if (mounted) {
        Get.snackbar('Error', 'Failed to load Store Reservations',
            backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}
