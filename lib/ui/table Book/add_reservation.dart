import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/Socket/reservation_socket_service.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/reservation/add_new_reservation_response_model.dart';

class AddReservationScreen extends StatefulWidget {
  final List<Map<String, String>> availableTimeSlots;
  final SocketService socketService;

  const AddReservationScreen({
    Key? key,
    required this.availableTimeSlots,
    required this.socketService,
  }) : super(key: key);

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController guestController = TextEditingController(text: "2");
  final TextEditingController reservationController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String? storeId;
  SharedPreferences? sharedPreferences;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.grey.shade300,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Color(0xffEEEEEE),width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 0),
                    blurRadius: 9,spreadRadius: 0
                  )
                ]
              ),
                child: Center(
                    child: SvgPicture.asset('assets/images/home.svg',height: 20,))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'new_reservation'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
              ),
            ),
            const SizedBox(height: 20),
            _buildAddReservationField('customer_name'.tr, nameController, Icons.person),
            _buildAddReservationField('phone_number'.tr, phoneController, Icons.phone),
            _buildAddReservationField('email_address'.tr, emailController, Icons.email),
            _buildAddReservationField('guest_count'.tr, guestController, Icons.group),
            _buildAddReservationField('reservation_date'.tr, reservationController, Icons.calendar_today, isDateField: true),
            _buildAddReservationField('special_note'.tr, noteController, Icons.note, maxLines: 3),

            const SizedBox(height: 20),
            // Row(
            //   children: [
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () {
            //           Navigator.of(context).pop();
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.grey[300],
            //           foregroundColor: Colors.black87,
            //           minimumSize: const Size(0, 50),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(3),
            //           ),
            //         ),
            //         child: Text('cancel'.tr, style: const TextStyle(
            //           fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 16,),),
            //       ),
            //     ),
            //     const SizedBox(width: 15),
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () {
            //           _createNewReservation(
            //             nameController.text,
            //             phoneController.text,
            //             emailController.text,
            //             guestController.text,
            //             reservationController.text,
            //             noteController.text,
            //           );
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: const Color(0xff0C831F),
            //           foregroundColor: Colors.white,
            //           minimumSize: const Size(0, 50),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(3),
            //           ),
            //         ),
            //         child: Center(child: Text('book'.tr, style: const TextStyle(
            //           fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 16,
            //         ),)),
            //       ),
            //     ),
            //   ],
            // ),
            GestureDetector(
              onTap: (){} ,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Color(0xff0C831F)
                ),
                child: Center(
                  child: Text('Continue',style: TextStyle(
                    fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',fontSize: 16,
                    color: Colors.white
                  ),),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReservationField(String label, TextEditingController controller,
      IconData icon, {int maxLines = 1, bool isDateField = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Mulish',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: isDateField,
              keyboardType: _getKeyboardType(label),
              onTap: isDateField ? () => _selectNewReservationDateTime(controller) : null,
              style: const TextStyle(
                fontFamily: 'Mulish',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _getHintText(label),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Mulish',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
                suffixIcon: isDateField
                    ? Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 24)
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: maxLines > 1 ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String label) {
    switch (label) {
      case 'Phone Number':
        return TextInputType.phone;
      case 'Guest Count':
        return TextInputType.number;
      case 'Email Address':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Customer Name':
        return 'name'.tr;
      case 'Phone Number':
        return 'contact_number'.tr;
      case 'Email Address':
        return 'email'.tr;
      case 'Guest Count':
        return 'guest_count'.tr;
      case 'Reservation Date':
        return 'dd'.tr;
      case 'Special Note':
        return 'type_note'.tr;
      default:
        return '';
    }
  }

  Future<void> _selectNewReservationDateTime(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      await _selectNewTimeSlot(selectedDate, controller);
    }
  }

  Future<void> _selectNewTimeSlot(DateTime selectedDate, TextEditingController controller) async {
    List<Map<String, String>> timeSlots = [];

    if (widget.availableTimeSlots.isEmpty) {
      print("⚠️ No time slots from WebSocket. Using default timings.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Store timing data not available. Using default timings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      timeSlots = _generateDefaultTimeSlots();
    } else {
      timeSlots = List.from(widget.availableTimeSlots);
    }

    List<Map<String, String>> availableSlots = timeSlots;
    bool isToday = selectedDate.day == DateTime.now().day &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.year == DateTime.now().year;

    if (isToday) {
      DateTime nowUtc = DateTime.now().toUtc();
      bool isDST = _isDaylightSavingTime(nowUtc);
      int germanyOffset = isDST ? 2 : 1;
      DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));
      int currentHour = nowGermany.hour;
      int currentMinute = nowGermany.minute;

      availableSlots = timeSlots.where((slot) {
        List<String> timeParts = slot['time24']!.split(':');
        int slotHour = int.parse(timeParts[0]);
        int slotMinute = int.parse(timeParts[1]);
        int slotTotalMinutes = (slotHour * 60) + slotMinute;
        int currentTotalMinutes = (currentHour * 60) + currentMinute;
        return slotTotalMinutes > currentTotalMinutes;
      }).toList();

      if (availableSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'closed'.tr} - No available time slots for today'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          height: Get.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'time_slot'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${'date'.tr}: ${DateFormat('dd-MM-yyyy (EEEE)').format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      var slot = availableSlots[index];
                      return GestureDetector(
                        onTap: () {
                          List<String> timeParts = slot['time24']!.split(':');
                          DateTime finalDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            int.parse(timeParts[0]),
                            int.parse(timeParts[1]),
                          );
                          String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
                          controller.text = formattedDateTime;
                          Navigator.pop(bottomSheetContext);

                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${'time_selected'.tr}: ${slot['time24']}'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade100, Colors.green.shade200],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Center(
                            child: Text(
                              slot['time24']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  bool _isDaylightSavingTime(DateTime dateTime) {
    int year = dateTime.year;
    DateTime marchEnd = DateTime.utc(year, 3, 31);
    while (marchEnd.weekday != DateTime.sunday) {
      marchEnd = marchEnd.subtract(const Duration(days: 1));
    }
    DateTime octoberEnd = DateTime.utc(year, 10, 31);
    while (octoberEnd.weekday != DateTime.sunday) {
      octoberEnd = octoberEnd.subtract(const Duration(days: 1));
    }
    DateTime dstStart = DateTime.utc(year, marchEnd.month, marchEnd.day, 2, 0);
    DateTime dstEnd = DateTime.utc(year, octoberEnd.month, octoberEnd.day, 3, 0);
    return dateTime.isAfter(dstStart) && dateTime.isBefore(dstEnd);
  }

  List<Map<String, String>> _generateDefaultTimeSlots() {
    List<Map<String, String>> slots = [];
    DateTime startTime = DateTime(2023, 1, 1, 10, 0);
    DateTime endTime = DateTime(2023, 1, 1, 22, 0);
    DateTime currentSlot = startTime;

    while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
      String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      String time12 = DateFormat('h:mm a').format(currentSlot);
      slots.add({'time24': time24, 'time12': time12});
      currentSlot = currentSlot.add(const Duration(minutes: 20));
    }
    return slots;
  }

  Future<void> _createNewReservation(String name, String phone, String email, String guestCount, String reservationDate, String note) async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }

    if (name.isEmpty || phone.isEmpty || reservationDate.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'fill'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
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

      var map = {
        "store_id": storeId,
        "user_id": 0,
        "guest_count": int.tryParse(guestCount),
        "reserved_for": reservationDate,
        "status": "booked",
        "table_number": 0,
        "customer_name": name,
        "customer_email": email,
        "customer_phone": phone,
        "note": note,
        "isActive": true
      };

      AddNewReservationResponseModel model = await CallService().addReservation(map);

      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr} - ${'create_reserv'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

//
// Widget _buildAddReservationBottomSheet() {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController guestController = TextEditingController(text: "2");
//   final TextEditingController reservationController = TextEditingController();
//   final TextEditingController noteController = TextEditingController();
//
//   return Stack(
//       clipBehavior: Clip.none,
//       children:[
//         Container(
//           height: Get.height * 0.85,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(35),
//               topRight: Radius.circular(35),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 10,
//                 offset: Offset(0, -5),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Container(
//                 margin: const EdgeInsets.only(top: 12),
//                 width: 50,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                 margin: const EdgeInsets.all(8),
//                 child: Center(
//                   child: Text(
//                     'new_reservation'.tr,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   physics: const BouncingScrollPhysics(),
//                   child: Column(
//                     children: [
//                       _buildAddReservationField('customer_name'.tr, nameController, Icons.person),
//                       _buildAddReservationField('phone_number'.tr, phoneController, Icons.phone),
//                       _buildAddReservationField('email_address'.tr, emailController, Icons.email),
//                       _buildAddReservationField('guest_count'.tr, guestController, Icons.group),
//                       _buildAddReservationField('reservation_date'.tr, reservationController, Icons.calendar_today, isDateField: true),
//                       _buildAddReservationField('special_note'.tr, noteController, Icons.note, maxLines: 3),
//
//                       const SizedBox(height: 15),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 // Close bottom sheet without triggering Get.back() multiple times
//                                 Navigator.of(context).pop();
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.grey[300],
//                                 foregroundColor: Colors.black87,
//                                 minimumSize: const Size(0, 50),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(3),
//                                 ),
//                               ),
//                               child: Text('cancel'.tr,style: const TextStyle(
//                                 fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,),),
//                             ),
//                           ),
//                           const SizedBox(width: 15),
//                           Expanded(
//                             //flex: 2,
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 _createNewReservation(
//                                   nameController.text,
//                                   phoneController.text,
//                                   emailController.text,
//                                   guestController.text,
//                                   reservationController.text,
//                                   noteController.text,
//                                 );
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xff0C831F),
//                                 foregroundColor: Colors.white,
//                                 minimumSize: const Size(0, 50),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(3),
//                                 ),
//                               ),
//                               child:  Center(child: Text('book'.tr,style: const TextStyle(
//                                 fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,
//                               ),)),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           top: -60,
//           right: 0,
//           left: 0,
//           child: Center(
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: const BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 6,
//                     )
//                   ],
//                 ),
//                 child: const Icon(Icons.close, size: 20, color: Colors.black),
//               ),
//             ),
//           ),
//         ),
//       ]
//   );
// }
//
// Widget _buildAddReservationField(String label, TextEditingController controller,
//     IconData icon, {int maxLines = 1, bool isDateField = false}) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 20),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8),
//           child: Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//               fontFamily: 'Mulish',
//             ),
//           ),
//         ),
//
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!, width: 1),
//           ),
//           child: TextFormField(
//             controller: controller,
//             maxLines: maxLines,
//             readOnly: isDateField,
//             keyboardType: _getKeyboardType(label),
//             onTap: isDateField ? () => _selectNewReservationDateTime(controller) : null,
//             style: const TextStyle(
//               fontFamily: 'Mulish',
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: Colors.black87,
//             ),
//             decoration: InputDecoration(
//               hintText: _getHintText(label),
//               hintStyle: TextStyle(
//                 color: Colors.grey[500],
//                 fontFamily: 'Mulish',
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//               prefixIcon: Container(
//                 padding: const EdgeInsets.all(8),
//                 child: Icon(
//                   icon,
//                   color: Colors.grey[600],
//                   size: 18,
//                 ),
//               ),
//               suffixIcon: isDateField
//                   ? Icon(Icons.keyboard_arrow_down,
//                   color: Colors.grey[600],
//                   size: 24)
//                   : null,
//               border: InputBorder.none,
//               enabledBorder: InputBorder.none,
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
//               ),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: maxLines > 1 ? 16 : 18,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
// String _getHintText(String label) {
//   switch (label) {
//     case 'Customer Name':
//       return 'name'.tr;
//     case 'Phone Number':
//       return 'contact_number'.tr;
//     case 'Email Address':
//       return 'email'.tr;
//     case 'Guest Count':
//       return 'guest_count'.tr;
//     case 'Reservation Date':
//       return 'dd'.tr;
//     case 'Special Note':
//       return 'type_note'.tr;
//     default:
//       return '';
//   }
// }
//
// Future<void> _selectNewReservationDateTime(TextEditingController controller) async {
//   DateTime? selectedDate = await showDatePicker(
//     context: context,
//     initialDate: DateTime.now(),
//     firstDate: DateTime.now(),
//     lastDate: DateTime.now().add(const Duration(days: 365)),
//     builder: (context, child) {
//       return Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: ColorScheme.light(
//             primary: Colors.orange.shade600,
//             onPrimary: Colors.white,
//             onSurface: Colors.black,
//           ),
//         ),
//         child: child!,
//       );
//     },
//   );
//
//   if (selectedDate != null) {
//     await _selectNewTimeSlot(selectedDate, controller);
//   }
// }
//
// Future<void> _selectNewTimeSlot(DateTime selectedDate, TextEditingController controller) async {
//   List<Map<String, String>> timeSlots = [];
//
//   // ✅ Check if WebSocket data is available
//   if (availableTimeSlots.isEmpty) {
//     print("⚠️ No time slots from WebSocket. Trying to reconnect...");
//
//     await _socketService.ensureConnected();
//     await Future.delayed(const Duration(milliseconds: 1500));
//
//     if (availableTimeSlots.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('⚠️ Store timing data not available. Using default timings.'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//
//       timeSlots = _generateDefaultTimeSlots();
//     } else {
//       timeSlots = List.from(availableTimeSlots);
//     }
//   } else {
//     timeSlots = List.from(availableTimeSlots);
//   }
//
//   // ✅ Filter time slots based on Germany time
//   List<Map<String, String>> availableSlots = timeSlots;
//   bool isToday = selectedDate.day == DateTime.now().day &&
//       selectedDate.month == DateTime.now().month &&
//       selectedDate.year == DateTime.now().year;
//
//   if (isToday) {
//     // ✅ Get current time in UTC
//     DateTime nowUtc = DateTime.now().toUtc();
//
//     // ✅ Germany timezone offset (check if DST is active)
//     bool isDST = _isDaylightSavingTime(nowUtc);
//     int germanyOffset = isDST ? 2 : 1; // UTC+2 in summer, UTC+1 in winter
//
//     // ✅ Get current Germany time
//     DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));
//
//     // ✅ CRITICAL FIX: Get current Germany hour and minute for comparison
//     int currentHour = nowGermany.hour;
//     int currentMinute = nowGermany.minute;
//
//     print("⏰ Current Germany time: ${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}");
//     print("🌍 UTC time: ${DateFormat('HH:mm').format(nowUtc)}");
//     print("☀️ DST Active: $isDST (Offset: +$germanyOffset hours)");
//
//     availableSlots = timeSlots.where((slot) {
//       List<String> timeParts = slot['time24']!.split(':');
//       int slotHour = int.parse(timeParts[0]);
//       int slotMinute = int.parse(timeParts[1]);
//
//       // ✅ FIXED: Compare slot time directly with current Germany time
//       // Convert to total minutes for accurate comparison
//       int slotTotalMinutes = (slotHour * 60) + slotMinute;
//       int currentTotalMinutes = (currentHour * 60) + currentMinute;
//
//       // ✅ Slot must be after current Germany time
//       bool isAvailable = slotTotalMinutes > currentTotalMinutes;
//
//       if (!isAvailable) {
//         print("❌ Slot ${slot['time24']} is in past ($slotTotalMinutes <= $currentTotalMinutes)");
//       } else {
//         print("✅ Slot ${slot['time24']} is available ($slotTotalMinutes > $currentTotalMinutes)");
//       }
//
//       return isAvailable;
//     }).toList();
//
//     print("✅ Available slots after filtering: ${availableSlots.length}");
//
//     if (availableSlots.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${'closed'.tr} - No available time slots for today'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//       return;
//     }
//   }
//
//   String dayInfo = isStoreOpen
//       ? '✅ Store is Open - ${availableSlots.length} slots available'
//       : '⚠️ Store is Closed - Showing available slots';
//
//   final scaffoldContext = context;
//
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     isDismissible: true,
//     enableDrag: true,
//     backgroundColor: Colors.transparent,
//     builder: (BuildContext bottomSheetContext) {
//       return Container(
//         height: Get.height * 0.7,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.orange.shade600, Colors.orange.shade800],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, color: Colors.white),
//                       const SizedBox(width: 10),
//                       Text(
//                         'time_slot'.tr,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: 'Mulish',
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.close, color: Colors.white),
//                         onPressed: () => Navigator.pop(bottomSheetContext),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     dayInfo,
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 '${'date'.tr}: ${DateFormat('dd-MM-yyyy (EEEE)').format(selectedDate)}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Mulish',
//                   color: Colors.orange.shade800,
//                 ),
//               ),
//             ),
//
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: GridView.builder(
//                   physics: const BouncingScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     childAspectRatio: 2.2,
//                   ),
//                   itemCount: availableSlots.length,
//                   itemBuilder: (context, index) {
//                     var slot = availableSlots[index];
//                     return GestureDetector(
//                       onTap: () {
//                         List<String> timeParts = slot['time24']!.split(':');
//                         DateTime finalDateTime = DateTime(
//                           selectedDate.year,
//                           selectedDate.month,
//                           selectedDate.day,
//                           int.parse(timeParts[0]),
//                           int.parse(timeParts[1]),
//                         );
//
//                         String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
//                         controller.text = formattedDateTime;
//
//                         Navigator.pop(bottomSheetContext);
//
//                         Future.delayed(const Duration(milliseconds: 400), () {
//                           if (mounted) {
//                             try {
//                               ScaffoldMessenger.of(scaffoldContext).showSnackBar(
//                                 SnackBar(
//                                   content: Text('${'time_selected'.tr}: ${slot['time24']}'),
//                                   backgroundColor: Colors.green,
//                                   duration: const Duration(seconds: 1),
//                                 ),
//                               );
//                             } catch (e) {
//                               print('Error showing snackbar: $e');
//                             }
//                           }
//                         });
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.green.shade100, Colors.green.shade200],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: Colors.green.shade300),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.green.withOpacity(0.2),
//                               blurRadius: 4,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Text(
//                             slot['time24']!,
//                             style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green.shade800,
//                               fontFamily: 'Mulish',
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//           ],
//         ),
//       );
//     },
//   );
// }
//
// bool _isDaylightSavingTime(DateTime dateTime) {
//   // Germany DST: Last Sunday of March to Last Sunday of October
//   int year = dateTime.year;
//
//   // Find last Sunday of March
//   DateTime marchEnd = DateTime.utc(year, 3, 31);
//   while (marchEnd.weekday != DateTime.sunday) {
//     marchEnd = marchEnd.subtract(const Duration(days: 1));
//   }
//
//   // Find last Sunday of October
//   DateTime octoberEnd = DateTime.utc(year, 10, 31);
//   while (octoberEnd.weekday != DateTime.sunday) {
//     octoberEnd = octoberEnd.subtract(const Duration(days: 1));
//   }
//
//   // DST starts at 2:00 AM on last Sunday of March
//   DateTime dstStart = DateTime.utc(year, marchEnd.month, marchEnd.day, 2, 0);
//
//   // DST ends at 3:00 AM on last Sunday of October
//   DateTime dstEnd = DateTime.utc(year, octoberEnd.month, octoberEnd.day, 3, 0);
//
//   bool isDST = dateTime.isAfter(dstStart) && dateTime.isBefore(dstEnd);
//
//   return isDST;
// }
//
// List<Map<String, String>> _generateDefaultTimeSlots() {
//   List<Map<String, String>> slots = [];
//
//   // Default timing: 10:00 AM to 10:00 PM, 20 min intervals
//   DateTime startTime = DateTime(2023, 1, 1, 10, 0);
//   DateTime endTime = DateTime(2023, 1, 1, 22, 0);
//
//   DateTime currentSlot = startTime;
//
//   while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
//     String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
//     String time12 = DateFormat('h:mm a').format(currentSlot);
//
//     slots.add({
//       'time24': time24,
//       'time12': time12,
//     });
//
//     currentSlot = currentSlot.add(const Duration(minutes: 20));
//   }
//
//   print("✅ Generated ${slots.length} default time slots as fallback");
//   return slots;
// }
//
// Future<void> _createNewReservation(String name, String phone, String email, String guestCount, String reservationDate, String note) async {
//   if (sharedPreferences == null) {
//     Get.snackbar('error'.tr, 'shared'.tr);
//     return;
//   }
//
//   storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
//   if (storeId == null) {
//     Get.snackbar('error'.tr, 'storeId'.tr);
//     return;
//   }
//
//   // Validate inputs
//   if (name.isEmpty || phone.isEmpty || reservationDate.isEmpty) {
//     Get.snackbar(
//       'error'.tr,
//       'fill'.tr,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//     );
//     return;
//   }
//
//   setState(() {
//     isLoading = true;
//   });
//
//   try {
//     Get.dialog(
//       Center(
//           child: Lottie.asset(
//             'assets/animations/burger.json',
//             width: 150,
//             height: 150,
//             repeat: true,
//           )
//       ),
//       barrierDismissible: false,
//     );
//
//     var map =
//     {
//       "store_id": storeId,
//       "user_id": 0,
//       "guest_count": int.tryParse(guestCount),
//       "reserved_for": reservationDate,
//       "status": "booked",
//       "table_number": 0,
//       "customer_name": name,
//       "customer_email":email,
//       "customer_phone": phone,
//       "note": note,
//       "isActive": true
//     };
//
//     print("Create Reservation Map: $map");
//     AddNewReservationResponseModel model = await CallService().addReservation(map);
//
//     setState(() {
//       isLoading = false;
//     });
//
//     // ✅ Close loading dialog first
//     if (Get.isDialogOpen == true) {
//       Navigator.of(Get.overlayContext!).pop();
//     }
//
//     // Wait a bit to ensure dialog is closed
//     await Future.delayed(const Duration(milliseconds: 300));
//
//     // ✅ Close the add reservation bottom sheet FIRST
//     if (mounted && Navigator.canPop(context)) {
//       Navigator.of(context).pop();
//     }
//
//     // ✅ Wait for bottom sheet to close completely
//     await Future.delayed(const Duration(milliseconds: 400));
//
//     // Refresh reservations
//     await getReservationDetails();
//
//     // ✅ Show success snackbar AFTER everything is closed and we're back to main screen
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${'success'.tr} - ${'created'.tr}'),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//
//   } catch (e) {
//     setState(() {
//       isLoading = false;
//     });
//
//     // ✅ Close loading dialog if open
//     if (Get.isDialogOpen == true) {
//       Navigator.of(Get.overlayContext!).pop();
//     }
//
//     print('Create reservation error: $e');
//
//     // ✅ Use ScaffoldMessenger instead of Get.snackbar for error too
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${'error'.tr} - ${'create_reserv'.tr}: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }