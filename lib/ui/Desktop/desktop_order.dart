import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DesktopOrderScreen extends StatefulWidget {
  const DesktopOrderScreen({super.key});

  @override
  State<DesktopOrderScreen> createState() => _DesktopOrderScreenState();
}

class _DesktopOrderScreenState extends State<DesktopOrderScreen> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.visibility;
      case 2:
        return Icons.check;
      case 3:
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return "Pending";
      case 2:
        return "Accepted";
      case 3:
        return "Declined";
      default:
        return "Unknown";
    }
  }

  Color getContainerColor(int? status) {
    switch (status) {
      case 2:
        return const Color(0xffEBFFF4);
      case 3:
        return const Color(0xffFFEFEF);
      case 1:
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Color getBorderColor(int? status) {
    switch (status) {
      case 2:
        return const Color(0xffC3F2D9);
      case 3:
        return const Color(0xffFFD0D0);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  String _extractTime(String deliveryTime) {
    try {
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildStatusBar(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildOrdersGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM, y').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'Total Orders: 12',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh, size: 28),
              onPressed: () {},
              tooltip: 'Refresh Orders',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusChip('Accepted', '5', Colors.green.withOpacity(0.1)),
          const SizedBox(width: 12),
          _buildStatusChip('Declined', '2', Colors.red.withOpacity(0.1)),
          const SizedBox(width: 12),
          _buildStatusChip('Pickup', '4', Colors.blue.withOpacity(0.1)),
          const SizedBox(width: 12),
          _buildStatusChip('Delivery', '8', Colors.purple.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String count, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOrdersGrid() {
    final orders = List.generate(8, (index) => _generateMockOrder(index));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on available width
        int crossAxisCount = 2;

        if (constraints.maxWidth < 900) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth >= 1400) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.5,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index]);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as int;
    final isPending = status == 1;
    final orderType = order['type'] as String;

    DateTime dateTime = DateTime.parse(order['created_at']);
    String time = DateFormat('hh:mm a').format(dateTime);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: isPending ? _opacityAnimation.value : 1.0,
          child: InkWell(
            onTap: () {
              // Navigate to order details
            },
            borderRadius: BorderRadius.circular(7),
            child: Container(
              decoration: BoxDecoration(
                color: getContainerColor(status),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: getBorderColor(status),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Icon, Address/Location, Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.green,
                                child: Icon(
                                  orderType == 'Delivery'
                                      ? Icons.local_shipping
                                      : Icons.shopping_bag,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['address'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        fontFamily: "Mulish-Regular",
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (orderType == 'Delivery')
                                      Text(
                                        order['full_address'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontFamily: "Mulish",
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: "Mulish",
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Second Row: Customer Name/Phone and Order Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${order['customer']} / ${order['phone']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: "Mulish",
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #: ${order['order_number']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            fontFamily: "Mulish",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Third Row: Amount and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order['amount'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: "Mulish",
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              getApprovalStatusText(status),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontFamily: "Mulish-Regular",
                                fontSize: 13,
                                color: getStatusColor(status),
                              ),
                            ),
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: getStatusColor(status),
                              child: Icon(
                                getStatusIcon(status),
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _generateMockOrder(int index) {
    final statuses = [1, 2, 3, 2, 1, 3, 2, 1];
    final types = ['Delivery', 'Pickup', 'Delivery', 'Pickup', 'Delivery', 'Pickup', 'Delivery', 'Pickup'];

    return {
      'type': types[index % types.length],
      'address': types[index % types.length] == 'Delivery' ? '12345' : 'Pickup',
      'full_address': '123 Main St, New York, NY 10001',
      'customer': 'John Doe',
      'phone': '+1 234-567-8900',
      'order_number': '#ORD${1001 + index}',
      'created_at': DateTime.now().subtract(Duration(minutes: index * 10)).toIso8601String(),
      'time': '10:${30 + index}0 AM',
      'amount': '€${25.50 + (index * 5)}',
      'status': statuses[index % statuses.length],
      'delivery_time': DateTime.now().add(Duration(minutes: 30 + index * 5)).toIso8601String(),
    };
  }
}
