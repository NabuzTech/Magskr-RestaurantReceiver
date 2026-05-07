import 'package:flutter/material.dart';
import 'package:food_receiver/ui/StoreTiming/store_hour_bottomsheet.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_holidays_response_model.dart';
import '../../models/get_store_timing_response_model.dart';
import 'holiday_bottomsheet.dart';

class StoreTiming extends StatefulWidget {
  const StoreTiming({super.key});

  @override
  State<StoreTiming> createState() => _StoreTimingState();
}

class _StoreTimingState extends State<StoreTiming> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  int _selectedTabIndex = 0;
  // Store timing data from API
  List<GetStoreTimingResponseModel> storeTimingList = [];
  List<GetHolidayResponseModel> holidayList = [];
  // Days array for mapping day numbers to names
  List<String> dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  List<String> fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getStoreTiming();
      await getHoliday();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? const Color(0xff0C831F) : Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                'store_timing'.tr,
                                style: TextStyle(
                                  color: _selectedTabIndex == 0 ? Colors.white :  Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ),
                          ),
                          if (_selectedTabIndex == 0)
                            CustomPaint(
                              size: const Size(20, 10),
                              painter: TrianglePainter(color: const Color(0xff0C831F)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Expanded(
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       setState(() {
                  //         _selectedTabIndex = 1;
                  //       });
                  //     },
                  //     child: Column(
                  //       children: [
                  //         Container(
                  //           padding: const EdgeInsets.symmetric(vertical: 12),
                  //           decoration: BoxDecoration(
                  //             color: _selectedTabIndex == 1 ? const Color(0xff0C831F) : Colors.white,
                  //           ),
                  //           child: Center(
                  //             child: Text(
                  //               'holi'.tr,
                  //               style: TextStyle(
                  //                 color: _selectedTabIndex == 1 ? Colors.white :Colors.black,
                  //                 fontWeight: FontWeight.bold,
                  //                 fontSize: 14,
                  //                 fontFamily: 'Mulish',
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //         if (_selectedTabIndex == 1)
                  //           CustomPaint(
                  //             size: const Size(20, 10),
                  //             painter: TrianglePainter(color: const Color(0xff0C831F)),
                  //           ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0 ? 'store_hour'.tr : 'Holidays',
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_selectedTabIndex == 0) {
                        showAddStoreHoursBottomSheet(context);
                      } else {
                        showAddHolidayBottomSheet(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: const Color(0xFFFCAE03),
                      ),
                      child: Center(
                        child: Text(
                          'add'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _selectedTabIndex == 0 ? buildTimingCards() : buildHolidayCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimingCards() {
    if (storeTimingList.isEmpty) {
      if (isLoading) {
        return Center(child: Container());
      } else {
        return const Center(child: Text('No store timing data available'));
      }
    }

    // Get grouped timings
    List<Map<String, dynamic>> groupedTimings = _groupStoreTimings();

    return Column(
      children: groupedTimings.map((timingGroup) {
        String timingName = timingGroup['name'];
        List<int> selectedDays = timingGroup['days'];
        String openingTime = timingGroup['openingTime'];
        String closingTime = timingGroup['closingTime'];
        List<int?> timingIds = timingGroup['ids'];

        return buildTimingCard(
          timingName,
          selectedDays,
          openingTime,
          closingTime,
          timingIds,
        );
      }).toList(),
    );
  }

  Widget buildTimingCard(
      String timingName,
      List<int> selectedDays,
      String openingTime,
      String closingTime,
      List<int?> timingIds
      )
  {
    // Create display text for selected days
    String daysDisplay = selectedDays.map((day) =>
    (day >= 0 && day <= 6) ? fullDayNames[day] : 'Unknown'
    ).join(', ');

    return Column(
      children: [
        // Header with timing name and days
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: Color(0xFFECF8FF),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  timingName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  ),
                ),
              ),
              Row(
                children: [
                  Text('open'.tr, style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  )),
                  const SizedBox(width: 20),
                  Text('close'.tr, style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  )),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(7, (index) {
                    bool isSelected = selectedDays.contains(index);

                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.green : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Row(
                  children: [
                    Text(
                      openingTime.length >= 5 ? openingTime.substring(0, 5) : openingTime,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Mulish'
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      closingTime.length >= 5 ? closingTime.substring(0, 5) : closingTime,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Mulish'
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Edit button
                    GestureDetector(
                      onTap: () {
                        showEditStoreHoursBottomSheet(
                            context,
                            timingName,
                            selectedDays,
                            openingTime,
                            closingTime,
                          timingIds,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff0C831F)
                        ),
                        child: const Center(
                          child: Icon(Icons.mode_edit_outline_outlined, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete button - now deletes all timings in this group
                    GestureDetector(
                      onTap: () {
                        if (timingIds.isNotEmpty && timingIds.first != null) {
                          _showDeleteConfirmation(context, '$timingName - $daysDisplay', timingIds);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('invalid_timing'.tr),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffE25454)
                        ),
                        child: const Center(
                          child: Icon(Icons.delete_outline, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFFAEC2DF)),
      ],
    );
  }

  Widget buildHolidayCards() {
    if (holidayList.isEmpty) {
      return const Center(child: Text('No holidays added'));
    }

    return Column(
      children: holidayList.map((holiday) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFECF8FF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'titles'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  Text(
                    'date'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  Text(
                    'start'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      holiday.name ?? '',
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _extractDate(holiday.date ?? ''),
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _extractTime(holiday.date ?? ''),
                      style: const TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showEditHolidayBottomSheet(
                            context,
                            holiday.name ?? '',
                            holiday.date ?? '',
                            holiday.id ?? 0,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff0C831F),
                          ),
                          child: const Icon(
                            Icons.mode_edit_outline_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (holiday.id != null) {
                            _showDeleteHolidayConfirmation(
                              context,
                              holiday.name ?? 'Holiday',
                              holiday.id!,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffE25454),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFAEC2DF)),
          ],
        );
      }).toList(),
    );
  }

  String _extractDate(String datetime) {
    if (datetime.isEmpty) return '';

    try {
      // If format is "2025-12-30T08:18:55"
      if (datetime.contains('T')) {
        List<String> parts = datetime.split('T');
        String datePart = parts[0]; // "2025-12-30"

        List<String> dateParts = datePart.split('-');
        if (dateParts.length == 3) {
          String year = dateParts[0];
          String month = dateParts[1];
          String day = dateParts[2];
          return '$day-$month-$year'; // "30-12-2025"
        }
      }

      return datetime;
    } catch (e) {
      print('Error extracting date: $e');
      return datetime;
    }
  }

  String _extractTime(String datetime) {
    if (datetime.isEmpty) return '';

    try {
      // If format is "2025-12-30T08:18:55"
      if (datetime.contains('T')) {
        List<String> parts = datetime.split('T');
        if (parts.length > 1) {
          String timePart = parts[1]; // "08:18:55"

          // Extract HH:mm only
          List<String> timeParts = timePart.split(':');
          if (timeParts.length >= 2) {
            return '${timeParts[0]}:${timeParts[1]}'; // "08:18"
          }
        }
      }

      return datetime;
    } catch (e) {
      print('Error extracting time: $e');
      return datetime;
    }
  }

  void showAddHolidayBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddHolidayBottomSheet(
          isEditMode: false,
          onDataAdded: () {
            getHoliday(showLoader: false);
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupStoreTimings() {
    Map<String, Map<String, dynamic>> groupedTimings = {};

    for (var timing in storeTimingList) {
      String key = '${timing.name}_${timing.openingTime}_${timing.closingTime}';

      if (groupedTimings.containsKey(key)) {
        // Add day to existing group
        groupedTimings[key]!['days'].add(timing.dayOfWeek ?? -1);
        groupedTimings[key]!['ids'].add(timing.id);
      } else {
        // Create new group
        groupedTimings[key] = {
          'name': timing.name ?? 'Timing',
          'openingTime': timing.openingTime ?? '00:00',
          'closingTime': timing.closingTime ?? '00:00',
          'days': [timing.dayOfWeek ?? -1],
          'ids': [timing.id],
        };
      }
    }

    // Sort days in each group
    groupedTimings.forEach((key, value) {
      (value['days'] as List<int>).sort();
    });

    return groupedTimings.values.toList();
  }

  void _showDeleteConfirmation(BuildContext context, String timingName, List<int?> timingIds) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        '${"are".tr} "$timingName"',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            fontFamily: 'Mulish'
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 35,
                            width: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E9AAF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            height: 35,
                            width: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE25454),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _deleteStoreTiming(timingIds);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              child: Text(
                                'delete'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFED4C5C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                )
              ]
          ),
        );
      },
    );
  }

  Future<void> _deleteStoreTiming(List<int?> timingIds) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        );
      },
    );

    try {
      // Delete all timing IDs in the group
      for (var id in timingIds) {
        if (id != null) {
          await CallService().deleteStoreTiming(id);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('del_timing'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      await getStoreTiming(showLoader: false);

    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error deleting timing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_timing'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void showEditStoreHoursBottomSheet(
      BuildContext context,
      String timingName,
      List<int> selectedDays,
      String openingTime,
      String closingTime,
      List<int?> timingIds,  // ADD THIS
      )
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child:  AddStoreHoursBottomSheet(
          isEditMode: true,
          editTimingName: timingName,
          editSelectedDays: selectedDays,
          editOpeningTime: openingTime,
          editClosingTime: closingTime,
          editTimingIds: timingIds,  // ADD THIS
          onDataAdded: () {
            getStoreTiming(showLoader: false);
          },
        ),
      ),
    );
  }

  void showAddStoreHoursBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddStoreHoursBottomSheet(
          isEditMode: false,
          onDataAdded: () {
            getStoreTiming(showLoader: false);
          },
        ),
      ),
    );
  }

  Future<void> getStoreTiming({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (showLoader) {
      setState(() {
        isLoading = true;
      });
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );
    }

    try {
      List<GetStoreTimingResponseModel> storeTiming = await CallService().getStoreTiming(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        storeTimingList = storeTiming;
        print('Store timing length is ${storeTiming.length}');
        isLoading = false;
      });

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Store Timing: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getHoliday({bool showLoader = true}) async {
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });

      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );
    }

    try {
      List<GetHolidayResponseModel> holiday = await CallService().getHolidays();
      print('holiday length is ${holiday.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          holidayList=holiday;
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting holiday: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  void showEditHolidayBottomSheet(
      BuildContext context,
      String name,
      String dateString,
      int holidayId,
      )
  {
    // Parse the date string to DateTime
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $e');
      parsedDate = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddHolidayBottomSheet(
          isEditMode: true,
          editTitle: name,
          editDate: parsedDate,
          editHolidayId: holidayId, // Pass the holiday ID
          onDataAdded: () {
            getHoliday(showLoader: false);
          },
        ),
      ),
    );
  }
  void _showDeleteHolidayConfirmation(BuildContext context, String holidayName, int holidayId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Are you sure you want to delete "$holidayName"?',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        fontFamily: 'Mulish',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 35,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E9AAF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          height: 35,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE25454),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _deleteHoliday(holidayId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
                              'delete'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFED4C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteHoliday(int holidayId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        );
      },
    );

    try {
      await CallService().deleteHoliday(holidayId.toString());

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holiday deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      await getHoliday(showLoader: false);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error deleting holiday: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete holiday'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}

class DayModel {
  final String day;
  bool isSelected;

  DayModel({
    required this.day,
    this.isSelected = false,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom center point
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}