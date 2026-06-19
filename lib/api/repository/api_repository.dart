import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:food_receiver/models/change_password_model.dart';
import 'package:food_receiver/models/get_admin_report_response_model.dart' hide PaymentMethods, TaxBreakdown, OrderTypes, ApprovalStatuses;
import 'package:food_receiver/models/today_report.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../constants/constant.dart';
import '../../models/DailySalesReport.dart'
    hide PaymentMethods, ApprovalStatuses, TaxBreakdown;
import '../../models/Logout.dart';
import '../../models/PrinterSetting.dart';
import '../../models/Store Owners/owners_store_today_report_model.dart' hide OrderTypes, ApprovalStatuses;
import '../../models/Store.dart';
import '../../models/StoreDetail.dart';
import '../../models/StoreSetting.dart';
import '../../models/UserMe.dart';
import '../../models/add-store_postcode_response_model.dart';
import '../../models/add_aleergy_link_response_model.dart';
import '../../models/add_allergy_response_model.dart';
import '../../models/add_collection_time_response_model.dart';
import '../../models/add_coupon_response_model.dart';
import '../../models/add_delivery_time_response_model.dart';
import '../../models/add_delivery_zone_model.dart';
import '../../models/add_new_category_availability_response_model.dart';
import '../../models/add_new_group_item_response_model.dart';
import '../../models/add_new_product_category_response_model.dart';
import '../../models/add_new_product_group_response_model.dart';
import '../../models/add_new_product_response_model.dart';
import '../../models/add_new_store_timing_response_model.dart';
import '../../models/add_new_store_topping_response_model.dart';
import '../../models/add_new_topping_group_response_model.dart';
import '../../models/add_printer_ip_response_model.dart';
import '../../models/add_tax_response_mode.dart';
import '../../models/all_admin_order_response_model.dart';
import '../../models/category_availability_management_response_model.dart';
import '../../models/create_new_holidays_response_model.dart';
import '../../models/device_status_response_model.dart';
import '../../models/discount_change_response_model.dart';
import '../../models/driver/driver_register_model.dart';
import '../../models/driver/get_deliver_driver_response_model.dart';
import '../../models/edit_allergy_item_response_model.dart';
import '../../models/edit_allergy_link_response_model.dart';
import '../../models/edit_category_availability_response_model.dart';
import '../../models/edit_collection_time_response_model.dart';
import '../../models/edit_delivery_time_response_model.dart';
import '../../models/edit_delivery_zone_model.dart';
import '../../models/edit_existing_product_category_response_model.dart';
import '../../models/edit_group_item_response_model.dart';
import '../../models/edit_postcode_response_model.dart';
import '../../models/edit_printer_ip_response_model.dart';
import '../../models/edit_product_group_response_model.dart';
import '../../models/edit_store_product_response_model.dart';
import '../../models/edit_store_toppings_response_model.dart';
import '../../models/edit_tax_response_model.dart';
import '../../models/edit_topping_group_response_model.dart';
import '../../models/get_added_tax_response_model.dart';
import '../../models/get_all_reservation_for_all_store.dart';
import '../../models/get_all_store_response_model.dart';
import '../../models/get_allergy_response_model.dart';
import '../../models/get_collection_time_response_model.dart';
import '../../models/get_coupons_response_model.dart';
import '../../models/get_customer_details_response_model.dart';
import '../../models/get_customer_order_details_response_model.dart';
import '../../models/get_delivery_time_response_model.dart';
import '../../models/get_delivery_zone_response_model.dart';
import '../../models/get_discount_percentage_response_model.dart';
import '../../models/get_group_item_response_model.dart';
import '../../models/get_holidays_response_model.dart';
import '../../models/get_item_allergy_link_response_model.dart';
import '../../models/get_notification_windows_history.dart';
import '../../models/get_printer_ip_response_model.dart';
import '../../models/get_product_category_list_response_model.dart';
import '../../models/get_product_group_response_model.dart';
import '../../models/get_search_product_response_model.dart';
import '../../models/get_specific_store_device_status_response_model.dart';
import '../../models/get_store_customer_response_model.dart';
import '../../models/get_store_postcode_response_model.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/get_store_timing_response_model.dart';
import '../../models/get_toppings_groups_response_model.dart';
import '../../models/get_toppings_response_model.dart';
import '../../models/iamge_upload_response_model.dart';
import '../../models/logout_store_by_superAdmin.dart';
import '../../models/manual_override_response_model.dart';
import '../../models/order_history_response_model.dart';
import '../../models/order_model.dart';
import '../../models/print_order_without_ip.dart';
import '../../models/reservation/accept_decline_reservation_response_model.dart';
import '../../models/reservation/add_new_reservation_response_model.dart';
import '../../models/reservation/edit_reservation_details_response_model.dart';
import '../../models/reservation/get_history_reservation.dart';
import '../../models/reservation/get_reservation_table_full_details.dart';
import '../../models/reservation/get_user_reservation_details.dart';
import '../../models/reservation/today_received_booking_model.dart';
import '../../models/reset_store_password_by_suyperAdmin_model.dart';
import '../../models/store_owners_store_model.dart';
import '../../models/sync_order_response_model.dart';
import '../../models/update_holiday_response_model.dart';
import '../../models/update_store_hour_response_model.dart';
import '../../models/windows_device_status.dart';
import '../api.dart';
import '../api_end_points.dart';
import '../api_params.dart';
import '../api_utils.dart';
import '../../models/userLogin_h.dart';
import 'package:http_parser/http_parser.dart';

const title = "ApiRepo";

class ApiRepo {
  Future<UserLoginH> loginApi(
      String email, String password, String deviceToken) async
  {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Error Internet connectivity");
      return UserLoginH.withError(
          code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
    }

    String url = Api.baseUrl + ApiEndPoints.login;
    Map<String, dynamic> loginData = {
      'username': email,
      'password': password,
      'device_token': deviceToken,
    };

    FormData formData = FormData.fromMap(loginData);

    try {
      final response = await apiUtils.post(url: url, data: formData);
      print("REsponseData $response");
      return UserLoginH.fromJson(response.data);
    } catch (e) {
      return UserLoginH.withError(
          code: CODE_ERROR, mess: apiUtils.handleError(e));
    }
  }

  Future<UserLoginH> resetPasswordApi(String password, String cPassword) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Error Internet connectivity");
      return UserLoginH.withError(
          code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
    }

