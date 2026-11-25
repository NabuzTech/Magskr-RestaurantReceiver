import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constant.dart';
import '../SuperAdmin/Admin Home/delete_order.dart';

/// Today's orders only; swipe left to delete. No history, no auto refresh.
class TodayOrdersScreen extends StatelessWidget {
  const TodayOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final storeId = int.tryParse(snap.data!.getString(valueShared_STORE_KEY) ?? '') ?? 0;
        return DeleteOrder(storeId: storeId, storeName: 'Orders', todayOnly: true);
      },
    );
  }
}
