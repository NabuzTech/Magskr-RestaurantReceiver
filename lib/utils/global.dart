import 'package:flutter/material.dart';
import 'package:food_receiver/utils/printer_helper_english.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../models/order_model.dart';
import '../models/reservation/get_user_reservation_details.dart';
import 'my_application.dart';

Set<int> _processedOrderIds = <int>{};
Map<int, DateTime> _orderProcessingTime = <int, DateTime>{};

// ✅ NEW: Clean old processed orders (older than 1 hour)
void _cleanOldProcessedOrders() {
  final now = DateTime.now();
  final oneHourAgo = now.subtract(const Duration(hours: 1));

  _orderProcessingTime.removeWhere((orderId, time) => time.isBefore(oneHourAgo));
  _processedOrderIds.removeWhere((orderId) => !_orderProcessingTime.containsKey(orderId));

  print("🧹 Cleaned old processed orders. Current tracked: ${_processedOrderIds.length}");
}

Future<void> getOrdersInBackground() async {
  try {
    print("🔄 Background order refresh started");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    String? storeID = prefs.getString(valueShared_STORE_KEY);

    if (bearerKey == null || bearerKey.isEmpty) {
      print("❌ No bearer token found");
      return;
    }

    if (storeID == null || storeID.isEmpty) {
      print("❌ No store ID found");
      return;
    }

    DateTime formatted = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(formatted);

    final Map<String, dynamic> data = {
      "store_id": storeID,
      "target_date": date,
      "limit": 0,
      "offset": 0,
    };

    final result = await ApiRepo().orderGetApiFilter(bearerKey, data);

    if (result.isNotEmpty && result.first.code == null) {
      print("✅ Background orders fetched: ${result.length} orders");

      // ✅ Update app controller with new orders
      app.appController.setOrders(result);

      print("✅ Orders list updated in app controller");
    } else {
      print("⚠️ No orders returned from API");
    }
  } catch (e) {
    print("❌ Background order fetch error: $e");
  }
}

Future<String> getStoreName() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // First try to get cached store name
    String? cachedStoreName = prefs.getString('cached_store_name');
    if (cachedStoreName != null && cachedStoreName.isNotEmpty) {
      print("✅ Using cached store name: $cachedStoreName");
      return cachedStoreName;
    }

    // If not cached, fetch from API
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    String? storeID = prefs.getString(valueShared_STORE_KEY);

    if (bearerKey != null && storeID != null) {
      final storeData = await ApiRepo().getStoreData(bearerKey, storeID);
      if (storeData.name != null) {
        String storeName = storeData.name.toString();
        // Cache the store name for future use
        await prefs.setString('cached_store_name', storeName);
        print("✅ Fetched and cached store name: $storeName");
        return storeName;
      }
    }

    print("⚠️ Store name not found, using default");
    return "Restaurant"; // Default fallback
  } catch (e) {
    print("❌ Error getting store name: $e");
    return "Restaurant"; // Default fallback
  }
}

Future<void> getOrdersInForegrund(BuildContext context, int orderID) async {
  try {
    print("📱 Foreground order processing started for: $orderID");

    // ✅ Step 1: Check if this order is already being processed
    if (_processedOrderIds.contains(orderID)) {
      print("⚠️ Order $orderID already processed recently, skipping duplicate");
      return;
    }

    // ✅ Step 2: Mark this order as being processed
    _processedOrderIds.add(orderID);
    _orderProcessingTime[orderID] = DateTime.now();
    _cleanOldProcessedOrders();

    bool autoOrderAccept = false;
    bool autoOrderPrint = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);

    if (bearerKey == null) {
      print("❌ Bearer key not found in SharedPreferences");
      _processedOrderIds.remove(orderID); // Remove from processed if failed
      return;
    }

    final result = await ApiRepo().getNewOrderData(bearerKey, orderID);

    // ✅ Step 3: Check if this order already exists in controller before adding
    bool orderExists = app.appController.searchResultOrder.any((order) => order.id == result.id);

    if (orderExists) {
      print("⚠️ Order ${result.id} already exists in controller, skipping add but processing actions");
    } else {
      app.appController.addNewOrder(result);
      print("📦 New order added to controller: ${result.id}");
    }

    autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;
    autoOrderPrint = prefs.getBool('auto_order_print') ?? false;

    print("⚙️ Auto settings - Accept: $autoOrderAccept");
    print("📋 Order Status: ${result.orderStatus} (2=Accepted, 1=Pending)");

    // ✅ CHECK ORDER STATUS FIRST
    if (result.orderStatus == 2) {
      // Order is already ACCEPTED
      print("✅ Order already accepted, checking auto print");

      if (autoOrderPrint) {
        print("🖨️ Auto printing already accepted order");

        // Check if invoice is ready
        if (result.invoice != null &&
            (result.invoice?.invoiceNumber ?? '').isNotEmpty) {

          // 🔥 GET STORE NAME BEFORE PRINTING
          String storeName = await getStoreName();

          PrinterHelperEnglish.printTestFromSavedIp(
              context: context,
              order: result,
              store: storeName,
              auto: true
          );
          print("✅ Auto print completed for accepted order with store: $storeName");

        } else {
          print("❌ Invoice not ready for accepted order. Skipping print.");
        }
      }

    } else {
      // Order is PENDING - check if auto accept is enabled
      print("⏳ Order is pending, checking auto accept");

      if (autoOrderAccept) {
        print("🤖 Auto accepting pending order");

        // Step 1: Accept the order first
        await getOrders(bearerKey, true, result);

        // Step 2: Wait for backend to process
        await Future.delayed(const Duration(seconds: 2));

        // Step 3: Auto print if enabled
        if (autoOrderPrint) {
          print("🖨️ Auto printing after accept");

          // Get updated order with invoice
          final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderID);

          if (updatedOrder.invoice != null &&
              (updatedOrder.invoice?.invoiceNumber ?? '').isNotEmpty) {

            // 🔥 GET STORE NAME BEFORE PRINTING
            String storeName = await getStoreName();

            // Print the order
            PrinterHelperEnglish.printTestFromSavedIp(
                context: context,
                order: updatedOrder,
                store: storeName,
                auto: true
            );
            print("✅ Auto print completed after accept with store: $storeName");

          } else {
            print("❌ Invoice not ready after accept. Skipping print.");
          }
        }
      } else {
        print("🔄 Order pending, auto accept disabled - waiting for manual accept");
      }
    }

    } catch (e) {
    showSnackbar("Api Error", "An error occurred: $e");
    print("❌ Foreground order processing error: $e");
    _processedOrderIds.remove(orderID); // Remove from processed if failed
  }
}