    String url = Api.baseUrl + ApiEndPoints.resetPassword;
    Map<String, dynamic> loginData = {
      'password': password,
      'confirmpassword': cPassword,
    };

    FormData formData = FormData.fromMap(loginData);

    try {
      final response = await apiUtils.post(url: url, data: formData);
      print("REsponseData $response");
      return UserLoginH.fromJson(response.data);
      /*  if (response.data['code'] == 0) {
        return UserLoginH.fromJson(response.data);
      } else {
        return UserLoginH.withError(
            code: CODE_RESPONSE_NULL, mess: response.data['message']);
      }*/

      //return null;
      return UserLoginH.withError(code: CODE_RESPONSE_NULL, mess: "");
    } catch (e) {
      return UserLoginH.withError(
          code: CODE_ERROR, mess: apiUtils.handleError(e));
    }
  }

  Future<List<Order>> orderGetApi(String bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getOrders;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Order.fromJson(json))
            .toList();
      } else {
        return [
          Order.withError(
            code: response.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        Order.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<List<Order>> orderGetApiFilter(
      String bearer, Map<String, dynamic> data) async
  {
    String url = Api.baseUrl + ApiEndPoints.getOrderFilter;

    try {
      final response = await apiUtils.post(
        url: url,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Order.fromJson(json))
            .toList();
      } else {
        return [
          Order.withError(
            code: response.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        Order.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<StoreDetail> getStoreID(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreDetail;

    try {
      final response = await apiUtils.post(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      final jsonData = response.data;
      return StoreDetail.fromJson(jsonData);
    } catch (e) {
      return StoreDetail.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<List<DailySalesReport>> reportGetApi(String bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getReports;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => DailySalesReport.fromJson(json))
            .toList();
      } else {
        return [
          DailySalesReport.withError(
            code: response.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        DailySalesReport.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<Order> orderAcceptDecline(
      String bearer, Map<String, dynamic> jsonData, int? id) async
  {
    //print("JsonDatsss "+jsonData.toString());

    String url = "${Api.baseUrl}${ApiEndPoints.getOrderStatus}/$id";
    try {
      /*final response = await apiUtils.post(
        url: url,
        data: jsonData ,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );*/
      final response = await Dio().put(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData $url");
      print("First call $response");
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 $redirectedUrl");
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Order.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Order.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error $e");
      return Order.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<Order> getNewOrderData(String bearer, int id) async {
    String url = Api.baseUrl + ApiEndPoints.getOrders + id.toString();
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        print("🚀 API Order Response: ${response.data}");

        return Order.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Order.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Order.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<UserMe> getUserMe(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getUserMe;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return UserMe.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return UserMe.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return UserMe.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<Logout> logoutAPi(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.logoutApi;
    try {
      final response = await apiUtils.post(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Logout.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Logout.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Logout.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<StoreSetting> getStoreSetting(String? bearer, String storeID) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreSetting + storeID;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return StoreSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return StoreSetting.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return StoreSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<StoreSetting> storeSettingPost(String bearer, Map<String, dynamic> jsonData,String storeID) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreSetting + storeID;
    try {
      final response = await Dio().put(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData $url");
      print("First call $response");
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 $redirectedUrl");
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return StoreSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return StoreSetting.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error $e");
      return StoreSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<PrinterSetting> printerSettingPost(
      String bearer, Map<String, dynamic> jsonData) async
  {
    String url = Api.baseUrl + ApiEndPoints.postPrinterSetting;
    try {
      final response = await Dio().post(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData $url");
      print("First call $response");
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 $redirectedUrl");
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return PrinterSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return PrinterSetting.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error $e");
      return PrinterSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<Store> getStoreData(String bearer, String id) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreDetail + id;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Store.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Store.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Store.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }
}

class CallService extends GetConnect {
  //get live reports for today sales
  Future<GetTodayReport> getLiveSaleData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      print("🔑 User Access Token Value is: $accessToken");

      if (accessToken == null || accessToken.isEmpty) {
        print("❌ Access token is null or empty");
        throw Exception("Access token not found");
      }

      httpClient.baseUrl = Api.baseUrl;
      print("🌐 Making API call to: ${Api.baseUrl}/reports/today");

      var res = await get(
        'reports/today',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("📡 API Response Status Code: ${res.statusCode}");
      print("📄 API Response Body: ${res.body}");

      if (res.statusCode == 200) {
        print("✅ Today Report Response Is Success: ${res.statusCode}");

        if (res.body == null || res.body.toString().trim().isEmpty) {
          print("❌ Response body is empty despite 200 status");
          return _createEmptyReport();
        }

        try {
          final parsedResponse = GetTodayReport.fromJson(res.body);
          print("✅ Successfully parsed response");
          return parsedResponse;
        } catch (parseError) {
          print("❌ JSON Parsing Error: $parseError");
          return _createEmptyReport();
        }
      } else if (res.statusCode == 204) {
        // ✅ Handle 204 No Content - this is normal for no data
        print("ℹ️ No Content (204) - No sales data available for today");
        print("ℹ️ This is normal if there are no orders yet today");

        return _createEmptyReport();
      } else if (res.statusCode == 401) {
        print("❌ Unauthorized - Token may be expired");
        throw Exception("Unauthorized: Please login again");
      } else if (res.statusCode == 404) {
        print("❌ API endpoint not found");
        throw Exception("API endpoint not found");
      } else if (res.statusCode == 500) {
        print("❌ Server error");
        throw Exception("Server error: ${res.statusCode}");
      } else {
        print("❌ API call failed with status: ${res.statusCode}");
        print("❌ Response body: ${res.body}");
        throw Exception(
            "API call failed with status ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      print("❌ Exception in getLiveSaleData: $e");

      // ✅ For 204 responses, return empty data instead of throwing error
      if (e.toString().contains('204')) {
        print("ℹ️ Returning empty report for 204 response");
        return _createEmptyReport();
      }

      rethrow;
    }
  }

  GetTodayReport _createEmptyReport() {
    print("📊 Creating empty report with zero values");

    return GetTodayReport(
      totalSales: 0.0,
      totalOrders: 0,
      cashTotal: 0.0,
      onlineTotal: 0.0,
      discountTotal: 0.0,
      deliveryTotal: 0.0,
      totalTax: 0.0,
      netTotal: 0.0,
      totalSalesDelivery: 0.0,
      taxBreakdown: TaxBreakdown(d7: 0.0, d19: 0.0),
      paymentMethods: PaymentMethods(cash: 0),
      orderTypes: OrderTypes(delivery: 0, pickup: 0, dineIn: 0),
      approvalStatuses: ApprovalStatuses(pending: 0, accepted: 0, declined: 0),
      topItems: [],
      byCategory: null,
    );
  }



  //Driver Section

  //1.) Create Driver
  Future<DriverRegisterModel> registerDriver(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    var res = await post(
      'delivery/register-driver/',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Driver Register Response is : ${res.statusCode.toString()}");
      print("Driver Register Response Body  is : ${res.body}");
      return DriverRegisterModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  //For Getting Specific Store Driver
  Future<GetSpecificStoreDeliveryDriverResponseModel> getDeliveryDriver(
      String storeId) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('delivery/drivers/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print(
          "Delivery Driver Details response is :${res.statusCode.toString()}");
      return GetSpecificStoreDeliveryDriverResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  //For getting Order LIst History For Specific Date
  Future<List<orderHistoryResponseModel>> orderHistory(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    var res = await post(
      'orders/store/filter',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );

    print("response is ${res.statusCode}");

    if (res.statusCode == 200) {
      print("order History Response is : ${res.statusCode.toString()}");
      print("Order History Response Body is : ${res.body}");

      // Parse the response body as a list
      List<dynamic> jsonList = res.body;
      List<orderHistoryResponseModel> orders = [];

      for (var json in jsonList) {
        orders.add(orderHistoryResponseModel.fromJson(json));
      }

      return orders;
    } else {
      throw Exception("Failed to load order history");
    }
  }

  //For Print Order Details Without Ip
  Future<printOrderWithoutIp> printWithoutIp(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    var res = await post(
      'orders/printorder',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Print Without Ip Response is : ${res.statusCode.toString()}");
      print("Print Without Ip Response Body  is : ${res.body}");
      return printOrderWithoutIp.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  //For Changing Discount Percentage
  Future<ChangeDiscountPercentageResponseModel> changeDiscount(dynamic body, String id) async
  {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    debugPrint('api call in save discount is ${Api.baseUrl}discounts/$id');
    print("User Access Token Value is : $accessToken");
    var res = await put(
      'discounts/$id',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Discount Change Response is : ${res.statusCode.toString()}");
      print("Discount Change Response Body  is : ${res.body}");
      return ChangeDiscountPercentageResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  // For Getting Discount Percentage
  Future<List<GetDiscountPercentageResponseModel>> getDiscountPercentage(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('discounts/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Discount response is :${res.statusCode.toString()}");

      // Parse the response as a List
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetDiscountPercentageResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load discounts: ${res.statusCode}');
    }
  }

  // For Adding New Store Timing
  Future<AddNewStoreTimingResponseModel> addStoreTiming(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      // Make the API call
      var res = await post(
        'store-hours/store/$storeId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Store response is ${res.statusCode}");
      print("Add Store Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Store Timing Response is : ${res.statusCode.toString()}");
        return AddNewStoreTimingResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID $storeId not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For updating Store hours
  Future<List<update_store_hours_response_model>> updateStoreTiming(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      print("User Access Token Value is : $accessToken");

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'store-hours/store/$storeId/bulk',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("update Store response is ${res.statusCode}");
      print("update Store Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        List<dynamic> data = res.body;

        return data
            .map((e) => update_store_hours_response_model.fromJson(e))
            .toList();
      } else if (res.statusCode == 400) {
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        throw Exception('Store with ID $storeId not found.');
      } else if (res.statusCode == 500) {
        throw Exception('Server error occurred. Please try again later.');
      } else {
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Getting Store Timing
  Future<List<GetStoreTimingResponseModel>> getStoreTiming(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('store-hours/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Store Timing response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetStoreTimingResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Store timing: ${res.statusCode}');
    }
  }

  //For Deleting Store Timing
  Future<bool> deleteStoreTiming(int timingId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "store-hours/$timingId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  // For Getting Taxes OF Store
  Future<List<getAddedtaxResponseModel>> getStoreTax(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('taxes/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Store taxes response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => getAddedtaxResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Store taxes: ${res.statusCode}');
    }
  }

  //For Adding New Tax To store
  Future<AddTaxResponseModel> addStoreTaxes(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'taxes/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Store Tax response is ${res.statusCode}");
      print("Add Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Store Tax Response is : ${res.statusCode.toString()}");
        return AddTaxResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For editing New Tax To store
  Future<editTaxResponseModel> editStoreTaxes(dynamic body, String taxId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'taxes/$taxId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Tax response is ${res.statusCode}");
      print("EDIT Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Store Tax Response is : ${res.statusCode.toString()}");
        return editTaxResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Deleting Store Tax
  Future<bool> deleteStoreTax(int taxId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "taxes/$taxId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else if (res.statusCode == 400) {
        String errorBody = res.body.toString();
        print('Delete API Error: ${res.statusCode} - $errorBody');
        throw Exception('400_ERROR: $errorBody');
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false; // Return false instead of throwing exception for other errors
      }
    } catch (e) {
      if (e.toString().contains('400_ERROR')) {
        rethrow; // Re-throw 400 errors
      }
      print('Delete API Exception: $e');
      return false; // Return false for network/other errors
    }
  }

  //For Getting Product Category List
  Future<List<GetProductCategoryList>> getProductCategory(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('categories/?store_id=$storeId&include_inactive=true',
        headers: {
          'accept': 'application/json',
          //'Authorization': "Bearer $accessToken",
        });

    if (res.statusCode == 200) {
      print(
          "Getting Product Category response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetProductCategoryList.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Product Category: ${res.statusCode}');
    }
  }

  //For adding the new product Category
  Future<AddNewProductCategoryResponseModel> addNewProductCategory(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'categories/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Store Tax response is ${res.statusCode}");
      print("Add Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "Add New Product Category Response is : ${res.statusCode.toString()}");
        return AddNewProductCategoryResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting The Product Categories
  Future<bool> deleteProductCategory(int productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "categories/$productId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        // Throw exception for FK constraint error
        if (res.statusCode == 409 ||
            res.body.toString().contains('FK constraints') ||
            res.body.toString().contains('foreign key constraint')) {
          throw Exception('FK_CONSTRAINT');
        }
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  // For Editing the existing product category
  Future<EditExistingProductCategoryResponseModel> editProductCategory(dynamic body, String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'categories/$productId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Product category response is ${res.statusCode}");
      print("EDIT  Product category Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "EDIT Product category Response is : ${res.statusCode.toString()}");
        return EditExistingProductCategoryResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Getting Reservation Details
  Future<List<GetUserReservationDetailsResponseModel>> getReservationDetailsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    String? storeId = prefs.getString(valueShared_STORE_KEY);
    print("User Access Token Value is : $accessToken");
    print("Store ID for reservation: $storeId");

    httpClient.baseUrl = Api.baseUrl;
    String url = 'reservations/';
    if (storeId != null && storeId.isNotEmpty) {
      url = 'reservations/?store_id=$storeId';
    }
    var res = await get(url, headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    print("API Response Status Code: ${res.statusCode}");
    print("API Response Body: ${res.body}");

    if (res.statusCode == 200) {
      List<GetUserReservationDetailsResponseModel> reservations = [];
      var jsonData = res.body;

      if (jsonData is List) {
        for (var item in jsonData) {
          reservations.add(GetUserReservationDetailsResponseModel.fromJson(item));
        }
      } else if (jsonData is Map<String, dynamic>) {
        // Single object response
        reservations.add(GetUserReservationDetailsResponseModel.fromJson(jsonData));
      }
      return reservations;
    } else {

      print("Failed to load reservation details. Status code: ${res.statusCode}");
      throw Exception(
          "Failed to load reservation details. Status code: ${res.statusCode}");
    }
  }

  // For Getting New Reservation
  Future<GetUserReservationDetailsResponseModel> getNewReservationData(String bearer, int id) async {
    String url = Api.baseUrl + ApiEndPoints.getReservation + id.toString();
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        print("🚀 API Order Response: ${response.data}");

        return GetUserReservationDetailsResponseModel.fromJson(
            jsonData); // ✅ Parse single order object
      } else {
        return GetUserReservationDetailsResponseModel.withError(
          code: response.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return GetUserReservationDetailsResponseModel.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  //for accepting and declining the reservation
  Future<GetOrderStatusResponseModel> acceptDeclineReservation(dynamic body, String reservationId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put(
        'reservations/$reservationId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Reservation response is ${res.statusCode}");
      print("Reservation response is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Reservation Response is : ${res.statusCode.toString()}");
        return GetOrderStatusResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Status error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Reservation table Full details
  Future<GetOrderDetailsResponseModel> getReservationFullDetails(String reservationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reservations/$reservationId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Reservation Details response is :${res.statusCode.toString()}");
      return GetOrderDetailsResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  // for Getting reservation History
  Future<List<GetHistoryReservationResponseModel>> reservationHistory(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    var res = await post(
      'reservations/store/filter',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );

    print("response is ${res.statusCode}");

    if (res.statusCode == 200) {
      print("order History Response is : ${res.statusCode.toString()}");
      print("Order History Response Body is : ${res.body}");

      // Parse the response body as a list
      List<dynamic> jsonList = res.body;
      List<GetHistoryReservationResponseModel> reservation = [];

      for (var json in jsonList) {
        reservation.add(GetHistoryReservationResponseModel.fromJson(json));
      }

      return reservation;
    } else {
      throw Exception("Failed to load order history");
    }
  }

  //For Editing reservation details
  Future<EditReservationDetailsResponseModel> editReservationDetails(dynamic body, String reservationId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'reservations/$reservationId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Tax response is ${res.statusCode}");
      print("EDIT Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Reservation Response is : ${res.statusCode.toString()}");
        return EditReservationDetailsResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Adding New Reservation
  Future<AddNewReservationResponseModel> addReservation(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'reservations/guest',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Reservation response is ${res.statusCode}");
      print("Add Reservation Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Reservation Response is : ${res.statusCode.toString()}");
        return AddNewReservationResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Getting products Of Specific Store
  Future<List<GetStoreProducts>> getProducts(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    debugPrint('product url is ${Api.baseUrl}products/?store_id=$storeId');
    var res = await get('products/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Product of Store response is :${res.statusCode.toString()}");
      print("Product body of Store response is :${res.body}");
      debugPrint(
        const JsonEncoder.withIndent('  ').convert(res.body),
        wrapWidth: 1024,
      );
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetStoreProducts.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Product of Store: ${res.statusCode}');
    }
  }

  Future<List<GetStoreProducts>> getProductsbylimit(
      String storeId, int limit, int offset) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get(
        'products/limit/$limit?offset=$offset&store_id=$storeId',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $accessToken",
        });

    if (res.statusCode == 200) {
      print(
          "Getting Product of Store response is :${res.statusCode.toString()}");
      print("Product body of Store response is :${res.body}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetStoreProducts.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Product of Store: ${res.statusCode}');
    }
  }

  //For Add New Products
  Future<AddNewProductResponseModel> addNewProduct(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'products/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Product response is ${res.statusCode}");
      print("Add Product Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Product Response is : ${res.statusCode.toString()}");
        return AddNewProductResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing the Existing Products
  Future<EditStoreProductResponseModel> editProducts(dynamic body, String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'products/$productId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Product response is ${res.statusCode}");
      print("EDIT Store Product Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Product Response is : ${res.statusCode.toString()}");
        return EditStoreProductResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Product
  Future<bool> deleteProduct(int productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "products/$productId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Toppings
  Future<List<GetToppingsResponseModel>> getToppings(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/?store_id=$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Toppings of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetToppingsResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Toppings of Store: ${res.statusCode}');
    }
  }

  //For Add New Toppings
  Future<AddNewStoreToppingsResponseModel> addNewToppings(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Toppings response is ${res.statusCode}");
      print("Add Toppings Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Toppings Response is : ${res.statusCode.toString()}");
        return AddNewStoreToppingsResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing Existing Toppings
  Future<EditStoreToppingsResponseModel> editToppings(dynamic body, String toppingsId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/$toppingsId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Toppings response is ${res.statusCode}");
      print("EDIT Store Toppings Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Toppings Response is : ${res.statusCode.toString()}");
        return EditStoreToppingsResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Toppings
  Future<bool> deleteToppings(String toppingId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "toppings/$toppingId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Postcode
  Future<List<GetStorePostCodesResponseModel>> getPostCode(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('postcodes/store/$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Postcode of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetStorePostCodesResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Postcode of Store: ${res.statusCode}');
    }
  }

  //For Add New PostCode
  Future<List<AddStorePostCodesResponseModel>> addNewPostcode(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }
      var res = await post(
        'postcodes/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("Add PostCode response is ${res.statusCode}");
      print("Add PostCode Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add PostCode Response is : ${res.statusCode.toString()}");
        List<dynamic> jsonList = res.body;
        return jsonList
            .map((json) => AddStorePostCodesResponseModel.fromJson(json))
            .toList();
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing PostCode
  Future<List<EditStorePostCodesResponseModel>> editPostcode(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'postcodes/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store PostCode response is ${res.statusCode}");
      print("EDIT Store Postcode Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT PostCode Response is : ${res.statusCode.toString()}");
        List<dynamic> jsonList = res.body;
        return jsonList
            .map((json) => EditStorePostCodesResponseModel.fromJson(json))
            .toList();
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting PostCode
  Future<bool> deletePostCode(int postcodeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "postcodes/$postcodeId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Toppings Group
  Future<List<GetToppingsGroupResponseModel>> getToppingGroups(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/groups?store_id=$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Toppings of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetToppingsGroupResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Toppings of Store: ${res.statusCode}');
    }
  }

  //For Add New Topping Group
  Future<AddToppingsGroupResponseModel> addToppingGroup(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/groups',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Topping Group response is ${res.statusCode}");
      print("Add Topping Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Topping Group Response is : ${res.statusCode.toString()}");
        return AddToppingsGroupResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Editing Topping Group
  Future<EditToppingsGroupResponseModel> editToppingGroup(dynamic body, String groupId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/groups/$groupId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Topping Group response is ${res.statusCode}");
      print("EDIT Store Topping Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Topping Group Response is : ${res.statusCode.toString()}");
        return EditToppingsGroupResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Delete Topping Group
  Future<bool> deleteToppingGroup(String groupId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "toppings/groups/$groupId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  // For Getting Group Items
  Future<List<GetGroupItemResponseModel>> getGroupItems(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/group-items?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Getting Group items response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetGroupItemResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Group items : ${res.statusCode}');
    }
  }

  //For Add New Group Item
  Future<AddGroupItemResponseModel> addGroupItem(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/group-items',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  Group Item response is ${res.statusCode}");
      print("Add  Group Item Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  Group Item Response is : ${res.statusCode.toString()}");
        return AddGroupItemResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Edit Group Items
  Future<EditGroupItemResponseModel> editGroupItem(dynamic body, String groupItemId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/group-items/$groupItemId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Group Item response is ${res.statusCode}");
      print("EDIT Group Item Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Group Item Response is : ${res.statusCode.toString()}");
        return EditGroupItemResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Deleting the group item
  Future<bool> deleteGroupItem(String groupItemId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete(
        "toppings/group-items/$groupItemId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Product Groups
  Future<List<GetProductGroupResponseModel>> getProductGroup(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/product-groups?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Getting Product Group response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetProductGroupResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Product Group : ${res.statusCode}');
    }
  }

  //For Add New Product Group
  Future<AddNewProductGroupResponseModel> addProductGroup(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/product-groups',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  ProductGroup response is ${res.statusCode}");
      print("Add  ProductGroup Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  ProductGroup Response is : ${res.statusCode.toString()}");
        return AddNewProductGroupResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing Product Group
  Future<EditProductGroupResponseModel> editProductGroup(dynamic body, String productGroupId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/product-groups/$productGroupId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Product Group response is ${res.statusCode}");
      print("EDIT Product Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Product Group Response is : ${res.statusCode.toString()}");
        return EditProductGroupResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Delete Product Group
  Future<bool> deleteProductGroup(String productGroupId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "toppings/product-groups/$productGroupId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete Product Group Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Product Group deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  // For Getting Allergy
  Future<List<GetAllergyResponseModel>> getAllergy(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('allergy-items/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Getting Allergy response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetAllergyResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Allergy : ${res.statusCode}');
    }
  }

  //For Add Allergy
  Future<AddAllergyResponseModel> addAllergy(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'allergy-items/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  Allergy response is ${res.statusCode}");
      print("Add  Allergy Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  Allergy Response is : ${res.statusCode.toString()}");
        return AddAllergyResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing allergy
  Future<EditAllergyResponseModel> editAllergy(dynamic body, String allergyId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'allergy-items/$allergyId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Allergy response is ${res.statusCode}");
      print("EDIT Allergy Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Allergy Response is : ${res.statusCode.toString()}");
        return EditAllergyResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Delete Allergy
  Future<bool> deleteAllergy(String allergyId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "allergy-items/$allergyId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete allergy Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("allergy deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  // For Getting Item Allergy Link
  Future<List<get_item_allergy_link_response_model>> getAllergyItemLink(String storeId,) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get(
        'allergies_link/store/$storeId/allergy-product?include_unlinked=false&limit=500&offset=0',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    if (res.statusCode == 200) {
      print(
          "Getting Allergy Item Link response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => get_item_allergy_link_response_model.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Allergy item link : ${res.statusCode}');
    }
  }

  // For Add New Allergy Item Link
  Future<AddAllergyLinkResponseModel> addAllergyItemLink(dynamic body, String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'allergies_link/$productId/allergy-items',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  Allergy Item Link Response response is ${res.statusCode}");
      print("Add  Allergy Item Link Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "Add Allergy Item Link Response is : ${res.statusCode.toString()}");
        return AddAllergyLinkResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing allergy
  Future<EditAllergyLinkResponseModel> editAllergyItemLink(dynamic body, String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'allergies_link/$productId/allergy-items',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Allergy Item Link response is ${res.statusCode}");
      print("EDIT Allergy Item Link Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "EDIT Allergy Item Link Response is : ${res.statusCode.toString()}");
        return EditAllergyLinkResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Allergy Link Item
  Future<bool> deleteAllergyLink(String productId, String allergyId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "allergies_link/$productId/allergy-items/$allergyId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete allergy Link Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("allergy Link deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  // For Compressing image Quality
  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
        dir.path, "${DateTime.now().millisecondsSinceEpoch}_compressed.jpg");

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result != null ? File(result.path) : file;
  }

  //For Uploading imaGE
  Future<image_upload_response_model> uploadImage(File imageFile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }
      httpClient.baseUrl = Api.baseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}images/upload'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['accept'] = 'application/json';

      // Add file
      File compressedImage = await compressImage(imageFile);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          compressedImage.path,
          contentType: MediaType('image', 'jpeg'), // Add explicit content type
        ),
      );

      print("Uploading file: ${imageFile.path}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload Image Response: ${response.statusCode}");
      print("Upload Image Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return image_upload_response_model.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Image upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print("Image upload error: $e");
      rethrow;
    }
  }

  // For Getting Category Availability
  Future<List<GetCategoryAvailabilityResponseModel>> getCategoryAvailability(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('categories/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Category Availability response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetCategoryAvailabilityResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to load Category Availability: ${res.statusCode}');
    }
  }

  // For Add Category Availability
  Future<AddNewCategoryAvailabilityResponseModel> addCategoryAvailability(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'categories-availability/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print(
          "Add  Category Availability Response response is ${res.statusCode}");
      print("Add  CategoryAvailability  Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "Add CategoryAvailability Response is : ${res.statusCode.toString()}");
        return AddNewCategoryAvailabilityResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing Category Availability
  Future<EditCategoryAvailabilityResponseModel> editCategoryAvailability(dynamic body, String availabilityId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'categories-availability/$availabilityId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT CategoryAvailability response is ${res.statusCode}");
      print("EDIT CategoryAvailability( Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "EDIT CategoryAvailability  Response is : ${res.statusCode.toString()}");
        return EditCategoryAvailabilityResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Category Availability
  Future<bool> deleteCategoryAvailability(String availabilityId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "categories-availability/$availabilityId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print(
          "Delete categories-availability Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("categories-availability deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Getting Ip Address
  Future<List<GetPrinterIpResponseModel>> getIpAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('printers/', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Printer Ip response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetPrinterIpResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load  Printer Ip: ${res.statusCode}');
    }
  }

  //For Add New Ip Address
  Future<AddPrinterIpResponseModel> addNewIp(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'printers/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  New IP Response response is ${res.statusCode}");
      print("Add   New IP  Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  New IP Response is : ${res.statusCode.toString()}");
        return AddPrinterIpResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //for Editing Ip Address
  Future<EditIpAddressResponseModel> editIpAddress(dynamic body, String printerId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'printers/$printerId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Ip Address response is ${res.statusCode}");
      print("EDIT  Ip Address  Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT  Ip Address  Response is : ${res.statusCode.toString()}");
        return EditIpAddressResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Ip Address
  Future<bool> deleteExistingIp(String printerId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "printers/$printerId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete Printer Ip Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("categories-availability deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Get All Store
  Future<List<GetAllStoreResponseModel>> getAllStore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('stores/', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting All Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetAllStoreResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load All Store : ${res.statusCode}');
    }
  }

  //For Get All Admin Order
  Future<List<AllOrderAdminResponseModel>> getAllAdminOrder({
    int limit = 20,
    int offset = 0,
    String? startDate,
    String? endDate,
    bool includePast = false,}) async
  {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? Token = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $Token");
      print("Fetching orders with limit=$limit, offset=$offset");

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final sd = startDate ?? today;
      final ed = endDate ?? today;

      httpClient.baseUrl = Api.baseUrl;
      httpClient.timeout = const Duration(seconds: 30);
      print('Api Calling Url is ${Api.baseUrl}orders/admin/list?limit=$limit&offset=$offset&include_past=$includePast&start_date=$sd&end_date=$ed');
      var res =
          await get('orders/admin/list?limit=$limit&offset=$offset&include_past=$includePast&start_date=$sd&end_date=$ed', headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $Token",
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print("Response status code: ${res.statusCode}");
      print("Response body type: ${res.body.runtimeType}");

      if (res.statusCode == null) {
        throw Exception('No response from server');
      }

      if (res.statusCode == 200) {
        print(
            "Getting All Admin Order response is :${res.statusCode.toString()}");

        if (res.body == null) {
          print("Response body is null");
          return [];
        }

        List<dynamic> jsonList = res.body is List ? res.body : [];
        print("Fetched ${jsonList.length} orders");

        if (jsonList.isEmpty) {
          return [];
        }

        return jsonList.map((json) {
          try {
            return AllOrderAdminResponseModel.fromJson(json);
          } catch (e) {
            print("Error parsing order: $e");
            print("JSON: $json");
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load All Admin Order : ${res.statusCode}');
      }
    } catch (e) {
      print("API Error: $e");
      rethrow;
    }
  }

  //For Get Admin Report
  Future<GetAdminReportResponseModel> getAdminReport(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reports/admin/today?store_ids=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Admin Report response is :${res.statusCode.toString()}");
      return GetAdminReportResponseModel.fromJson(res.body);
    } else {
      throw Exception('Failed to load Admin Report : ${res.statusCode}');
    }
  }

  //For get daily admin report
  Future<List<DailySalesReport>> reportGetApiAdmin(String bearer, String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reports/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Admin Daily Report For Calender is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => DailySalesReport.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load All Store : ${res.statusCode}');
    }
  }

  //For Get Admin Report
  Future<GetAdminReportResponseModel> getAdminReportAllStore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reports/admin/today', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Admin Report response is :${res.statusCode.toString()}");
      return GetAdminReportResponseModel.fromJson(res.body);
    } else {
      throw Exception('Failed to load Admin Report : ${res.statusCode}');
    }
  }

  //For Sync Order
  Future<SyncLocalOrder> syncLocalOrder(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      print("🔑 User Access Token: $accessToken");
      print("📦 Request Body Type: ${body.runtimeType}");

      String prettyJson = const JsonEncoder.withIndent('  ').convert(body);
      print("📦 FULL Request Body:\n$prettyJson");

      var res = await post(
        'sync/orders',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("📡 Sync Order Response Status: ${res.statusCode}");
      print("📡 Sync Order Response Body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return SyncLocalOrder.fromJson(res.body);
      } else {
        print("❌ Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception(
            'Request failed with status code: ${res.statusCode}. Response: ${res.body}');
      }
    } catch (e) {
      print("❌ Syncing error: $e");
      rethrow;
    }
  }

  //For Getting the Coupons
  Future<List<GetCouponsResponseModel>> getCoupons(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('coupons/$storeId?include_inactive=true', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Coupons response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetCouponsResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Coupons: ${res.statusCode}');
    }
  }

  //For Add New Coupon
  Future<AddCouponResponseModel> addNewCoupon(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'coupons/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add  New Coupons is ${res.statusCode}");
      print("Add   New Coupons Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  New Coupons is : ${res.statusCode.toString()}");
        return AddCouponResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Delete Coupon
  Future<bool> deleteExistingCoupon(String couponId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "coupons/$couponId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete Coupon Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Coupon deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Reactivate Coupon
  Future<bool> activateCoupon(String couponId, dynamic body) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await patch(
        "coupons/$couponId/activate",
        body,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Activate Coupon Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Coupon Activate successfully");
        return true;
      } else {
        print('activate API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('activate API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("activate successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Getting Holiday
  Future<List<GetHolidayResponseModel>> getHolidays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('holidays/', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Holidays response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetHolidayResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Holidays: ${res.statusCode}');
    }
  }

  //For Creating New Holiday
  Future<CreateHolidayResponseModel> addNewHoliday(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await post(
        'holidays/',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  New Holiday Response is : ${res.statusCode.toString()}");
        return CreateHolidayResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Updating Holiday
  Future<UpdateHolidayResponseModel> editHoliday(dynamic body, String holidayId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put(
        'holidays/$holidayId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("EDIT Holiday Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT  Holiday Response is : ${res.statusCode.toString()}");
        return UpdateHolidayResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For delete holiday
  Future<bool> deleteHoliday(String holidayId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "holidays/$holidayId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("Delete Coupon Status: ${res.statusCode}");
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Coupon deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For manual override store open close
  Future<ManualOverrideResponseModel> addManualOverride(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await patch(
        'stores/$storeId/manual-override',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("override Store Response is : ${res.statusCode.toString()}");
        return ManualOverrideResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Getting Device Status
  Future<DeviceStatusResponseModel> getDeviceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('devices/status', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting device Status response is :${res.statusCode.toString()}");
      print("Getting device Status response body is :${res.body}");
      return DeviceStatusResponseModel.fromJson(res.body);
    } else {
      throw Exception('Failed to load device status : ${res.statusCode}');
    }
  }

  Future<GetSpecificStoreDeviceStatus> getDeviceStatusSpecificStore(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('devices/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Specific Store device Status response is :${res.statusCode.toString()}");
      print(
          "Getting Specific Store device Status response body is :${res.body}");
      return GetSpecificStoreDeviceStatus.fromJson(res.body);
    } else {
      throw Exception('Failed to load device status : ${res.statusCode}');
    }
  }

  //For Get Delivery Times of Store
  Future<List<GetDeliveryTimeStore>> getDeliveryTime(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('time-plans/delivery/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Delivery Time response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetDeliveryTimeStore.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Delivery Times : ${res.statusCode}');
    }
  }

  //For Get Collection Times of Store
  Future<List<GetCollectionTimeStore>> getCollectionTime(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('time-plans/collection/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Collection Time response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetCollectionTimeStore.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Collection Times : ${res.statusCode}');
    }
  }

  //For Adding Delivery Time
  Future<AddDeliveryTimeStore> addDeliveryTime(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res =
          await post('time-plans/delivery/store/$storeId/bulk', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Delivery time Response is : ${res.statusCode.toString()}");

        // API returns a list, extract the first item
        if (res.body is List && (res.body as List).isNotEmpty) {
          return AddDeliveryTimeStore.fromJson((res.body as List)[0]);
        } else {
          throw Exception('Empty or invalid response from server');
        }
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Adding Collection Time
  Future<AddCollectionTimeStore> addCollectionTime(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await post('time-plans/collection/store/$storeId/bulk', body,
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Collection Time Response is : ${res.statusCode.toString()}");

        // API returns a list, extract the first item
        if (res.body is List && (res.body as List).isNotEmpty) {
          return AddCollectionTimeStore.fromJson((res.body as List)[0]);
        } else {
          throw Exception('Empty or invalid response from server');
        }
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Updating Collection time
  Future<EditCollectionTimeStore> editCollectionTime(dynamic body, String collectionId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put(
        'time-plans/collection/$collectionId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("EDIT Collection time Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(
            "EDIT Collection time Response is : ${res.statusCode.toString()}");
        return EditCollectionTimeStore.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Updating Delivery Time
  Future<EditDeliveryTimeStore> editDeliveryTime(dynamic body, String deliveryId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put(
        'time-plans/delivery/$deliveryId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("EDIT delivery time Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT delivery time Response is : ${res.statusCode.toString()}");
        return EditDeliveryTimeStore.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //for delete delivery time
  Future<bool> deleteDeliveryTime(String deliveryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "time-plans/delivery/$deliveryId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("Delete Delivery time Status: ${res.statusCode}");
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Delivery time deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For delete collection time
  Future<bool> deleteCollectionTime(String collectionId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "time-plans/collection/$collectionId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("Delete Collection time Status: ${res.statusCode}");
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Collection time deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Getting Store Customer
  Future<GetStoreCustomerResponseModel> getStoreCustomer(int limit, int offset) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('customers/?limit=$limit&offset=$offset', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Store Customer response is :${res.statusCode.toString()}");
      print("Getting Store Customer response body is :${res.body}");
      return GetStoreCustomerResponseModel.fromJson(res.body);
    } else {
      throw Exception('Failed to load device status : ${res.statusCode}');
    }
  }

  //Gor getting Customer details
  Future<CustomerDetailsResponseModel> getCustomerDetails(int customerId, int ordersLimit, int reservationsLimit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get(
        'customers/$customerId?orders_limit=$ordersLimit&reservations_limit=$reservationsLimit',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $Token",
        });

    if (res.statusCode == 200) {
      print(
          "Getting Customer details response is :${res.statusCode.toString()}");
      print("Getting Customer details response body is :${res.body}");
      return CustomerDetailsResponseModel.fromJson(res.body);
    } else {
      throw Exception('Failed to load customer details: ${res.statusCode}');
    }
  }

  //Get Customer order Details
  Future<GetCustomerOrderDetails> getCustomerOrderDetails(String orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('orders/$orderId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print(
          "Getting Customer Order details response is :${res.statusCode.toString()}");
      print("Getting Customer Order details response body is :${res.body}");
      return GetCustomerOrderDetails.fromJson(res.body);
    } else {
      throw Exception(
          'Failed to load customer Order details: ${res.statusCode}');
    }
  }

  //Get Search products
  Future<List<GetSearchProductResponseModel>> getSearchProducts(String query, String storeId, int limit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get(
        'search/products?q=$query&store_id=$storeId&limit=$limit',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $accessToken",
        });

    if (res.statusCode == 200) {
      print("Getting Search product response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList
          .map((json) => GetSearchProductResponseModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load Search product : ${res.statusCode}');
    }
  }

  //For Add Delivery Zone
  Future<AddDeliveryZoneResponseModel> addDeliveryZone(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await post('delivery-zones/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Delivery Zone Response is : ${res.statusCode.toString()}");

        if (res.body == null || res.body.toString().isEmpty) {
          // 201 with empty body = success, return empty model
          return AddDeliveryZoneResponseModel();
        } else if (res.body is List) {
          final list = res.body as List;
          if (list.isNotEmpty) {
            return AddDeliveryZoneResponseModel.fromJson(list[0]);
          }
          return AddDeliveryZoneResponseModel();
        } else if (res.body is Map) {
          return AddDeliveryZoneResponseModel.fromJson(res.body);
        } else {
          return AddDeliveryZoneResponseModel();
        }
      }else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For getting Delivery Zone
  Future<List<GetDeliveryZoneResponseModel>> getDeliveryZone(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('delivery-zones/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting delivery Zone response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetDeliveryZoneResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load delivery Zone : ${res.statusCode}');
    }
  }

  //For Edit Delivery Zone
  Future<UpdateDeliveryZoneResponseModel> updateDeliveryZone(dynamic body,String deliveryZoneId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put('delivery-zones/$deliveryZoneId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Edit Delivery Zone Response is : ${res.statusCode.toString()}");

        if (res.body == null || res.body.toString().isEmpty) {
          // 201 with empty body = success, return empty model
          return UpdateDeliveryZoneResponseModel();
        } else if (res.body is List) {
          final list = res.body as List;
          if (list.isNotEmpty) {
            return UpdateDeliveryZoneResponseModel.fromJson(list[0]);
          }
          return UpdateDeliveryZoneResponseModel();
        } else if (res.body is Map) {
          return UpdateDeliveryZoneResponseModel.fromJson(res.body);
        } else {
          return UpdateDeliveryZoneResponseModel();
        }
      }else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Editing error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Delete Delivery Zone
  Future<bool> deleteDeliveryZone(String deliveryZoneId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "delivery-zones/$deliveryZoneId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      print("Delete Delivery Zone  Status: ${res.statusCode}");
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Collection time deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

  //For Getting Today Receive Booking
  Future<List<TodayReceivedBookingResponseModel>> todayReceivedBooking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    String? storeId = prefs.getString(valueShared_STORE_KEY);
    print("User Access Token Value is : $accessToken");
    print("Store ID for today received booking: $storeId");

    httpClient.baseUrl = Api.baseUrl;
    String url = 'reservations/store/today';
    if (storeId != null && storeId.isNotEmpty) {
      url = 'reservations/store/today?store_id=$storeId';
    }
    var res = await get(url, headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting today Received Booking response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => TodayReceivedBookingResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to today Received Booking : ${res.statusCode}');
    }
  }

  //For Changing Store Password
  Future<ChangePasswordModel> changePassword(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      var res = await post(
        ApiEndPoints.changePassword,
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("Change Password Response: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ChangePasswordModel();
      } else {
        throw Exception('Server error: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print("Change Password error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Getting All Store Reservation For Store
  Future<GetAllReservationForAllStoreInSuperAdmin> getAllReservationForStore(String date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('superadmin/reservations/count?date=$date', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Reservation For Admin response is :${res.statusCode.toString()}");
      print("Getting Reservation For Admin response body is :${res.body}");
      return GetAllReservationForAllStoreInSuperAdmin.fromJson(res.body);
    } else {
      throw Exception(
          'Failed to load Reservation For Admin: ${res.statusCode}');
    }
  }

  //For Resetting Store password by SuperAdmin
  Future<ResetStorePasswordBySuperAdminModel> resetPassword(dynamic body,String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      var res = await post('superadmin/stores/$storeId/reset-owner-password',
        body, headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("Reset Password Response: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ResetStorePasswordBySuperAdminModel();
      } else {
        throw Exception('Server error: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print("Reset Password error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Getting StoreOwners Stores
  Future<List<StoreOwnersStoreResponseModel>> getStoreOwnersStores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    print("🔵 API URL: ${Api.baseUrl}stores/my-stores");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('stores/my-stores', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting StoreOwners Store response is :${res.statusCode.toString()}");
      print("Getting StoreOwners Store response body is :${res.body}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => StoreOwnersStoreResponseModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load  StoreOwners Store: ${res.statusCode}');
    }
  }

  //For getting Store Owners Report
  Future<GetAdminReportResponseModel> getStoreOwnersReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reports/today', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Store Owner Report response is :${res.statusCode.toString()}");
      print("Getting Store Owner Report response body is :${res.body}");
      return GetAdminReportResponseModel.fromJson(res.body);
    } else {
      throw Exception(
          'Failed to load Getting Store Owner Report: ${res.statusCode}');
    }
  }

  //For getting Windows Device Status
  Future<WindowsDeviceStatus> getWindowsDeviceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('stores/online/windows/all', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print(" Windows Device Status response is :${res.statusCode.toString()}");
      print(" Windows Device Status  response body is :${res.body}");
      return WindowsDeviceStatus.fromJson(res.body);
    } else {
      throw Exception(
          'Failed to load  Windows Device Status : ${res.statusCode}');
    }
  }

  //For Logout Store By SuperAdmin
  Future<LogoutStoreBySuperAdmin> logOutStoreBySuperAdmin(dynamic body,String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      var res = await post('logout/store/$storeId',
        body, headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("Logout Store Response: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return LogoutStoreBySuperAdmin();
      } else {
        throw Exception('Server error: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print("Logout Store error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Windows Notification History
  Future<GetWindowsNotificationHistory> getWindowsNotificationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? Token = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $Token");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('stores/windows/history/all', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $Token",
    });

    if (res.statusCode == 200) {
      print("Getting Windows Notification History response is :${res.statusCode.toString()}");
      print("Getting  Windows Notification History response body is :${res.body}");
      return GetWindowsNotificationHistory.fromJson(res.body);
    } else {
      throw Exception(
          'Failed to load Getting  Windows Notification History: ${res.statusCode}');
    }
  }

  //For Generate Report
  Future<List<int>> generateReport({required String fromDate, required String toDate,
    required int storeId, String language = 'De',}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Access token not found");
    }

    final uri = Uri.parse(
        '${Api.baseUrl}reports/pdf?from_date=$fromDate&to_date=$toDate&language=$language&store_id=$storeId');

    final response = await http.get(uri, headers: {
      'accept': 'application/pdf',
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate report: ${response.statusCode}');
    }
  }
}
