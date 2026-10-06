import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/admin/payment_by_ordertype_model.dart';

class PaymentSettings extends StatefulWidget {
  const PaymentSettings({super.key});

  @override
  State<PaymentSettings> createState() => _PaymentSettingsState();
}

class _PaymentSettingsState extends State<PaymentSettings> {
  String? storeId;
  bool isLoading = true;
  String selectedType = 'delivery';
  PaymentByOrderTypeModel? deliveryConfig;
  PaymentByOrderTypeModel? collectionConfig;
  bool isSaving = false;

  PaymentByOrderTypeModel? get _current => selectedType == 'delivery' ? deliveryConfig : collectionConfig;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      storeId = prefs.getString(valueShared_STORE_KEY);
      if (storeId == null || storeId!.isEmpty) {
        throw Exception('Store not found');
      }
      final list = await CallService().getPaymentOrderType(storeId!);
      for (final item in list) {
        final name = item.orderTypeName?.toLowerCase() ?? '';
        if (name.contains('delivery')) {
          deliveryConfig = item;
        } else if (name.contains('collection')) {
          collectionConfig = item;
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, '${'pm_load_error'.tr}: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFlag(String field, bool value) async {
    final current = _current;
    if (current?.flags == null || storeId == null || isSaving) return;

    final flags = current!.flags!;
    final previous = _flagValue(flags, field);
    setState(() {
      _setFlagValue(flags, field, value);
      isSaving = true;
    });

    try {
      final body = {
        'cash_enabled': flags.cashEnabled ?? false,
        'card_enabled': flags.cardEnabled ?? false,
        'stripe_enabled': flags.stripeEnabled ?? false,
        'paypal_enabled': flags.paypalEnabled ?? false,
        'ec_enabled': flags.ecEnabled ?? false,
      };
      await CallService().updatePaymentByOrderType(body, storeId!, selectedType);
    } catch (e) {
      setState(() => _setFlagValue(flags, field, previous));
      Get.snackbar('error'.tr, '${'pm_update_error'.tr}: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  bool _flagValue(Flags flags, String field) {
    switch (field) {
      case 'cash_enabled':
        return flags.cashEnabled ?? false;
      case 'stripe_enabled':
        return flags.stripeEnabled ?? false;
      case 'paypal_enabled':
        return flags.paypalEnabled ?? false;
      case 'ec_enabled':
        return flags.ecEnabled ?? false;
      default:
        return false;
    }
  }

  void _setFlagValue(Flags flags, String field, bool value) {
    switch (field) {
      case 'cash_enabled':
        flags.cashEnabled = value;
        break;
      case 'stripe_enabled':
        flags.stripeEnabled = value;
        break;
      case 'paypal_enabled':
        flags.paypalEnabled = value;
        break;
      case 'ec_enabled':
        flags.ecEnabled = value;
        break;
    }
  }

  Widget _tab(String key, String label) {
    final selected = selectedType == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required String field,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Sora', fontSize: 14)),
                Text(subtitle, style: TextStyle(fontFamily: 'Sora', fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.orange,
            onChanged: isSaving ? null : (v) => _toggleFlag(field, v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final flags = current?.flags;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text('pm_title'.tr, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'pm_override_hint'.tr,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xffF3F3F3), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        _tab('delivery', 'pm_delivery'.tr),
                        _tab('collection', 'pm_collection'.tr),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (current?.isOverride == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'pm_custom'.tr,
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (flags == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('pm_none'.tr, style: const TextStyle(fontFamily: 'Sora'))),
                    )
                  else ...[
                    _paymentTile(
                      icon: Icons.payments_outlined,
                      iconColor: Colors.green,
                      iconBg: const Color(0xffEBFAF2),
                      title: 'pm_cash'.tr,
                      subtitle: 'pm_cash_sub'.tr,
                      value: flags.cashEnabled ?? false,
                      field: 'cash_enabled',
                    ),
                    _paymentTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: Colors.purple,
                      iconBg: const Color(0xffF3EEFB),
                      title: 'Stripe',
                      subtitle: 'pm_stripe_sub'.tr,
                      value: flags.stripeEnabled ?? false,
                      field: 'stripe_enabled',
                    ),
                    _paymentTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.blue,
                      iconBg: const Color(0xffEAF3FE),
                      title: 'PayPal',
                      subtitle: 'pm_paypal_sub'.tr,
                      value: flags.paypalEnabled ?? false,
                      field: 'paypal_enabled',
                    ),
                    _paymentTile(
                      icon: Icons.credit_card,
                      iconColor: Colors.orange,
                      iconBg: const Color(0xffFFF1E8),
                      title: 'pm_ec'.tr,
                      subtitle: 'pm_ec_sub'.tr,
                      value: flags.ecEnabled ?? false,
                      field: 'ec_enabled',
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
