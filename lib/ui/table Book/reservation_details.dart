import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../models/reservation/accept_decline_reservation_response_model.dart';
import '../../models/reservation/edit_reservation_details_response_model.dart';
import '../../models/reservation/get_reservation_table_full_details.dart';

class ReservationDetails extends StatefulWidget {
  final String id;
  const ReservationDetails(this.id, {super.key});

  @override
  State<ReservationDetails> createState() => _ReservationDetailsState();
}

class _ReservationDetailsState extends State<ReservationDetails> {
  bool isLoading = false;
  String orderId = '',
      date = '',
      customerName = '',
      phone = '',
      guest = '',
      reservation = '',
      note = '',
      status = '',
      email = '';
  Timer? _orderTimer;
  final TextEditingController _customerMsgController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getFullReservationDetails();
    });
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'booked':
      case 'accepted':
        return Colors.green;
      case 'cancelled':
      case 'decline':
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String date = DateFormat('dd-MM-yyyy').format(dateTime);
      String time = DateFormat('HH:mm').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return dateTimeString;
    }
  }

  void showSnackbar(String title, String message, {Color? backgroundColor}) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/reservationIcon.png',
                height: 20,
                width: 20,
              ),
            ),
            Text(
              'details'.tr,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? Center(
        child: Lottie.asset(
          'assets/animations/burger.json',
          width: 150,
          height: 150,
          repeat: true,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Color(0xff757B8F)),
            Center(
              child: Text(
                '${'order_id'.tr}: $orderId',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'Mulish'),
              ),
            ),
            Center(
              child: Text(
                '${'date'.tr}: ${formatDateTime(date)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Mulish'),
              ),
            ),
            const Divider(color: Color(0xff757B8F)),
            Text(
              '${'customer'.tr} : $customerName',
              style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              '${'phone'.tr} : $phone ',
              style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              '${'guest'.tr} : $guest',
              style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Divider(color: Color(0xff757B8F)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'reservation_date'.tr}:  ${formatDateTime(reservation)}',
                  style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(color: Color(0xff757B8F)),
            const SizedBox(height: 5),
            Text(
              '${'note'.tr}:  $note',
              style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            status.toLowerCase() == 'pending' || status.isEmpty
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _showCustomerMessagePopup(actionType: 'cancelled');
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: Text(
                        'decline'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    _showCustomerMessagePopup(actionType: 'booked');
                  },
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: Text(
                        'accept'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: InkWell(
                onLongPress: status.toLowerCase() == 'booked'
                    ? () {
                  _showEditBottomSheet();
                }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: getStatusColor(status),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Status: ${status.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> getFullReservationDetails() async {
    String reservationId = widget.id;
    print('reservatiod id is $reservationId');

    setState(() {
      isLoading = true;
    });

    try {
      GetOrderDetailsResponseModel model = await CallService().getReservationFullDetails(reservationId);
      orderId = model.id.toString();
      date = model.createdAt.toString();
      customerName = model.customerName.toString();
      phone = model.customerPhone.toString();
      guest = model.guestCount.toString();
      reservation = model.reservedFor.toString();
      note = model.note.toString();
      status = model.status.toString();
      email = model.customerEmail.toString();

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      setState(() {
        isLoading = false;
        print('Reservation Table Customer Name is $customerName');
        print('Reservation Status is $status');
      });
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> acceptDeclineReservation(String statusToUpdate, {String? customerMessage}) async {
    String id = widget.id;
    try {
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
      _orderTimer = Timer(const Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("Order Timeout", "Request timed out. Please try again.");
        }
      });

      var map = <String, dynamic>{"user_id": 0, "status": statusToUpdate};
      if (customerMessage != null && customerMessage.isNotEmpty) {
        map["customer_message"] = customerMessage;
      }

      print("Status Map: $map");

      GetOrderStatusResponseModel model =
      await CallService().acceptDeclineReservation(map, id);

      await Future.delayed(const Duration(seconds: 2));
      _orderTimer?.cancel();
      print("Reservation status updated successfully to: $statusToUpdate");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      await getFullReservationDetails();

      // Small delay before showing snackbar
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'success'.tr,
          '${'reserv'.tr} ${statusToUpdate == 'booked' ? 'accepted'.tr : 'decline'.tr} ${'successfully'.tr}',
          backgroundColor: statusToUpdate == 'booked' ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      _orderTimer?.cancel();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('Status error: $e');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar('error'.tr, '${'updated_status'.tr}: ${e.toString()}');
      }
    }
  }

  Future<void> _editReservationDetail(String name, String phoneNum,
      String emailText, String guestCount, String reservationDate, String noteText,
      {String? customerMessage}) async {
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
            )),
        barrierDismissible: false,
      );

      var map = <String, dynamic>{
        "user_id": 0,
        "guest_count": int.tryParse(guestCount) ?? 2,
        "reserved_for": reservationDate,
        "status": "booked",
        "table_number": 0,
        "customer_name": name,
        "customer_phone": phoneNum,
        "customer_email": emailText,
        "note": noteText,
        "isActive": true
      };
      if (customerMessage != null && customerMessage.isNotEmpty) {
        map["customer_message"] = customerMessage;
      }

      print("Edit Reservation Map: $map");
      EditReservationDetailsResponseModel model =
      await CallService().editReservationDetails(map, widget.id.toString());

      print("Reservation updated successfully");

      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      if (Get.isBottomSheetOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      await getFullReservationDetails();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'success'.tr,
          'reserv_update'.tr,
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }
      print('Edit error: $e');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'error'.tr,
          '${'reserv_update_failed'.tr}: ${e.toString()}',
        );
      }
    }
  }

  void _showEditBottomSheet() {
    final TextEditingController nameController =
    TextEditingController(text: customerName);
    final TextEditingController phoneController =
    TextEditingController(text: phone);
    final TextEditingController guestController =
    TextEditingController(text: guest);
    final TextEditingController reservationController =
    TextEditingController(text: reservation);
    final TextEditingController noteController = TextEditingController(text: note);
    final TextEditingController emailController =
    TextEditingController(text: email);
    Get.bottomSheet(
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: Get.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  margin: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      'edit_reservation'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildEditableField(
                            'customer_name'.tr, nameController, Icons.person),
                        _buildEditableField(
                            'phone_number'.tr, phoneController, Icons.phone),
                        _buildEditableField(
                            'email_address'.tr, emailController, Icons.email),
                        _buildEditableField(
                            'guest_count'.tr, guestController, Icons.group),
                        _buildEditableField('reservation'.tr,
                            reservationController, Icons.calendar_today),
                        _buildEditableField(
                            'special_note'.tr, noteController, Icons.note,
                            maxLines: 3),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                _showCustomerMessagePopup(actionType: 'cancelled');
                              },
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                  child: Text(
                                    'cancel_reserv'.tr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                final name = nameController.text;
                                final phone = phoneController.text;
                                final email = emailController.text;
                                final guest = guestController.text;
                                final reservDate = reservationController.text;
                                final noteText = noteController.text;
                                Navigator.of(context).pop();
                                _showCustomerMessagePopup(
                                  actionType: 'save',
                                  onActionOverride: (msg) {
                                    _editReservationDetail(
                                      name, phone, email, guest, reservDate, noteText,
                                      customerMessage: msg,
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                  child: Text(
                                    'save_reserv'.tr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: Colors.white),
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
              ],
            ),
          ),
          Positioned(
            top: -60,
            right: 0,
            left: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
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
                  child: const Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  TextInputType _getKeyboardType(String label) {
    if (label == 'phone_number'.tr) {
      return TextInputType.phone;
    } else if (label == 'guest_count'.tr) {
      return TextInputType.number;
    } else if (label == 'email_address'.tr) {
      return TextInputType.emailAddress;
    } else {
      return TextInputType.text;
    }
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1}) {
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
              keyboardType: _getKeyboardType(label),
              readOnly: label == 'reservation'.tr ? true : false,
              onTap: label == 'reservation'.tr
                  ? () => _selectReservationDateTime(controller)
                  : null,
              style: const TextStyle(
                fontFamily: 'Mulish',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _getEditHintText(label),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                ),
                suffixIcon: label == 'reservation'.tr
                    ? Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[600], size: 24)
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
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

  String _getEditHintText(String label) {
    if (label == 'customer_name'.tr) {
      return 'Enter customer name';
    } else if (label == 'phone_number'.tr) {
      return 'Enter phone number';
    } else if (label == 'email_address'.tr) {
      return 'Enter email address';
    } else if (label == 'guest_count'.tr) {
      return 'Enter guest count';
    } else if (label == 'reservation'.tr) {
      return 'Select date and time';
    } else if (label == 'special_note'.tr) {
      return 'Add special note';
    } else {
      return '';
    }
  }

  Future<void> _selectReservationDateTime(
      TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      await _selectTimeSlot(selectedDate, controller);
    }
  }

  Future<void> _selectTimeSlot(
      DateTime selectedDate, TextEditingController controller) async {
    int weekday = selectedDate.weekday;

    List<TimeSlot> timeSlots = [];

    if (weekday >= 2 && weekday <= 5) {
      timeSlots = _generateTimeSlots(11, 0, 22, 45);
    } else if (weekday == 6) {
      timeSlots = _generateTimeSlots(12, 0, 22, 45);
    } else if (weekday == 7 || weekday == 1) {
      timeSlots = _generateTimeSlots(11, 0, 22, 45);
    }

    List<TimeSlot> availableSlots = timeSlots;
    bool isToday = selectedDate.day == DateTime.now().day &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.year == DateTime.now().year;

    if (isToday) {
      DateTime currentTime = DateTime.now();

      availableSlots = timeSlots.where((slot) {
        List<String> timeParts = slot.time.split(':');
        int slotHour = int.parse(timeParts[0]);
        int slotMinute = int.parse(timeParts[1]);

        DateTime slotDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          slotHour,
          slotMinute,
        );

        return slotDateTime.isAfter(currentTime);
      }).toList();

      if (availableSlots.isEmpty) {
        showSnackbar('closed', 'slot'.tr);
        return;
      }
    }

    String dayInfo = _getDayInfo(weekday);

    await Get.bottomSheet(
      Container(
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
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayInfo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
                  color: Colors.blue.shade800,
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
                    TimeSlot slot = availableSlots[index];
                    return GestureDetector(
                      onTap: () {
                        List<String> timeParts = slot.time.split(':');
                        DateTime finalDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          int.parse(timeParts[0]),
                          int.parse(timeParts[1]),
                        );

                        String formattedDateTime =
                        DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format(finalDateTime);
                        controller.text = formattedDateTime;

                        String selectedTime = slot.displayTime;
                        Navigator.of(context).pop();

                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && context.mounted) {
                            showSnackbar(
                              'time_selected'.tr,
                              '${"updated".tr} $selectedTime',
                              backgroundColor: Colors.green,
                            );
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade100,
                              Colors.green.shade200
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            slot.displayTime,
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
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  List<TimeSlot> _generateTimeSlots(
      int startHour, int startMinute, int endHour, int endMinute) {
    List<TimeSlot> slots = [];
    DateTime startTime = DateTime(2023, 1, 1, startHour, startMinute);
    DateTime endTime = DateTime(2023, 1, 1, endHour, endMinute);

    DateTime currentSlot = startTime;

    while (currentSlot.isBefore(endTime) ||
        currentSlot.isAtSameMomentAs(endTime)) {
      String time24 =
          '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      String time12 = DateFormat('h:mm a').format(currentSlot);

      slots.add(TimeSlot(time24, time12));
      currentSlot = currentSlot.add(const Duration(minutes: 20));
    }

    return slots;
  }

  String _getDayInfo(int weekday) {
    switch (weekday) {
      case 2:
      case 3:
      case 4:
      case 5:
        return 'Tuesday - Friday: 11:00 AM - 10:45 PM';
      case 6:
        return 'Saturday: 12:00 PM - 10:45 PM';
      case 7:
      case 1:
        return 'Sunday/Monday: 11:00 AM - 10:45 PM';
      default:
        return '';
    }
  }

  void _showCustomerMessagePopup({
    required String actionType,
    Function(String? customerMessage)? onActionOverride,
  }) {
    _customerMsgController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 5),
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
                    const SizedBox(height: 10),
                    const Icon(Icons.message_outlined, color: Colors.blue, size: 45),
                    const SizedBox(height: 12),
                    Text(
                      'customer_message'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        fontFamily: 'Mulish',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'send_msg_to_customer'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: 'Mulish',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerMsgController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'type_msg_here'.tr,
                        hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Mulish'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              if (onActionOverride != null) {
                                onActionOverride(null);
                              } else {
                                acceptDeclineReservation(actionType);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'skip'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              String msg = _customerMsgController.text.trim();
                              Navigator.of(dialogContext).pop();
                              if (onActionOverride != null) {
                                onActionOverride(msg.isEmpty ? null : msg);
                              } else {
                                acceptDeclineReservation(actionType,
                                    customerMessage: msg.isEmpty ? null : msg);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'continue'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
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
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFED4C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> cancelReservation(String statusToUpdate) async {
    String id = widget.id;
    try {
      _orderTimer = Timer(const Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("Order Timeout", "Request timed out. Please try again.");
        }
      });

      var map = {"user_id": 0, "status": statusToUpdate};
      print("Status Map: $map");

      GetOrderStatusResponseModel model =
      await CallService().acceptDeclineReservation(map, id);

      await Future.delayed(const Duration(seconds: 1));
      _orderTimer?.cancel();

      print("Reservation status updated successfully to: $statusToUpdate");

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      await getFullReservationDetails();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'success'.tr,
          'reserv_cancelled'.tr,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _orderTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('Cancel reservation error: $e');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'error'.tr,
          '${'failed_cancelled'.tr}: ${e.toString()}',
        );
      }
    }
  }
}

class TimeSlot {
  final String time;
  final String displayTime;

  TimeSlot(this.time, this.displayTime);
}