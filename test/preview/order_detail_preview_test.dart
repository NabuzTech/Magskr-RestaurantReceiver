// Renders OrderDetailEnglish to PNGs for design review (not a real test).
// Run: flutter test test/preview --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_receiver/models/order_model.dart';
import 'package:food_receiver/ui/Order/OrderDetailEnglish.dart';
import 'package:food_receiver/utils/AppTranslations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

Map<String, dynamic> _order(int approval) => {
      'id': 4037,
      'order_number': 4037,
      'order_type': 1,
      'order_status': 1,
      'approval_status': approval,
      'source': 'online',
      'created_at': DateTime.now().toIso8601String(),
      'delivery_time': DateTime.now().add(const Duration(minutes: 45)).toIso8601String(),
      'note': 'Bitte klingeln, 2. Stock links',
      'coupon_code': null,
      'guest_shipping_json': {
        'customer_name': 'Lara Streng',
        'phone': '015162613700',
        'email': 'lara.streng@t-online.de',
        'line1': 'Hauptstraße 12',
        'city': 'München',
        'zip': '80331',
        'country': 'DE',
      },
      'items': [
        {
          'id': 1, 'product_name': 'Pizza Margherita', 'quantity': 2, 'unit_price': 9.5,
          'note': 'Extra knusprig',
          'toppings': [
            {'name': 'Extra Käse', 'price': 1.5, 'quantity': 1},
            {'name': 'Oliven', 'price': 1.0, 'quantity': 1},
          ],
        },
        {'id': 2, 'product_name': 'Tiramisu', 'quantity': 1, 'unit_price': 5.9},
        {'id': 3, 'product_name': 'Coca-Cola 0,33l', 'quantity': 3, 'unit_price': 2.8},
      ],
      'invoice': {
        'invoice_number': 'INV-2026-0931', 'total_amount': 39.3, 'issued_at': '2026-09-30T19:02:00', 'store_id': 20, 'id': 1, 'order_id': 4037,
        'discount_amount': 2.0, 'delivery_fee': 2.5,
      },
      'payment': {'payment_method': 'cash', 'status': 'pending', 'paid_at': '2026-09-30T19:02:00', 'id': 1, 'order_id': 4037, 'amount': 39.3},
      'brutto_netto_summary': [
        {'tax_rate': 7, 'brutto': 30.9, 'netto': 28.88, 'tax_amount': 2.02},
        {'tax_rate': 19, 'brutto': 8.4, 'netto': 7.06, 'tax_amount': 1.34},
      ],
    };

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
    final mf = '$flutterRoot/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', ['$mf/roboto-regular.ttf', '$mf/roboto-medium.ttf', '$mf/roboto-bold.ttf', '$mf/roboto-black.ttf']);
    await _loadFont('MaterialIcons', ['$mf/materialicons-regular.otf']);
    await _loadFont('Sora', ['assets/fontFamily/Sora-Regular.ttf']);
    await _loadFont('Mulish', ['assets/fontFamily/Mulish-Regular.ttf']);
  });

  for (final (name, approval, height) in [
    ('pending', 1, 844.0),
    ('pending_full', 1, 2000.0),
    ('accepted_full', 2, 2000.0),
  ]) {
    testWidgets('order detail $name', (tester) async {
      tester.view.physicalSize = Size(390 * 2, height * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GetMaterialApp(
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: const Locale('de'),
        theme: ThemeData(primaryColor: Colors.blue),
        home: OrderDetailEnglish(Order.fromJson(_order(approval))),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      await expectLater(find.byType(OrderDetailEnglish), matchesGoldenFile('out/$name.png'));
    });
  }
}
