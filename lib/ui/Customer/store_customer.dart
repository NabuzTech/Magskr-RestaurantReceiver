import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../api/repository/api_repository.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_store_customer_response_model.dart';
import '../../utils/my_application.dart';
import '../home_screen.dart';
import 'customer_detail.dart';

class StoreCustomer extends StatefulWidget {
  const StoreCustomer({super.key});

  @override
  State<StoreCustomer> createState() => _StoreCustomerState();
}

class _StoreCustomerState extends State<StoreCustomer> {
  final ScrollController _scrollController = ScrollController();
  int currentLimit = 20;
  int currentOffset = 0;
  bool isLoadingMore = false;
  bool hasMoreCustomers = true;
  int? totalCustomers;
  bool isLoading=false;
  List<Customers>? customers=[];
  List<Customers>? filteredCustomers = [];
  String currentSearchQuery = '';

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
    app.appController.customerFilterCallback = _filterCustomers;

    getStoreCustomers();

    // Pagination scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMoreCustomers) {
          _loadMoreCustomers();
        }
      }
    });
  }

  @override
  void dispose() {
    app.appController.customerFilterCallback = null;
    _scrollController.dispose();
    super.dispose();
  }
  void _filterCustomers(String query) {
    setState(() {
      currentSearchQuery = query.toLowerCase();

      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers?.where((customer) {
          final name = customer.customerName?.toLowerCase() ?? '';
          final phone = customer.phone?.toLowerCase() ?? '';
          final email = customer.email?.toLowerCase() ?? '';

          return name.contains(currentSearchQuery) ||
              phone.contains(currentSearchQuery) ||
              email.contains(currentSearchQuery);
        }).toList();
      }
    });

    print('🔍 Filtered customers: ${filteredCustomers?.length}');
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Text(
                  'custom'.tr,
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xffB8ABD1),
                  ),
                  child: Text(
                    '${totalCustomers ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ),
                const Spacer(),
                // Refresh Button
                InkWell(
                  onTap: () {
                    currentOffset = 0;
                    hasMoreCustomers = true;
                    getStoreCustomers();
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
              ],
            ),
            const SizedBox(height: 15),

            // Customer List
            Expanded(
              child: filteredCustomers == null || filteredCustomers!.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      currentSearchQuery.isEmpty ? 'no_customer'.tr : 'no_matching'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: filteredCustomers!.length + (isLoadingMore ? 1 : 0),  // ✅ Change from customers
                itemBuilder: (context, index) {
                  if (index == filteredCustomers!.length) {  // ✅ Change from customers
                    return Center(
                      child: Lottie.asset(
                        'assets/animations/burger.json',
                        width: 80,
                        height: 80,
                        repeat: true,
                      ),
                    );
                  }

                  final customer = filteredCustomers![index];  // ✅ Change from customers
                  return _buildCustomerCard(customer);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customers customer) {
    return InkWell(
      onTap: (){
        Get.to(()=>CustomerDetail(customerId: customer.id!,));
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xffFFFFFF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xffE2EBF9)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name with verified badge
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: SvgPicture.asset('assets/images/customer.svg')),
                          const SizedBox(width: 5),
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width*0.4,
                                child: Text(
                                  customer.customerName ?? 'N/A',
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3,),
                              SizedBox( width: MediaQuery.of(context).size.width*0.4,
                                child: Text(
                                  'Joined ${_formatDate(customer.createdAt ?? '')}',
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 11,
                                    color: Color(0xff797878),
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3,),

                            ],
                          ),
                          // if (customer.email != null && customer.email!.isNotEmpty)
                          //   Container(
                          //     padding: EdgeInsets.all(3),
                          //     decoration: BoxDecoration(
                          //       color: Colors.blue.shade50,
                          //       shape: BoxShape.circle,
                          //     ),
                          //     child: Icon(Icons.verified, size: 12, color: Colors.blue),
                          //   ),
                        ],
                      ),
                      Row(
                        children: [
                          SvgPicture.asset('assets/images/phone.svg'),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: MediaQuery.of(context).size.width*0.3,
                            child: Text(
                              customer.phone ?? 'N/A',
                              style: const TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff797878)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3,),
                      Row(
                        children: [
                          SvgPicture.asset('assets/images/email.svg'),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: MediaQuery.of(context).size.width*0.5,
                            child: Text(
                              customer.email ?? 'N/A',
                              style: const TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff797878)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 80,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reservations Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xffB8ABD1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:Center(
                                  child: Text(
                                '${customer.totalReservations ?? 0}',
                                style: const TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white
                                ),
                              ),)
                            ),
                            const SizedBox(width: 4,),
                            Text(
                              'rese'.tr,
                              style: const TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Orders Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xffFCAE03),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${customer.totalOrders ?? 0}',
                                style: const TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'order'.tr,
                              style: const TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,

                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Total Spent

                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone and Email
                      // Row(
                      //   children: [
                      //     SvgPicture.asset('assets/images/phone.svg'),
                      //     SizedBox(width: 5),
                      //     Container(
                      //       width: MediaQuery.of(context).size.width*0.3,
                      //       child: Text(
                      //         customer.phone ?? 'N/A',
                      //         style: TextStyle(
                      //             fontFamily: 'Mulish',
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w600,
                      //             color: Color(0xff797878)
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     SvgPicture.asset('assets/images/email.svg'),
                      //     SizedBox(width: 5),
                      //     Container(
                      //       width: MediaQuery.of(context).size.width*0.45,
                      //       child: Text(
                      //         customer.email ?? 'N/A',
                      //         style: TextStyle(
                      //             fontFamily: 'Mulish',
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w600,
                      //             color: Color(0xff797878)
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),

                    ],
                  ),
                  // Container(
                  //   padding: EdgeInsets.only(bottom: 20),
                  //   child: Column(
                  //     children: [
                  //       Text(
                  //         '€200', // Ye calculate karna padega orders se
                  //         style: TextStyle(
                  //           fontFamily: 'Mulish',
                  //           fontSize: 20,
                  //           fontWeight: FontWeight.w800,
                  //         ),
                  //       ),
                  //       Text(
                  //         'Total Spent',
                  //         style: TextStyle(
                  //           fontFamily: 'Mulish',
                  //           fontSize: 10,fontWeight: FontWeight.w700,
                  //           color: Colors.grey.shade600,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
              if (customer.lastOrderDate != null)
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${'last_placed'.tr}${_formatDate(customer.lastOrderDate ?? '')}',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Future<void> getStoreCustomers() async {
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

      GetStoreCustomerResponseModel model = await CallService().getStoreCustomer(
        currentLimit, currentOffset,
      );

      setState(() {
        if (currentOffset == 0) {
          customers = model.customers ?? [];
          customers = model.customers ?? [];  // ✅ Store all
          filteredCustomers = model.customers ?? [];  // ✅ Initial filtered same as all
        } else {
          customers!.addAll(model.customers ?? []);
          customers!.addAll(model.customers ?? []);  // ✅ Add to all
          if (currentSearchQuery.isEmpty) {
            filteredCustomers = customers;  // ✅ Update filtered only if not searching
          }
        }

        totalCustomers = model.total;
        hasMoreCustomers = customers!.length < (model.total ?? 0);
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error getting Customer: $e');
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  Future<void> _loadMoreCustomers() async {
    if (isLoadingMore || !hasMoreCustomers) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentOffset += currentLimit;

      GetStoreCustomerResponseModel model = await CallService().getStoreCustomer(
       currentLimit, currentOffset,
      );

      setState(() {
        customers!.addAll(model.customers ?? []);
        customers!.addAll(model.customers ?? []);
        if (currentSearchQuery.isEmpty) {
          filteredCustomers = customers;
        } else {
          _filterCustomers(currentSearchQuery);
        }
        hasMoreCustomers = customers!.length < (model.total ?? 0);
        isLoadingMore = false;
      });

      print('Loaded more customers. Total now: ${customers!.length}');
    } catch (e) {
      print('Error loading more customers: $e');
      setState(() {
        isLoadingMore = false;
        currentOffset -= currentLimit; // Rollback offset on error
      });
    }
  }

}
