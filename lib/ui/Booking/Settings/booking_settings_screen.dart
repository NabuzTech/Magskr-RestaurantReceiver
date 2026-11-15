import 'package:flutter/material.dart';

import '../../../constants/common_colors.dart';
import 'resource_screen.dart';
import 'service_screen.dart';
import 'settings_header.dart';
import 'store_config_screen.dart';
import 'time_management_screen.dart';

/// Booking settings menu: Store Settings / Services / Resources / Time Management.
class BookingSettingsScreen extends StatelessWidget {
  const BookingSettingsScreen({super.key});

  static const Color primaryBlue = CommonColors.darkBlue;
  static const Color veryLightBlue = CommonColors.skyBlue;

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, Widget screen) => ListTile(
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: veryLightBlue, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: primaryBlue, size: 18),
          ),
          title: Text(title,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: Color(0xFF263238))),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Booking Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: Colors.lightBlue),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          tile(Icons.settings_outlined, 'Store Settings', const StoreConfigScreen()),
                          const Divider(height: 1, indent: 62),
                          tile(Icons.room_service_outlined, 'Services', const ServiceScreen()),
                          const Divider(height: 1, indent: 62),
                          tile(Icons.folder_copy_outlined, 'Resources', const ResourceScreen()),
                          const Divider(height: 1, indent: 62),
                          tile(Icons.schedule_outlined, 'Time Management', const TimeManagementScreen()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
