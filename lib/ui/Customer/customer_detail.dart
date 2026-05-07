import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_customer_details_response_model.dart';
import '../home_screen.dart';
import 'customer_order_details.dart';

class CustomerDetail extends StatefulWidget {
  final int customerId;

  const CustomerDetail({super.key, required this.customerId});

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Pagination variables
  int ordersLimit = 10;
  int reservationsLimit = 10;
  int currentOrdersLoaded = 0;
  int currentReservationsLoaded = 0;
  bool isLoadingMore = false;
  bool hasMoreData = true;

  // Customer data
  CustomerDetailsResponseModel? customerDetails;
  bool isLoading = false;

  // Tab controller
  late TabController _tabController;
  int currentTab = 0;

  void _openTab(int index) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.off(() => const HomeScreen(),
        arguments: {'initialTab': index},
        transition: Transition.noTransition,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentTab = _tabController.index;
      });
    });

    getCustomerDetails();

    // Pagination scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMoreData) {
          _loadMoreData();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFCFF),
      appBar: const CustomAppBar(),
      drawer: CustomDrawer(onSelectTab: _openTab),
      body: customerDetails == null
          ? const Center(
        child: Text(
          'No customer details found',
          style: TextStyle(
            fontFamily: 'Mulish',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'custom_order'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Mulish',
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        currentOrdersLoaded = 0;
                        currentReservationsLoaded = 0;
                        hasMoreData = true;
                        getCustomerDetails();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.refresh,
                          size: 24,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15,),
                    InkWell(
                      onTap: (){
                        Get.back();
                      },
                      child: const Icon(Icons.arrow_back_ios),
                    )                  ],
                ),

              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 3),
                  child: SvgPicture.asset('assets/images/customer.svg'),
                ),
                const SizedBox(width: 8),
                Text(
                  customerDetails!.customerName ?? 'N/A',
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset('assets/images/phone.svg'),
                const SizedBox(width: 5),
                Text(
                  customerDetails!.phone ?? 'N/A',
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff797878),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SvgPicture.asset('assets/images/email.svg'),
                const SizedBox(width: 5),
                Container(

                  child: Text(
                    customerDetails!.email ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff797878),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.centerRight,
              child: Text(
                '${'joined'.tr} ${_formatDate(customerDetails!.createdAt ?? '')}',
                style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 11,
                  color: Color(0xff797878),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Buttons
            Row(
              children: [
                _buildTabButton(
                  label: 'order'.tr,
                  count: customerDetails!.totalOrders ?? 0,
                  isSelected: currentTab == 0,
                  color: const Color(0xffFCAE03),
                  onTap: () {
                    _tabController.animateTo(0);
                  },
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  label: 'reserv'.tr,
                  count: customerDetails!.totalReservations ?? 0,
                  isSelected: currentTab == 1,
                  color: const Color(0xffB8ABD1),
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(),
                  _buildReservationsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xffC5D8F5)),
        ),
        child: Row(
          children: [
            Container(
             height: 22,width: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (customerDetails!.orders == null || customerDetails!.orders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'no_order'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Mulish',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: customerDetails!.orders!.length + (isLoadingMore && currentTab == 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == customerDetails!.orders!.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Lottie.asset(
                'assets/animations/burger.json',
                width: 60,
                height: 60,
                repeat: true,
              ),
            ),
          );
        }

        final order = customerDetails!.orders![index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildReservationsList() {
    if (customerDetails!.reservations == null || customerDetails!.reservations!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'no_reservation'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Mulish',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: customerDetails!.reservations!.length + (isLoadingMore && currentTab == 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == customerDetails!.reservations!.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Lottie.asset(
                'assets/animations/burger.json',
                width: 60,
                height: 60,
                repeat: true,
              ),
            ),
          );
        }

        final reservation = customerDetails!.reservations![index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildOrderCard(Orders order) {
    return InkWell(
      onTap: (){
        Get.to(()=>CustomerOrderDetails(order.orderId.toString()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffE2EBF9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Container(
                //   padding: EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: Color(0xff00C853).withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Icon(
                //     Icons.shopping_bag,
                //     color: Color(0xff00C853),
                //     size: 24,
                //   ),
                // ),
                // SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Pickup : 15:00',
                    //   style: TextStyle(
                    //     fontFamily: 'Mulish',
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w700,
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      '${customerDetails!.customerName} / ${customerDetails!.phone ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0B043A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   '€5,90',
                    //   style: TextStyle(
                    //     fontFamily: 'Mulish',
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w700,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
            Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${'order_id'.tr} :',
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0B043A),
                      ),
                    ),
                    Text(
                      '${order.orderId ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff0B043A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Row(
                  children: [
                    Text(
                      'order_placed'.tr,
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0B043A),
                      ),
                    ),
                    Text(
                      order.orderDate ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff797878),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservations reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2EBF9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffB8ABD1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_available,
              color: Color(0xffB8ABD1),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reservation.tableNumber != null)
                  Text(
                    '${'table'.tr} ${reservation.tableNumber}',
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${'guests'.tr}: ${reservation.guestCount ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff797878),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(reservation.reservationDate ?? ''),
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff797878),
                  ),
                ),
              ],
            ),
          ),
          Text(
              '${'id'.tr}: ${reservation.reservationId ?? 'N/A'}',
            style: const TextStyle(
              fontFamily: 'Mulish',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xff797878),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> getCustomerDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
          barrierDismissible: false,
        );
      });
      CustomerDetailsResponseModel model = await CallService().getCustomerDetails(
        widget.customerId,
        ordersLimit,
        reservationsLimit,
      );

      setState(() {
        customerDetails = model;
        currentOrdersLoaded = model.orders?.length ?? 0;
        currentReservationsLoaded = model.reservations?.length ?? 0;
        isLoading = false;
      });
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      print('Customer Details Loaded');
      print('Orders: ${customerDetails!.orders?.length}');
      print('Reservations: ${customerDetails!.reservations?.length}');
    } catch (e) {
      print('Error getting Customer Details: $e');
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      int newOrdersLimit = currentTab == 0 ? currentOrdersLoaded + 10 : currentOrdersLoaded;
      int newReservationsLimit = currentTab == 1 ? currentReservationsLoaded + 10 : currentReservationsLoaded;

      CustomerDetailsResponseModel model = await CallService().getCustomerDetails(
        widget.customerId,
        newOrdersLimit,
        newReservationsLimit,
      );

      setState(() {
        customerDetails = model;

        if (currentTab == 0) {
          currentOrdersLoaded = model.orders?.length ?? 0;
          hasMoreData = (model.orders?.length ?? 0) < (model.totalOrders ?? 0);
        } else {
          currentReservationsLoaded = model.reservations?.length ?? 0;
          hasMoreData = (model.reservations?.length ?? 0) < (model.totalReservations ?? 0);
        }

        isLoadingMore = false;
      });

      print('Loaded more data. Orders: $currentOrdersLoaded, Reservations: $currentReservationsLoaded');
    } catch (e) {
      print('Error loading more data: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }
}