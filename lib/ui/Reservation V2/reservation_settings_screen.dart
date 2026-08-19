import 'package:flutter/material.dart';

class ReservationSettingsScreen extends StatelessWidget {
  final bool reservationsOn;
  final int maxCovers;
  final int slotIntervalMin;
  final int defaultDurationMin;
  final int maxPartySize;
  final int leadTimeMin;
  final int bookingWindowDays;

  const ReservationSettingsScreen({
    super.key,
    required this.reservationsOn,
    required this.maxCovers,
    required this.slotIntervalMin,
    required this.defaultDurationMin,
    required this.maxPartySize,
    required this.leadTimeMin,
    required this.bookingWindowDays,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem('Reservations', reservationsOn ? 'ON' : 'OFF',
          valueColor: reservationsOn ? const Color(0xFF16A34A) : Colors.red),
      _SettingItem('Max Covers', '$maxCovers'),
      _SettingItem('Slot Interval', '$slotIntervalMin min'),
      _SettingItem('Default Duration', '$defaultDurationMin min'),
      _SettingItem('Max Party Size', '$maxPartySize'),
      _SettingItem('Lead Time', '$leadTimeMin min'),
      _SettingItem('Booking Window', '$bookingWindowDays days'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Reservation Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Reservation Settings',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, i) => _settingTile(items[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(_SettingItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(item.value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: item.valueColor ?? Colors.black87)),
        ],
      ),
    );
  }
}

class _SettingItem {
  final String label;
  final String value;
  final Color? valueColor;
  _SettingItem(this.label, this.value, {this.valueColor});
}