Future<void> getOrders(String bearerKey, bool orderStatus, Order updatedOrder) async {
  Map<String, dynamic> jsonData = {
    "order_status": orderStatus ? 2 : 1,
    "approval_status": orderStatus ? 2 : 3,
  };

  try {
    print("📤 ${orderStatus ? 'Accepting' : 'Declining'} order: ${updatedOrder.id}");

    final result = await ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);

    updatedOrder = result;

    // Safe controller update
    try {
      app.appController.updateOrder(result);
      print("✅ Order ${orderStatus ? 'Accepted' : 'Declined'}: ID ${updatedOrder.id}");
    } catch (e) {
      print("⚠️ Controller update failed: $e");
    }

    } catch (e) {
    print("❌ Exception in getOrders: $e");
  }
}

Future<void> processOrderInBackground(int orderID) async {
  try {
    print("🌙 Background order processing: $orderID");

    // ✅ Check for duplicates in background too
    if (_processedOrderIds.contains(orderID)) {
      print("⚠️ Background - Order $orderID already processed, skipping");
      return;
    }

    _processedOrderIds.add(orderID);
    _orderProcessingTime[orderID] = DateTime.now();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    bool autoAccept = prefs.getBool('auto_order_accept') ?? false;
    bool autoPrint = prefs.getBool('auto_order_print') ?? false;

    if (bearerKey == null) {
      _processedOrderIds.remove(orderID);
      return;
    }

    // Get order data
    final orderData = await ApiRepo().getNewOrderData(bearerKey, orderID);

    // Auto accept
    if (autoAccept) {
      await getOrders(bearerKey, true, orderData);
      await Future.delayed(const Duration(seconds: 2));

      // Auto print after accept
      if (autoPrint) {
        final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderID);
        if (updatedOrder.invoice != null) {
          print("🖨️ Background printing order: $orderID");
        }
      }
    }

    // Refresh orders
    await getOrdersInBackground();

  } catch (e) {
    print("❌ Background processing error: $e");
    _processedOrderIds.remove(orderID); // Remove if failed
  }
}

// ✅ NEW: Method to clear processed orders manually
void clearProcessedOrders() {
  _processedOrderIds.clear();
  _orderProcessingTime.clear();
  print("🧹 Manually cleared all processed order tracking");
}

// ✅ NEW: Method to check if order was recently processed
bool wasOrderRecentlyProcessed(int orderID) {
  return _processedOrderIds.contains(orderID);
}

// In global.dart, add these methods:

Future<void> getReservationsInBackground() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);

    if (bearerKey != null) {
      List<GetUserReservationDetailsResponseModel> reservations =
      await CallService().getReservationDetailsList();

      app.appController.setReservations(reservations);
    }
  } catch (e) {
    print("Error in background reservation fetch: $e");
  }
}

Future<void> getReservationInForeground(int reservationID) async {
  try {
    print("📱 Processing new reservation: $reservationID");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);

    if (bearerKey != null) {
      var reservation = await CallService().getNewReservationData(bearerKey, reservationID);

      app.appController.addNewReservation(reservation);
      print("✅ Reservation $reservationID added to controller");
        }
  } catch (e) {
    print("❌ Error in foreground reservation processing: $e");
  }
}