import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:food_receiver/ui/StoreTiming/store_timing.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/add_collection_time_response_model.dart';
import '../../models/add_delivery_time_response_model.dart';
import '../../models/edit_collection_time_response_model.dart';
import '../../models/edit_delivery_time_response_model.dart';
import '../../models/get_collection_time_response_model.dart';
import '../../models/get_delivery_time_response_model.dart';

class DeliveryPickupTiming extends StatefulWidget {
  const DeliveryPickupTiming({super.key});

  @override
  State<DeliveryPickupTiming> createState() => _DeliveryPickupTimingState();
}

class _DeliveryPickupTimingState extends State<DeliveryPickupTiming> {
  bool isLoading =false;
  int _selectedTabIndex = 0;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<GetDeliveryTimeStore> delivery = [];
  List<GetCollectionTimeStore> collection = [];
  late PageController _pageController;
  final ValueNotifier<int> _listRebuildNotifier = ValueNotifier<int>(0);
  bool selectAllDays = false;
  TextEditingController allDaysNameController = TextEditingController();
  List<Map<String, String>> allDaysTimeSlots = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
  }
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
      await getDeliveryTime();
      await getCollectionTime();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              'del_time'.tr,
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
                //               'collection'.tr,
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
                  _selectedTabIndex == 0 ? 'del_time'.tr : 'collection'.tr,
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showAddTimeBottomSheet(context, _selectedTabIndex == 0);
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
            const SizedBox(height: 10,),
            _selectedTabIndex == 0 ? buildDeliveryTime() : collectionTime(),
          ],
        ),
      ),
    );
  }

  void showAddTimeBottomSheet(BuildContext context, bool isDelivery) {
    Map<int, TextEditingController> nameControllers = {};
    List<int> selectedDays = [];
    Map<int, List<Map<String, String>>> dayTimeSlots = {};
    Map<int, bool> hasText = {};

    // New variables for Select All
    bool selectAllDays = false;
    TextEditingController allDaysNameController = TextEditingController();
    List<Map<String, String>> allDaysTimeSlots = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isDelivery ? 'add_del'.tr : 'add_collection'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Select Days with Select All checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'days'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: selectAllDays,
                                    activeColor: const Color(0xff0C831F),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectAllDays = value!;
                                        if (selectAllDays) {
                                          // Clear individual selections
                                          selectedDays.clear();
                                          nameControllers.clear();
                                          dayTimeSlots.clear();
                                          hasText.clear();
                                        } else {
                                          // Clear select all data
                                          allDaysNameController.clear();
                                          allDaysTimeSlots.clear();
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'all'.tr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Show day selection only if Select All is not checked
                          if (!selectAllDays)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(7, (index) {
                                  bool isSelected = selectedDays.contains(index);
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedDays.remove(index);
                                          nameControllers.remove(index);
                                          dayTimeSlots.remove(index);
                                          hasText.remove(index);
                                        } else {
                                          selectedDays.add(index);
                                          nameControllers[index] = TextEditingController();
                                          hasText[index] = false;
                                          dayTimeSlots[index] = [];
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xff0C831F)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xff0C831F)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        getDayName(index).substring(0, 3),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Name Field - Single field for all days or individual fields
                          if (selectAllDays) ...[
                            Text(
                              'name_for'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: allDaysNameController,
                              decoration: InputDecoration(
                                hintText: 'enter_name_for_all'.tr,
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F8F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else if (selectedDays.isNotEmpty) ...[
                            Text(
                              'name_selected'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...selectedDays.map((dayIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getDayName(dayIndex),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Mulish',
                                        color: hasText[dayIndex] == true
                                            ? const Color(0xff0C831F)
                                            : const Color(0xFFE25454),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: nameControllers[dayIndex],
                                      onTap: () {},
                                      onChanged: (value) {
                                        setModalState(() {
                                          hasText[dayIndex] = value.trim().isNotEmpty;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: '${'enter_name_for'.tr} ${getDayName(dayIndex)}',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Mulish',
                                          fontSize: 12,
                                        ),
                                        filled: true,
                                        fillColor: hasText[dayIndex] == true
                                            ? const Color(0xFFF0F8F0)
                                            : const Color(0xFFFFF5F5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: hasText[dayIndex] == true
                                                ? const Color(0xff0C831F)
                                                : const Color(0xFFE25454),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: hasText[dayIndex] == true
                                                ? const Color(0xff0C831F)
                                                : const Color(0xFFE25454),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: hasText[dayIndex] == true
                                                ? const Color(0xff0C831F)
                                                : const Color(0xFFE25454),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],

                          // Time Slots - Single slot for all days or individual slots
                          if (selectAllDays) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'add_time'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                    color: Color(0xff0C831F),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: allDaysTimeSlots.isEmpty ||
                                      (allDaysTimeSlots.length == 1 &&
                                          allDaysTimeSlots[0]['startTime']!.isNotEmpty &&
                                          allDaysTimeSlots[0]['endTime']!.isNotEmpty)
                                      ? () {
                                    FocusScope.of(context).unfocus();
                                    setModalState(() {
                                      allDaysTimeSlots.add({
                                        'startTime': '',
                                        'endTime': '',
                                      });
                                    });
                                  }
                                      : null,
                                  child: Opacity(
                                    opacity: allDaysTimeSlots.isEmpty ||
                                        (allDaysTimeSlots.length == 1 &&
                                            allDaysTimeSlots[0]['startTime']!.isNotEmpty &&
                                            allDaysTimeSlots[0]['endTime']!.isNotEmpty)
                                        ? 1.0
                                        : 0.5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCAE03),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.add, size: 16, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            'add_t'.tr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Mulish',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (allDaysTimeSlots.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: allDaysTimeSlots.length,
                                itemBuilder: (context, slotIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${'slo'.tr} ${slotIndex + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  fontFamily: 'Mulish',
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setModalState(() {
                                                    allDaysTimeSlots.removeAt(slotIndex);
                                                  });
                                                },
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              // Start Time for Select All
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    FocusScope.of(context).unfocus();
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      builder: (BuildContext builder) {
                                                        DateTime selectedTime = allDaysTimeSlots[slotIndex]['startTime']!.isEmpty
                                                            ? DateTime.now()
                                                            : DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day,
                                                          int.parse(allDaysTimeSlots[slotIndex]['startTime']!.split(':')[0]),
                                                          int.parse(allDaysTimeSlots[slotIndex]['startTime']!.split(':')[1]),
                                                        );
                                                        return Container(
                                                          height: MediaQuery.of(context).size.height * 0.5,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                decoration: BoxDecoration(
                                                                  border: Border(
                                                                    bottom: BorderSide(color: Colors.grey.shade300),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context),
                                                                      child: Text('cancel'.tr, style: const TextStyle(color: Colors.red, fontSize: 16)),
                                                                    ),
                                                                    Text(
                                                                        'select_time'.tr,
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 16,
                                                                          fontFamily: 'Mulish',
                                                                        )
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        setModalState(() {
                                                                          allDaysTimeSlots[slotIndex]['startTime'] =
                                                                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                                        });
                                                                        Navigator.pop(context);
                                                                      },
                                                                      child: Text('don'.tr, style: const TextStyle(color: Colors.green, fontSize: 16)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: CupertinoDatePicker(
                                                                  mode: CupertinoDatePickerMode.time,
                                                                  use24hFormat: true,
                                                                  initialDateTime: selectedTime,
                                                                  onDateTimeChanged: (DateTime newTime) {
                                                                    selectedTime = newTime;
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF8F8F8),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          allDaysTimeSlots[slotIndex]['startTime']!.isEmpty
                                                              ? 'start_time'.tr
                                                              : allDaysTimeSlots[slotIndex]['startTime']!,
                                                          style: TextStyle(
                                                            color: allDaysTimeSlots[slotIndex]['startTime']!.isEmpty ? Colors.grey : Colors.black,
                                                            fontSize: 12,
                                                            fontFamily: 'Mulish',
                                                          ),
                                                        ),
                                                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // End Time for Select All
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    FocusScope.of(context).unfocus();
                                                    await showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext builder) {
                                                        DateTime selectedTime = allDaysTimeSlots[slotIndex]['endTime']!.isEmpty
                                                            ? DateTime.now()
                                                            : DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day,
                                                          int.parse(allDaysTimeSlots[slotIndex]['endTime']!.split(':')[0]),
                                                          int.parse(allDaysTimeSlots[slotIndex]['endTime']!.split(':')[1]),
                                                        );
                                                        return Container(
                                                          height: MediaQuery.of(context).size.height * 0.5,
                                                          color: Colors.white,
                                                          child: Column(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                decoration: BoxDecoration(
                                                                  border: Border(
                                                                    bottom: BorderSide(color: Colors.grey.shade300),
                                                                  ),
                                                                ),child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: Text('cancel'.tr, style: const TextStyle(color: Colors.red)),
                                                                  ),
                                                                  Text('select_time'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      setModalState(() {
                                                                        allDaysTimeSlots[slotIndex]['endTime'] =
                                                                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                                      });
                                                                      Navigator.pop(context);
                                                                    },
                                                                    child: Text('don'.tr, style: const TextStyle(color: Colors.green)),
                                                                  ),
                                                                ],
                                                              ),
                                                              ),
                                                              Expanded(
                                                                child: CupertinoDatePicker(
                                                                  mode: CupertinoDatePickerMode.time,
                                                                  use24hFormat: true,
                                                                  initialDateTime: selectedTime,
                                                                  onDateTimeChanged: (DateTime newTime) {
                                                                    selectedTime = newTime;
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF8F8F8),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          allDaysTimeSlots[slotIndex]['endTime']!.isEmpty
                                                              ? 'end_time'.tr
                                                              : allDaysTimeSlots[slotIndex]['endTime']!,
                                                          style: TextStyle(
                                                            color: allDaysTimeSlots[slotIndex]['endTime']!.isEmpty ? Colors.grey : Colors.black,
                                                            fontSize: 12,
                                                            fontFamily: 'Mulish',
                                                          ),
                                                        ),
                                                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                          ] else if (selectedDays.isNotEmpty) ...[
                            ...selectedDays.map((dayIndex) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${'add_f'.tr} ${getDayName(dayIndex)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Mulish',
                                          color: Color(0xff0C831F),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: dayTimeSlots[dayIndex]!.isEmpty ||
                                            (dayTimeSlots[dayIndex]!.length == 1 &&
                                                dayTimeSlots[dayIndex]![0]['startTime']!.isNotEmpty &&
                                                dayTimeSlots[dayIndex]![0]['endTime']!.isNotEmpty)
                                            ? () {
                                          FocusScope.of(context).unfocus();
                                          setModalState(() {
                                            dayTimeSlots[dayIndex]!.add({
                                              'startTime': '',
                                              'endTime': '',
                                            });
                                          });
                                        }
                                            : null,
                                        child: Opacity(
                                          opacity: dayTimeSlots[dayIndex]!.isEmpty ||
                                              (dayTimeSlots[dayIndex]!.length == 1 &&
                                                  dayTimeSlots[dayIndex]![0]['startTime']!.isNotEmpty &&
                                                  dayTimeSlots[dayIndex]![0]['endTime']!.isNotEmpty)
                                              ? 1.0
                                              : 0.5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFCAE03),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.add, size: 16, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'add_t'.tr,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Mulish',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Display Time Slots for this day
                                  if (dayTimeSlots[dayIndex]!.isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: dayTimeSlots[dayIndex]!.length,
                                      itemBuilder: (context, slotIndex) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${'slo'.tr} ${slotIndex + 1}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                        fontFamily: 'Mulish',
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          dayTimeSlots[dayIndex]!.removeAt(slotIndex);
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    // Start Time for Individual Days - FIXED
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () async {
                                                          FocusScope.of(context).unfocus();
                                                          await showModalBottomSheet(
                                                            context: context,
                                                            isScrollControlled: true,
                                                            builder: (BuildContext builder) {
                                                              // FIX: Use dayTimeSlots[dayIndex] instead of allDaysTimeSlots
                                                              DateTime selectedTime = dayTimeSlots[dayIndex]![slotIndex]['startTime']!.isEmpty
                                                                  ? DateTime.now()
                                                                  : DateTime(
                                                                DateTime.now().year,
                                                                DateTime.now().month,
                                                                DateTime.now().day,
                                                                int.parse(dayTimeSlots[dayIndex]![slotIndex]['startTime']!.split(':')[0]),
                                                                int.parse(dayTimeSlots[dayIndex]![slotIndex]['startTime']!.split(':')[1]),
                                                              );
                                                              return Container(
                                                                height: MediaQuery.of(context).size.height * 0.5,
                                                                decoration: const BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                                ),
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                      decoration: BoxDecoration(
                                                                        border: Border(
                                                                          bottom: BorderSide(color: Colors.grey.shade300),
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(context),
                                                                            child: Text('cancel'.tr, style: const TextStyle(color: Colors.red, fontSize: 16)),
                                                                          ),
                                                                          Text(
                                                                              'select_time'.tr,
                                                                              style: const TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 16,
                                                                                fontFamily: 'Mulish',
                                                                              )
                                                                          ),
                                                                          TextButton(
                                                                            onPressed: () {
                                                                              setModalState(() {
                                                                                // FIX: Update dayTimeSlots[dayIndex] instead of allDaysTimeSlots
                                                                                dayTimeSlots[dayIndex]![slotIndex]['startTime'] =
                                                                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                                              });
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child: Text('don'.tr, style: const TextStyle(color: Colors.green, fontSize: 16)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child: CupertinoDatePicker(
                                                                        mode: CupertinoDatePickerMode.time,
                                                                        use24hFormat: true,
                                                                        initialDateTime: selectedTime,
                                                                        onDateTimeChanged: (DateTime newTime) {
                                                                          selectedTime = newTime;
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF8F8F8),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                dayTimeSlots[dayIndex]![slotIndex]['startTime']!.isEmpty
                                                                    ? 'start_time'.tr
                                                                    : dayTimeSlots[dayIndex]![slotIndex]['startTime']!,
                                                                style: TextStyle(
                                                                  color: dayTimeSlots[dayIndex]![slotIndex]['startTime']!.isEmpty
                                                                      ? Colors.grey
                                                                      : Colors.black,
                                                                  fontSize: 12,
                                                                  fontFamily: 'Mulish',
                                                                ),
                                                              ),
                                                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // End Time for Individual Days - FIXED
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () async {
                                                          FocusScope.of(context).unfocus();
                                                          await showModalBottomSheet(
                                                            context: context,
                                                            builder: (BuildContext builder) {
                                                              // FIX: Use dayTimeSlots[dayIndex] instead of allDaysTimeSlots
                                                              DateTime selectedTime = dayTimeSlots[dayIndex]![slotIndex]['endTime']!.isEmpty
                                                                  ? DateTime.now()
                                                                  : DateTime(
                                                                DateTime.now().year,
                                                                DateTime.now().month,
                                                                DateTime.now().day,
                                                                int.parse(dayTimeSlots[dayIndex]![slotIndex]['endTime']!.split(':')[0]),
                                                                int.parse(dayTimeSlots[dayIndex]![slotIndex]['endTime']!.split(':')[1]),
                                                              );
                                                              return Container(
                                                                height: MediaQuery.of(context).size.height * 0.5,
                                                                color: Colors.white,
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                      decoration: BoxDecoration(
                                                                        border: Border(
                                                                          bottom: BorderSide(color: Colors.grey.shade300),
                                                                        ),
                                                                      ), child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(context),
                                                                          child: Text('cancel'.tr, style: const TextStyle(color: Colors.red)),
                                                                        ),
                                                                        Text('select_time'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            setModalState(() {
                                                                              // FIX: Update dayTimeSlots[dayIndex] instead of allDaysTimeSlots
                                                                              dayTimeSlots[dayIndex]![slotIndex]['endTime'] =
                                                                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                                            });
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child: Text('don'.tr, style: const TextStyle(color: Colors.green)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    ),
                                                                    Expanded(
                                                                      child: CupertinoDatePicker(
                                                                        mode: CupertinoDatePickerMode.time,
                                                                        use24hFormat: true,
                                                                        initialDateTime: selectedTime,
                                                                        onDateTimeChanged: (DateTime newTime) {
                                                                          selectedTime = newTime;
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF8F8F8),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                dayTimeSlots[dayIndex]![slotIndex]['endTime']!.isEmpty
                                                                    ? 'end_time'.tr
                                                                    : dayTimeSlots[dayIndex]![slotIndex]['endTime']!,
                                                                style: TextStyle(
                                                                  color: dayTimeSlots[dayIndex]![slotIndex]['endTime']!.isEmpty
                                                                      ? Colors.grey
                                                                      : Colors.black,
                                                                  fontSize: 12,
                                                                  fontFamily: 'Mulish',
                                                                ),
                                                              ),
                                                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            }),
                          ],

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff757B8F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // FIXED: Different API calls based on selection
                                    if (selectAllDays) {
                                      // Validation for select all mode
                                      if (allDaysNameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_enter_name'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      if (allDaysTimeSlots.isEmpty ||
                                          allDaysTimeSlots.any((slot) => slot['startTime']!.isEmpty || slot['endTime']!.isEmpty)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_fill'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Call API for all days - DIFFERENT API
                                      if (isDelivery) {
                                        saveAllDaysDeliveryTime(
                                          name: allDaysNameController.text,
                                          timeSlots: allDaysTimeSlots,
                                        );
                                      } else {
                                        saveAllDaysCollectionTime(
                                          name: allDaysNameController.text,
                                          timeSlots: allDaysTimeSlots,
                                        );
                                      }
                                    } else {
                                      // Validation for individual days
                                      if (selectedDays.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_select_at'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Check if all names are filled
                                      bool allNamesFilled = true;
                                      for (int day in selectedDays) {
                                        if (nameControllers[day]!.text.isEmpty) {
                                          allNamesFilled = false;
                                          break;
                                        }
                                      }

                                      if (!allNamesFilled) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_enter_name_for'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Check if at least one time slot exists for each day
                                      bool allDaysHaveTimeSlots = true;
                                      for (int day in selectedDays) {
                                        if (dayTimeSlots[day]!.isEmpty) {
                                          allDaysHaveTimeSlots = false;
                                          break;
                                        }
                                      }

                                      if (!allDaysHaveTimeSlots) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_add'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Check if all time slots are filled
                                      bool allTimeSlotsFilled = true;
                                      for (int day in selectedDays) {
                                        for (var slot in dayTimeSlots[day]!) {
                                          if (slot['startTime']!.isEmpty || slot['endTime']!.isEmpty) {
                                            allTimeSlotsFilled = false;
                                            break;
                                          }
                                        }
                                        if (!allTimeSlotsFilled) break;
                                      }

                                      if (!allTimeSlotsFilled) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('please_fill_all'.tr),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Call API for individual days - DIFFERENT API
                                      if (isDelivery) {
                                        saveBulkDeliveryTime(
                                          nameControllers: nameControllers,
                                          selectedDays: selectedDays,
                                          dayTimeSlots: dayTimeSlots,
                                        );
                                      } else {
                                        saveBulkCollectionTime(
                                          nameControllers: nameControllers,
                                          selectedDays: selectedDays,
                                          dayTimeSlots: dayTimeSlots,
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'saved'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -90,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: const Icon(Icons.close, size: 30, color: Colors.black),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  void showEditTimeBottomSheet(BuildContext context, bool isDelivery, dynamic timeData) {
    final TextEditingController nameController = TextEditingController(text: timeData.name);
    final TextEditingController startTimeController = TextEditingController(text: timeData.startTime);
    final TextEditingController endTimeController = TextEditingController(text: timeData.endTime);
    int selectedDay = timeData.dayOfWeek ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isDelivery ? 'edit_del'.tr : 'edit_coll'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Name Field
                           Text(
                            'name'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'enter_name'.tr,
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Mulish',
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Day of Week
                           Text(
                            'day_of'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: selectedDay,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: List.generate(7, (index) {
                              return DropdownMenuItem(
                                value: index,
                                child: Text(getDayName(index)),
                              );
                            }),
                            onChanged: (value) {
                              setModalState(() {
                                selectedDay = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Time Fields Row
                          Row(
                            children: [
                              // Start Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                      'start_time'.tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Mulish',
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: startTimeController,
                                      readOnly: true,
                                      // Start Time TextField - Replace onTap method
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext builder) {
                                            DateTime selectedTime = startTimeController.text.isEmpty
                                                ? DateTime.now()
                                                : DateTime(
                                              DateTime.now().year,
                                              DateTime.now().month,
                                              DateTime.now().day,
                                              int.parse(startTimeController.text.split(':')[0]),
                                              int.parse(startTimeController.text.split(':')[1]),
                                            );
                                            return Container(
                                              height: MediaQuery.of(context).size.height * 0.5,
                                              color: Colors.white,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(color: Colors.grey.shade300), // ADDED: Bottom border for header
                                                      ),
                                                    ),child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child:  Text('cancel'.tr, style: const TextStyle(color: Colors.red)),
                                                        ),
                                                         Text('select_time'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        TextButton(
                                                          onPressed: () {
                                                            startTimeController.text = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                            Navigator.pop(context);
                                                          },
                                                          child:  Text('don'.tr, style: const TextStyle(color: Colors.green)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: CupertinoDatePicker(
                                                      mode: CupertinoDatePickerMode.time,
                                                      use24hFormat: true,
                                                      initialDateTime: selectedTime,
                                                      onDateTimeChanged: (DateTime newTime) {
                                                        selectedTime = newTime;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      decoration: InputDecoration(
                                        hintText: '--:--',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Mulish',
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8F8F8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.access_time,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // End Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                      'end_time'.tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Mulish',
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: endTimeController,
                                      readOnly: true,
                                      // End Time TextField - Replace onTap method
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext builder) {
                                            DateTime selectedTime = endTimeController.text.isEmpty
                                                ? DateTime.now()
                                                : DateTime(
                                              DateTime.now().year,
                                              DateTime.now().month,
                                              DateTime.now().day,
                                              int.parse(endTimeController.text.split(':')[0]),
                                              int.parse(endTimeController.text.split(':')[1]),
                                            );
                                            return Container(
                                              height: MediaQuery.of(context).size.height * 0.5,
                                              color: Colors.white,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(color: Colors.grey.shade300), // ADDED: Bottom border for header
                                                      ),
                                                    ),child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child:  const Text('cancel', style: TextStyle(color: Colors.red)),
                                                        ),
                                                         const Text('select_time', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        TextButton(
                                                          onPressed: () {
                                                            endTimeController.text = '${selectedTime.hour.toString().padLeft(2, '0')}:'
                                                                '${selectedTime.minute.toString().padLeft(2, '0')}:00';
                                                            Navigator.pop(context);
                                                          },
                                                          child:  const Text('don', style: TextStyle(color: Colors.green)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: CupertinoDatePicker(
                                                      mode: CupertinoDatePickerMode.time,
                                                      use24hFormat: true,
                                                      initialDateTime: selectedTime,
                                                      onDateTimeChanged: (DateTime newTime) {
                                                        selectedTime = newTime;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      decoration: InputDecoration(
                                        hintText: '--:--',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Mulish',
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8F8F8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.access_time,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff757B8F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child:  Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isDelivery) {
                                      updateDeliveryTime(
                                        id: timeData.id.toString(),
                                        name: nameController.text,
                                        dayOfWeek: selectedDay,
                                        startTime: startTimeController.text,
                                        endTime: endTimeController.text,
                                      );
                                    } else {
                                      updateCollectionTime(
                                        id: timeData.id.toString(),
                                        name: nameController.text,
                                        dayOfWeek: selectedDay,
                                        startTime: startTimeController.text,
                                        endTime: endTimeController.text,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:  Text(
                                    'update'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -90,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: const Icon(Icons.close, size: 30, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveBulkDeliveryTime({
    required Map<int, TextEditingController> nameControllers,
    required List<int> selectedDays,
    required Map<int, List<Map<String, String>>> dayTimeSlots,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      List<Map<String, dynamic>> map = [];

      // Create array for each day with its own name and time slots
      for (int day in selectedDays) {
        String dayName = nameControllers[day]!.text;
        for (var timeSlot in dayTimeSlots[day]!) {
          map.add({
            "day_of_week": day,
            "start_time": "${timeSlot['startTime']}.942Z",
            "end_time": "${timeSlot['endTime']}.942Z",
            "name": dayName
          });
        }
      }

      print("Add Bulk Delivery Time Map: $map");

      AddDeliveryTimeStore model = await CallService().addDeliveryTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${map.length} ${'deli_time'.tr}'),
            backgroundColor: Colors.green,
          ),
        );
        await getDeliveryTime(showLoader: false);
      }
    } catch (e) {
      Get.back();
      print('Error saving Bulk Delivery Time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('fail_time'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveBulkCollectionTime({
    required Map<int, TextEditingController> nameControllers,
    required List<int> selectedDays,
    required Map<int, List<Map<String, String>>> dayTimeSlots,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      List<Map<String, dynamic>> map = [];

      // Create array for each day with its own name and time slots
      for (int day in selectedDays) {
        String dayName = nameControllers[day]!.text;
        for (var timeSlot in dayTimeSlots[day]!) {
          map.add({
            "day_of_week": day,
            "start_time": "${timeSlot['startTime']}.942Z",
            "end_time": "${timeSlot['endTime']}.942Z",
            "name": dayName
          });
        }
      }

      print("Add Bulk Collection Time Map: $map");

      AddCollectionTimeStore model = await CallService().addCollectionTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${map.length} ${'collec_time'.tr}'),
            backgroundColor: Colors.green,
          ),
        );
        await getCollectionTime(showLoader: false);
      }
    } catch (e) {
      Get.back();
      print('Error saving Bulk Collection Time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('fail_collec'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> getDeliveryTime({bool showLoader = true}) async {
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
      List<GetDeliveryTimeStore> deliveryTime = await CallService().getDeliveryTime(storeId!);
      print('delivery Time length is ${deliveryTime.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          delivery=deliveryTime;
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting delivery Time: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getCollectionTime({bool showLoader = true}) async {
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
      List<GetCollectionTimeStore> collectionTime = await CallService().getCollectionTime(storeId!);
      print('collection Time length is ${collectionTime.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          collection=collectionTime;
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting collection Time: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Widget buildDeliveryTime() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            // gradient: const LinearGradient(
            //   colors: [Color(0xFF0C831F), Color(0xFF0A6B19)],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // ),
            color: const Color(0xFFECF8FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'name'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'day_of'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'start_time'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'end_time'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _listRebuildNotifier,
          builder: (context, value, child) {
            return SlidableAutoCloseBehavior(
              key: ValueKey(value),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: delivery.length,
                itemBuilder: (context, index) {
                  var time = delivery[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Slidable(
                      key: ValueKey(delivery[index].id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.4,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showEditTimeBottomSheet(context, true, time),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4,left: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0C831F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showDeleteTimeConfirmation(
                                context,
                                time.name ?? 'this time',
                                time.id ?? 0,
                                true,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4,left: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE25454),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                time.name.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Mulish',
                                  color: Color(0xFF2D3748),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                getDayName(time.dayOfWeek!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  color: Color(0xFF4A5568),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7ED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  time.startTime.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    fontFamily: 'Mulish',
                                    color: Color(0xFF0C831F),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5E6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  time.endTime.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Mulish',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFCAE03),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget collectionTime() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'name'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'day_of'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'start_time',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'end_time'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'Mulish',

                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _listRebuildNotifier,
          builder: (context, value, child) {
            return SlidableAutoCloseBehavior(
              key: ValueKey(value),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: collection.length,
                itemBuilder: (context, index) {
                  var collectionTime = collection[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Slidable(
                      key: ValueKey(collection[index].id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.4,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showEditTimeBottomSheet(context, false, collectionTime),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4,left: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0C831F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showDeleteTimeConfirmation(
                                context,
                                collectionTime.name ?? 'this time',
                                collectionTime.id ?? 0,
                                false,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4,left: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE25454),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                collectionTime.name.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Mulish',
                                  color: Color(0xFF2D3748),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                getDayName(collectionTime.dayOfWeek!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  color: Color(0xFF4A5568),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7ED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  collectionTime.startTime.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    fontFamily: 'Mulish',
                                    color: Color(0xFF0C831F),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5E6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  collectionTime.endTime.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Mulish',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFCAE03),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> saveDeliveryTime({
    required String name,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      var map = [
        {
          "day_of_week": dayOfWeek,
          "start_time": "$startTime.942Z",
          "end_time": "$endTime.942Z",
          "name": name
        }
      ];

      print("Add Delivery Time Map: $map");

      AddDeliveryTimeStore model = await CallService().addDeliveryTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery Time added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await getDeliveryTime(showLoader: false); // Refresh list
      }
    } catch (e) {
      Get.back();
      print('Error saving Delivery Time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add Delivery Time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveCollectionTime({
    required String name,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      var map = [
        {
          "day_of_week": dayOfWeek,
          "start_time": "$startTime.942Z",
          "end_time": "$endTime.942Z",
          "name": name
        }
      ];

      print("Add Collection Time Map: $map");

      AddCollectionTimeStore model = await CallService().addCollectionTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection Time added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await getCollectionTime(showLoader: false); // Refresh list
      }
    } catch (e) {
      Get.back();
      print('Error saving Collection time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add Collection Time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> updateDeliveryTime({
    required String id,
    required String name,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      var map = {
        "day_of_week": dayOfWeek,
        "start_time": "$startTime.942Z",
        "end_time": "$endTime.942Z",
        "name": name
      };

      print("Update delivery time Map: $map");

      EditDeliveryTimeStore model = await CallService().editDeliveryTime(map, id);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Slidable.of(context)?.close();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery time updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await getDeliveryTime(showLoader: false);
        _listRebuildNotifier.value++;
      }
    } catch (e) {
      Get.back();
      print('Error updating Delivery time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update Delivery Time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> updateCollectionTime({
    required String id,
    required String name,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      var map = {
        "day_of_week": dayOfWeek,
        "start_time": "$startTime.942Z",
        "end_time": "$endTime.942Z",
        "name": name
      };

      print("Update Collection Time Map: $map");

      EditCollectionTimeStore model = await CallService().editCollectionTime(map, id);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Slidable.of(context)?.close();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection Time updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await getCollectionTime(showLoader: false);
        _listRebuildNotifier.value++;
      }
    } catch (e) {
      Get.back();
      print('Error updating collection time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update Collection Time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveAllDaysDeliveryTime({
    required String name,
    required List<Map<String, String>> timeSlots,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      List<Map<String, dynamic>> map = [];

      // Create entry for each day (0-6) with each time slot
      for (int day = 0; day < 7; day++) {
        for (var timeSlot in timeSlots) {
          map.add({
            "day_of_week": day,
            "start_time": "${timeSlot['startTime']}.942Z",
            "end_time": "${timeSlot['endTime']}.942Z",
            "name": name
          });
        }
      }

      print("Add All Days Delivery Time Map: $map");

      AddDeliveryTimeStore model = await CallService().addDeliveryTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${map.length} Delivery Times added for all days'),
            backgroundColor: Colors.green,
          ),
        );
        await getDeliveryTime(showLoader: false);
      }
    } catch (e) {
      Get.back();
      print('Error saving All Days Delivery Time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add Delivery Times'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveAllDaysCollectionTime({
    required String name,
    required List<Map<String, String>> timeSlots,
  }) async
  {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      return;
    }

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
        ),
      ),
      barrierDismissible: false,
    );

    try {
      List<Map<String, dynamic>> map = [];

      // Create entry for each day (0-6) with each time slot
      for (int day = 0; day < 7; day++) {
        for (var timeSlot in timeSlots) {
          map.add({
            "day_of_week": day,
            "start_time": "${timeSlot['startTime']}.942Z",
            "end_time": "${timeSlot['endTime']}.942Z",
            "name": name
          });
        }
      }

      print("Add All Days Collection Time Map: $map");

      AddCollectionTimeStore model = await CallService().addCollectionTime(map, storeId!);

      Get.back();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${map.length} Collection Times added for all days'),
            backgroundColor: Colors.green,
          ),
        );
        await getCollectionTime(showLoader: false);
      }
    } catch (e) {
      Get.back();
      print('Error saving All Days Collection Time: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add Collection Times'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showDeleteTimeConfirmation(BuildContext context, String timeName, int timeId, bool isDelivery) {
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
                      'Are you sure you want to delete "$timeName"?',
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
                              deleteTime(timeId, isDelivery);
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

  Future<void> deleteTime(int timeId, bool isDelivery) async {
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

    try {
      if (isDelivery) {
        await CallService().deleteDeliveryTime(timeId.toString());
      } else {
        await CallService().deleteCollectionTime(timeId.toString());
      }

      Get.back();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDelivery ? 'Delivery time deleted successfully' : 'Collection time deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Refresh the appropriate list
        if (isDelivery) {
          await getDeliveryTime(showLoader: false);
        } else {
          await getCollectionTime(showLoader: false);
        }
      }
    } catch (e) {
      Get.back();
      print('Error deleting time: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete time'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
