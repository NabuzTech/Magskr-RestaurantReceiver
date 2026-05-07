import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';

class DeliveryOrder extends StatefulWidget {
  const DeliveryOrder({super.key});

  @override
  State<DeliveryOrder> createState() => _DeliveryOrderState();
}

class _DeliveryOrderState extends State<DeliveryOrder> {
  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed header that doesn't scroll
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Orders',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Mulish'
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      //onTap: () => Get.to(() => OrderDetailEnglish(order)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // top row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.green,
                                    child: SvgPicture.asset(
                                      'assets/images/ic_delivery.svg',
                                      height: 14,
                                      width: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PLZ 53604',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            fontFamily: "Mulish-Regular"),
                                      ),
                                      Text(
                                        'REWE Markt GmbH , Aegidienbe...',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                            letterSpacing: 0,
                                            height: 0,
                                            fontFamily: "Mulish"),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                  ),
                                  Text(
                                    '10:30',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: "Mulish",
                                      fontSize: 10,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rakesh Sharma / 49 98787678',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Mulish",
                                    fontSize: 13),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${'order_id'.tr} :',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        fontFamily: "Mulish"),
                                  ),
                                  const Text(
                                    '${2347687}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        fontFamily: "Mulish"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/driverProfile.png',
                                    height: 15,
                                    width: 15,
                                  ),
                                  const Text(
                                    'Mandeep',
                                    style: TextStyle(
                                        fontFamily: 'Mulish',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset('assets/images/accepted.svg'),
                                  const Text(
                                    'Delivered',
                                    style: TextStyle(
                                        fontFamily: 'Mulish',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}