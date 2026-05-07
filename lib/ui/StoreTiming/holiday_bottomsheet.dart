import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/create_new_holidays_response_model.dart';
import '../../models/update_holiday_response_model.dart';

class AddHolidayBottomSheet extends StatefulWidget {
  final VoidCallback? onDataAdded;
  final String? editTitle;
  final DateTime? editDate;
  final String? editStartTime;
  final String? editEndTime;
  final bool isEditMode;
  final int? editHolidayId;

  const AddHolidayBottomSheet({
    super.key,
    this.onDataAdded,
    this.editTitle,
    this.editDate,
    this.editStartTime,
    this.editEndTime,
    this.isEditMode = false,
    this.editHolidayId,
  });

  @override
  State<AddHolidayBottomSheet> createState() => _AddHolidayBottomSheetState();
}

class _AddHolidayBottomSheetState extends State<AddHolidayBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay? _selectedStartTime;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _prefillEditData();
    }
  }
  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }
  void _prefillEditData() {
    setState(() {
      if (widget.editTitle != null) {
        _titleController.text = widget.editTitle!;
      }

      if (widget.editDate != null) {
        _selectedDate = widget.editDate!;
        _focusedDay = widget.editDate!;

        // Extract time from date
        _selectedStartTime = TimeOfDay(
          hour: widget.editDate!.hour,
          minute: widget.editDate!.minute,
        );
        _startTimeController.text = _formatTimeForDisplay(_selectedStartTime!);
      }
    });
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _startTimeController.text = _formatTimeForDisplay(picked);
        } else {

        }
      });
    }
  }

  String _formatTimeForDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Please enter holiday title');
      return;
    }
    if (_selectedStartTime == null) {
      _showSnackbar('Please select time');
      return;
    }

    // Call different methods based on mode
    if (widget.isEditMode) {
      _updateHoliday();
    } else {
      _saveHoliday();
    }
  }

  Future<void> _saveHoliday() async {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      _showSnackbar('Store ID not found');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Combine selected date with selected time
      DateTime combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
        0,
      );

      var map = {
        "date": combinedDateTime.toIso8601String(),
        "store_id": int.parse(storeId!),
        "name": _titleController.text.trim(),
      };

      print("Add Holiday Map: $map");

      CreateHolidayResponseModel model = await CallService().addNewHoliday(map);

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holiday added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onDataAdded != null) {
          widget.onDataAdded!();
        }
      }
    } catch (e) {
      print('Error saving holiday: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        _showSnackbar('Failed to save holiday: ${e.toString()}');
      }
    }
  }

  Future<void> _updateHoliday() async {
    if (sharedPreferences == null) {
      await _initializeSharedPreferences();
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      _showSnackbar('Store ID not found');
      return;
    }

    if (widget.editHolidayId == null) {
      _showSnackbar('Holiday ID not found');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Combine selected date with selected time
      DateTime combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
        0,
      );

      var map = {
        "date": combinedDateTime.toIso8601String(),
        "store_id": int.parse(storeId!),
        "name": _titleController.text.trim(),
      };

      print("Update Holiday Map: $map");
      print("Holiday ID: ${widget.editHolidayId}");


      UpdateHolidayResponseModel model = await CallService().editHoliday(map,widget.editHolidayId.toString());

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holiday updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onDataAdded != null) {
          widget.onDataAdded!();
        }
      }
    } catch (e) {
      print('Error updating holiday: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        _showSnackbar('Failed to update holiday: ${e.toString()}');
      }
    }
  }
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      widget.isEditMode ? 'Edit Holiday' : 'Add Holiday',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Holiday Title
                  Text(
                    'holiday'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Add Title...',
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),


                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Month Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getMonthName(_focusedDay.month),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                  Text(
                                    ', ${_focusedDay.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Weekday Headers
                        Container(
                          child: Row(
                            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  color: const Color(0xff1F1E1E),
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Calendar Grid
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: _buildCalendarRows(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'time'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _startTimeController,
                    readOnly: true,
                    onTap: () => _selectTime(true),
                    decoration: InputDecoration(
                      hintText: '--:--',
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.access_time, size: 20),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                          onPressed: () => Navigator.pop(context),
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
                          onPressed: isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              :  Text(
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
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: const Icon(Icons.close, size: 30, color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    // Remove: _endTimeController.dispose();
    super.dispose();
  }
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  List<Widget> _buildCalendarRows() {
    List<Widget> rows = [];
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    int startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    int daysInMonth = lastDayOfMonth.day;

    List<Widget> dayCells = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < startingWeekday; i++) {
      DateTime prevMonthDay = firstDayOfMonth.subtract(Duration(days: startingWeekday - i));
      dayCells.add(_buildDayCell(prevMonthDay, isCurrentMonth: false));
    }

    // Add days of current month
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(_focusedDay.year, _focusedDay.month, day);
      dayCells.add(_buildDayCell(date, isCurrentMonth: true));
    }

    // Add empty cells to complete the grid
    int remainingCells = (7 - (dayCells.length % 7)) % 7;
    for (int i = 1; i <= remainingCells; i++) {
      DateTime nextMonthDay = lastDayOfMonth.add(Duration(days: i));
      dayCells.add(_buildDayCell(nextMonthDay, isCurrentMonth: false));
    }

    // Create rows of 7 days each
    for (int i = 0; i < dayCells.length; i += 7) {
      rows.add(
        Row(
          children: dayCells.sublist(i, i + 7),
        ),
      );
    }

    return rows;
  }

  Widget _buildDayCell(DateTime date, {required bool isCurrentMonth}) {
    bool isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    bool isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
            if (!isCurrentMonth) {
              _focusedDay = date;
            }
          });
        },
        child: Container(
          height: 45,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xffEEF5FF))
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                    ? Colors.black
                    : Colors.grey.shade400,
                fontWeight: isToday && !isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                fontFamily: 'Mulish',
              ),
            ),
          ),
        ),
      ),
    );
  }
}