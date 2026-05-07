
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/*import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_source.dart';
import '../utils/my_application.dart';*/
import 'app_color.dart';

const String Monstserrat = 'Montserrat';
const String MonstserratBold = 'Montserrat-Bold';
const String MonstserratMedium = 'Montserrat-Medium';

String valueShared_USER_KEY = 'USER_KEY';
String valueShared_BEARER_KEY = 'BEARER_KEY';
String valueShared_PROFILE_KEY = 'PROFILE_KEY';
String valueShared_USERNAME_KEY = 'USERNAME_KEY';
String valueShared_PASSWORD_KEY = 'PASSWORD_KEY';
String valueShared_STORE_KEY = 'STORE_KEY';
String valueShared_BASEURL = 'BASEURL_KEY';
String valueShared_LANGUAGE = 'LANGUAGE_KEY';
String valueShared_STORE_NAME = 'STORE_NAME_KEY';
String valueShared_STORE_TYPE = 'STORE_TYPE_KEY';
String valueShared_ROLE_ID = 'role_id';

/*
// Save the list to SharedPreferences
Future<void> saveIntList(List<int> intList) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String encodedList = jsonEncode(intList); // Convert list to JSON string
  await prefs.setString(valueShared_PROFILE_IDS_LIST, encodedList); // Save JSON string
}*/

/*// Retrieve the list from SharedPreferences
Future<List<int>> getIntList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? encodedList = prefs.getString(valueShared_PROFILE_IDS_LIST); // Read JSON string
  if (encodedList != null) {
    return List<int>.from(jsonDecode(encodedList)); // Decode JSON to List<int>
  }
  return []; // Return empty list if no data is found
}*/

// Add an ID to the list and save it
/*Future<void> addIdToProfileList(int newId) async {
  List<int> profileIds = await getIntList(); // Retrieve current list
  if (!profileIds.contains(newId)) { // Avoid duplicates
    profileIds.add(newId); // Add new ID
    await saveIntList(profileIds); // Save updated list
    print('ID $newId added to the list.');
  } else {
    print('ID $newId is already in the list.');
  }
}*/
/*
Future<void> saveIntList(String key, List<int> intList) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String encodedList = jsonEncode(intList); // Convert list to JSON string
  await prefs.setString(key, encodedList); // Save JSON string
}

Future<List<int>> getIntList(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? encodedList = prefs.getString(key); // Read JSON string
  if (encodedList != null) {
    return List<int>.from(jsonDecode(encodedList)); // Decode JSON to List<int>
  }
  return []; // Return empty list if no data is found
}*/


void showSnackbar(String title, String msg) {
  Get.snackbar(title, msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      backgroundColor: Colors.white.withOpacity(0.5),
      colorText: Colors.black);
}

appbarColor() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [
            AppColor.backgroundBlueLightColor,
            AppColor.backgroundBlueDarkColor,
          ],
          begin: FractionalOffset(0.0, 0.0),
          end: FractionalOffset(1.0, 0.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp),
    ),
  );
}

gradientContainer() {
  return const LinearGradient(
      colors: [
        AppColor.backgroundBlueLightColor,
        AppColor.backgroundBlueDarkColor,
      ],
      begin: FractionalOffset(0.0, 0.0),
      end: FractionalOffset(1.0, 0.0),
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp);
}

/*Future<void> getSchedule(bool value) async {
  var boxTicket = await Hive.openBox(scheduleFilter);
  await boxTicket.put(isScheduleFilter, value);
  app.appController.filterSchedule(value);
}*/
