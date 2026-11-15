import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../models/Booking V2/get_bookingV2_detail_model.dart';

/// updateBookingV2Details with the app's full-screen burger loader shown while it runs.
Future<BookingV2DetailsModel> updateBookingWithLoader(dynamic body, String bookingId) async {
  Get.dialog(
    Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
    barrierDismissible: false,
  );
  try {
    return await CallService().updateBookingV2Details(body, bookingId);
  } finally {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}
