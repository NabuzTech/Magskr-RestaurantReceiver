import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/order_history_response_model.dart';
import '../models/order_model.dart';

class PrinterHelperEnglish {

  static Future<void> printTestFromSavedIp({required BuildContext context, required Order order, required String? store, required bool? auto,}) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIndex = prefs.getInt('selected_ip_index');
    if (auto == false) {
      if (selectedIndex == null) {
        _showSnackbar(context, 'no_printer_selected'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    final ip = prefs.getString('printer_ip_$selectedIndex');

    if (ip == null || ip.trim().isEmpty) {
      if (auto == false) {
        _showSnackbar(context, 'empty_printer_ip'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final result = await printer.connect(ip!, port: 9100);

      if (result == PosPrintResult.success) {
        await _printOrderDetails(printer, order, store);
        printer.disconnect();
        if (auto == false) {
          _showSnackbar(context, 'printer_success'.tr);
          Navigator.of(context).pop(true);
        }
      } else {
        if (auto == false) {
          _showSnackbar(context, '${'printer_failed'.tr}: $result');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (auto == false) {
        _showSnackbar(context, '${'printer_error'.tr}: $e');
        Navigator.of(context).pop(true);
      }
    }
  }

  static Future<void> _printOrderDetails(NetworkPrinter printer, Order order, String? store) async {
    String formatAmount(double? amount) {
      if (amount == null) return "0";

      final locale = Get.locale?.languageCode ?? 'en';
      String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }
    final now = DateTime.now();
    final dateTimeStr = '${now.day}/${now.month}/${now.year},'
        ' ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    var amount = order.invoice?.totalAmount ?? 0.0;
    var discount = order.invoice?.discount_amount ?? 0.0;
    var delFee = order.invoice?.delivery_fee ?? 0.0;
    final subtotal = order.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      // Item total (unit price + toppings) * quantity
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      return sum + itemTotal;
    }) ?? 0;

    final discountData = order.invoice?.discount_amount ?? 0.0;
    final deliveryFee = order.invoice?.delivery_fee ?? 0.0;
    final orderType =   order.orderType == 2 ?'pickup'.tr:'delivery'.tr;
    final note =   order.note.toString();
    String guestAddress = order.guestShippingJson?.line1?.toString() ?? '';
    String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';

    printer.text(" ${store ?? ''}",
      styles: const PosStyles(align: PosAlign.center, bold: true,),);
    printer.text(
      sanitizeText(orderType),
      styles: const PosStyles(align: PosAlign.center, bold: true,),
    );
    printer.text("${'order'.tr} # ${order.id ?? ''}",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    printer.setStyles(const PosStyles(align: PosAlign.center));
    printer.text(
      sanitizeText("${'invoice_number'.tr}: ${order.invoice?.invoiceNumber ?? ''}"),
      styles: const PosStyles(bold: true),
    );
    printer.text(
      sanitizeText("${'date'.tr}: ${order.createdAt ?? dateTimeStr}"),
      styles: const PosStyles(bold: true),
    );
    printer.hr();
    printer.text(
      sanitizeText("${'customer'.tr}: ${(order.shipping_address?.customer_name != null && order.shipping_address!.customer_name!.isNotEmpty)
          ? order.shipping_address!.customer_name!
          : guestName}"),
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );

    String addressText = "${'address'.tr}: ";
    if (order.shipping_address?.line1 != null && order.shipping_address!.line1!.isNotEmpty) {
      addressText += "${order.shipping_address!.line1!}, ${order.shipping_address?.city ?? ""}";
      if (order.orderType != 2) {
        addressText += ",${order.shipping_address?.zip ?? ""}";
      }
    } else {
      addressText += guestAddress;
    }

    printer.text(
      addressText,
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );

    printer.text(
      "${'phone'.tr}: ${(order.shipping_address?.phone != null && order.shipping_address!.phone!.isNotEmpty)
          ? order.shipping_address!.phone!
          : guestPhone}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();
    printer.feed(1);

    _printOrderItems(printer, order);
    printer.hr();

    // Mixed formatting for note: bold label + light text
    printer.textEncoded(
      Uint8List.fromList([
        ...utf8.encode("${'note'.tr}: "),
        0x1B, 0x21, 0x00, // ESC command to cancel bold
        ...utf8.encode(order.note ?? "")
      ]),
      styles: const PosStyles(align: PosAlign.left, bold: true), // Start with bold
    );

    printer.hr();
    _printItemWithNote(
        printer: printer,
        left: "${'subtotal'.tr}:",
        right: formatAmount(subtotal),
        note: '');

    if (discountData != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'discount'.tr}:",
          right: formatAmount(discount),
          note: '');
    }

    if (delFee != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'delivery_fee'.tr}:",
          right: formatAmount(delFee),
          note: '');
    }

    printer.hr();
    _printItemWithNote(
      printer: printer,
      left: "${'grand_total'.tr}:",
      right: formatAmount(amount),
      note: '',
    );
    printer.hr();

    printer.text("${'invoice_number'.tr}:  ${order.invoice?.invoiceNumber ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'payment_method'.tr}:  ${order.payment?.paymentMethod ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'paid'.tr}: ${order.createdAt ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();

    if (order.brutto_netto_summary != null &&
        order.brutto_netto_summary!.isNotEmpty) {
      _printTaxSummary(printer, order);
    }

    printer.feed(1);
    printer.cut();
  }

  static void _printOrderItems(NetworkPrinter printer, Order order) {
    if (order.items == null || order.items!.isEmpty) return;

    for (final item in order.items!) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      // Check if should show unit price (matching UI logic)
      bool shouldShowUnitPrice = (item.toppings?.isNotEmpty ?? false) && item.variant == null;

      // Print main product line (matching UI format exactly)
      String productLine = '${item.quantity ?? 0}X ${item.productName ?? "Unknown"}';
      if (shouldShowUnitPrice) {
        productLine += ' [${_formatCurrency(item.unitPrice ?? 0)}]';
      }

      final totalPriceText = _formatCurrency(itemTotal);

      _printItemWithNote(
        printer: printer,
        left: productLine,
        right: totalPriceText,
        note: '',
      );

      // Print variant info (if exists)
      if (item.variant != null) {
        final variantName = sanitizeText(item.variant!.name ?? '');
        final variantPrice = _formatCurrency(item.variant!.price ?? 0);
        final variantLine = '  ${item.quantity} × $variantName [$variantPrice]';
        printer.text(variantLine);
      }

      // Print toppings info (if exists)
      if (item.toppings != null && item.toppings!.isNotEmpty) {
        for (final topping in item.toppings!) {
          final tQty = topping.quantity ?? 1;
          final tName = sanitizeText(topping.name ?? '');
          final totalToppingPrice = (topping.price ?? 0) * tQty;
          final tPrice = _formatCurrency(totalToppingPrice);
          final toppingLine = '  $tQty × $tName [$tPrice]';
          printer.text(toppingLine);
        }
      }

      // Print note if exists
      if (item.note != null && item.note!.trim().isNotEmpty) {
        printer.text('  + ${sanitizeText(item.note!.trim())}');
      }

      printer.feed(1); // Add spacing between different items
    }
  }

  static String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  static String formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  static void _printTaxSummary(NetworkPrinter printer, Order order) {
    String formatAmount(double? amount) {
      if (amount == null) return "0";

      final locale = Get.locale?.languageCode ?? 'en';
      String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }

    printer.text(
      '${'vat_rate'.tr}        ${'gross'.tr}       ${'net'.tr}       ${'vat'.tr}',
      styles: const PosStyles(bold: true, align: PosAlign.left),
    );

    for (var tax in order.brutto_netto_summary!) {
      _printTaxSummaryLine(
        printer: printer,
        left: '${(tax.taxRate ?? 0.0).toStringAsFixed(0)} %',
        middle1: formatAmount(tax.brutto ?? 0.0),
        middle2: formatAmount(tax.netto ?? 0.0),
        right: formatAmount(tax.tax_amount ?? 0.0),
      );
    }
    printer.hr();
    printer.feed(1);
  }

  static void _printItemWithNote({required NetworkPrinter printer, required String left, required String right, String? note, int lineWidth = 48,}) {
    final availableWidth = lineWidth - right.length;

    if (left.length + right.length <= lineWidth) {
      final spaces = lineWidth - left.length - right.length;
      printer.text('$left${' ' * spaces}$right');
    } else {
      final leftLines = <String>[];
      String remaining = left;

      while (remaining.isNotEmpty) {
        if (remaining.length <= availableWidth) {
          leftLines.add(remaining);
          remaining = '';
        } else {
          int breakIndex = remaining.lastIndexOf(' ', availableWidth);
          if (breakIndex == -1) breakIndex = availableWidth;
          leftLines.add(remaining.substring(0, breakIndex).trimRight());
          remaining = remaining.substring(breakIndex).trimLeft();
        }
      }

      for (int i = 0; i < leftLines.length - 1; i++) {
        printer.text(leftLines[i]);
      }

      final lastLeft = leftLines.isNotEmpty ? leftLines.last : '';
      final spaces = lineWidth - lastLeft.length - right.length;
      final finalLine = '$lastLeft${' ' * (spaces >= 0 ? spaces : 0)}$right';
      printer.text(finalLine);
    }

    if (note != null && note.trim().isNotEmpty) {
      printer.text('+ ${note.trim()}');
    }
  }

  static void _printTaxSummaryLine({required NetworkPrinter printer, required String left, required String middle1, required String middle2, required String right}) {
    const col1 = 11;
    const col2 = 12;
    const col3 = 12;
    const col4 = 11;

    final leftStr = left.padRight(col1);
    final middle1Str = middle1.padLeft(col2);
    final middle2Str = middle2.padLeft(col3);
    final rightStr = right.padLeft(col4);

    final line = '$leftStr$middle1Str$middle2Str$rightStr';

    printer.text(line, styles: const PosStyles(align: PosAlign.left));
  }

  static String sanitizeText(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  static void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Map<String, Map<String, String>> translations = {
    'en': {
      'order': 'Order',
      'invoice_number': 'Invoice Number',
      'date': 'Date',
      'customer': 'Customer',
      'address': 'Address',
      'phone': 'Phone',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'delivery_fee': 'Delivery Fee',
      'grand_total': 'Grand Total',
      'payment_method': 'Payment Method',
      'paid': 'Paid',
      'vat_rate': 'VAT Rate',
      'gross': 'Gross',
      'net': 'Net',
      'vat': 'VAT',
      'note': 'Note',
    },
    'de': {
      'order': 'Bestellung',
      'invoice_number': 'Rechnungsnummer',
      'date': 'Datum',
      'customer': 'Kunde',
      'address': 'Adresse',
      'phone': 'Telefon',
      'subtotal': 'Zwischensumme',
      'discount': 'Rabatt',
      'delivery_fee': 'Liefergebühr',
      'grand_total': 'Gesamtbetrag',
      'payment_method': 'Zahlungsmethode',
      'paid': 'Bezahlt',
      'vat_rate': 'MWSt-Satz',
      'gross': 'Brutto',
      'net': 'Netto',
      'vat': 'MWSt',
      'note': 'Notiz'
    },
    'ch': {
      'order': 'Bestellung',
      'invoice_number': 'Rechnungsnummer',
      'date': 'Datum',
      'customer': 'Kunde',
      'address': 'Adresse',
      'phone': 'Telefon',
      'subtotal': 'Zwischensumme',
      'discount': 'Rabatt',
      'delivery_fee': 'Liefergebühr',
      'grand_total': 'Gesamtbetrag',
      'payment_method': 'Zahlungsmethode',
      'paid': 'Bezahlt',
      'vat_rate': 'MWSt-Satz',
      'gross': 'Brutto',
      'net': 'Netto',
      'vat': 'MWSt',
      'note': 'Notiz'
    }
  };

  static String trBg(String key, String locale) {
    String normalizedLocale = translations.containsKey(locale) ? locale : 'de';
    return translations[normalizedLocale]?[key] ??
        translations['de']?[key] ??
        translations['en']?[key] ??
        key;
  }

  static Future<void> printInBackground({required Order order, required String ipAddress, required String store, String locale = 'de',}) async {
    try {
      print("🖨️ Background printing started for order: ${order.id}");
      print("🌐 DEBUG: printInBackground() received locale = $locale");

      if (ipAddress.isEmpty) {
        print("❌ Background print failed: IP address is empty");
        return;
      }

      // Force default German fallback
      String savedLocale = 'de';
      print("🌐 Locale in Background Print: $savedLocale");

      // Network printer setup
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult connectResult =
      await printer.connect(ipAddress, port: 9100);

      if (connectResult == PosPrintResult.success) {
        print("✅ Background printer connected: $ipAddress");

        String formatAmount(double? amount) {
          if (amount == null) return "0";
          String localeToUse = savedLocale == 'de' ? 'de_DE' : 'en_US';
          return NumberFormat('#,##0.00#', localeToUse).format(amount);
        }

        final now = DateTime.now();
        final dateTimeStr =
            '${now.day}.${now.month}.${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

        var amount = order.invoice?.totalAmount ?? 0.0;
        var discount = order.invoice?.discount_amount ?? 0.0;
        var delFee = order.invoice?.delivery_fee ?? 0.0;
        String guestAddress = order.guestShippingJson?.line1?.toString() ?? '';
        String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
        String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';

        final subtotal = order.items?.fold<double>(0, (sum, item) {
          final toppingsTotal = item.toppings?.fold<double>(
            0,
                (tSum, topping) =>
            tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
          ) ??
              0;
          return sum +
              (((item.unitPrice ?? 0) + toppingsTotal) *
                  (item.quantity ?? 0));
        }) ?? 0;
        final orderType =   order.orderType == 2 ?'pickup'.tr:'delivery'.tr;

        printer.text(" ${store ?? ''}",
          styles: const PosStyles(align: PosAlign.center, bold: true,),);
        printer.text(
          sanitizeText(orderType),
          styles: const PosStyles(align: PosAlign.center, bold: true,),
        );
        printer.text(
          "${trBg('order', savedLocale)} # ${order.id ?? ''}",
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );

        printer.setStyles(const PosStyles(align: PosAlign.center));
        printer.text(
          sanitizeText(
              "${trBg('invoice_number', savedLocale)}: ${order.invoice?.invoiceNumber ?? ''}"),
          styles: const PosStyles(bold: true),
        );
        printer.text(
          sanitizeText(
              "${trBg('date', savedLocale)}: ${order.createdAt ?? dateTimeStr}"),
          styles: const PosStyles(bold: true),
        );
        printer.hr();

        printer.text(
          sanitizeText(
              "${trBg('customer', savedLocale)}: ${(order.shipping_address?.customer_name != null && order.shipping_address!.customer_name!.isNotEmpty)
                  ? order.shipping_address!.customer_name!
                  : guestName}"),
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );

        String addressText = "${trBg('address', savedLocale)}: ";
        if (order.shipping_address?.line1 != null && order.shipping_address!.line1!.isNotEmpty) {
          addressText += "${order.shipping_address!.line1!}, ${order.shipping_address?.city ?? ""}";
          if (order.orderType != 2) {
            addressText += ",${order.shipping_address?.zip ?? ""}";
          }
        } else {
          addressText += guestAddress;
        }

        printer.text(
          addressText,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        printer.text(
          "${trBg('phone', savedLocale)}: ${(order.shipping_address?.phone != null && order.shipping_address!.phone!.isNotEmpty)
              ? order.shipping_address!.phone!
              : guestPhone}",
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        printer.hr();
        printer.feed(1);

        _printOrderItems(printer, order);
        printer.hr();

        // Mixed formatting for note: bold label + light text
        printer.textEncoded(
          Uint8List.fromList([
            ...utf8.encode("${trBg('note', savedLocale)}: "),
            0x1B, 0x21, 0x00, // ESC command to cancel bold
            ...utf8.encode(order.note ?? "")
          ]),
          styles: const PosStyles(align: PosAlign.left, bold: true), // Start with bold
        );

        printer.hr();
        _printItemWithNote(
          printer: printer,
          left: "${trBg('subtotal', savedLocale)}:",
          right: formatAmount(subtotal),
          note: '',
        );

        if (discount != 0.0) {
          _printItemWithNote(
            printer: printer,
            left: "${trBg('discount', savedLocale)}:",
            right: formatAmount(discount),
            note: '',
          );
        }

        if (delFee != 0.0) {
          _printItemWithNote(
            printer: printer,
            left: "${trBg('delivery_fee', savedLocale)}:",
            right: formatAmount(delFee),
            note: '',
          );
        }

        printer.hr();
        _printItemWithNote(
          printer: printer,
          left: "${trBg('grand_total', savedLocale)}:",
          right: formatAmount(amount),
          note: '',
        );
        printer.hr();

        printer.text(
          "${trBg('invoice_number', savedLocale)}:  ${order.invoice?.invoiceNumber ?? ''}",
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        printer.text(
          "${trBg('payment_method', savedLocale)}:  ${order.payment?.paymentMethod ?? ''}",
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        printer.text(
          "${trBg('paid', savedLocale)}: ${order.createdAt ?? ''}",
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        printer.hr();

        if (order.brutto_netto_summary != null &&
            order.brutto_netto_summary!.isNotEmpty) {
          _printTaxSummaryBackground(printer, order, locale: locale);
        }

        printer.feed(1);
        printer.cut();
        printer.disconnect();
        print("✅ Background print completed successfully");
      } else {
        print("❌ Background printer connection failed: $connectResult");
      }
    } catch (e) {
      print("❌ Background print error: $e");
    }
  }

  static void _printTaxSummaryBackground(NetworkPrinter printer, Order order, {String locale = 'de'}) {
    // Updated amount formatter with forced locale
    String formatAmount(double? amount) {
      if (amount == null) return "0";
      String localeToUse = (locale == 'de') ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }
    print("🔍 DEBUG Tax Locale: $locale");
    print("🔍 DEBUG Text: ${trBg('vat_rate', locale)}");

    // Using trBg instead of 'xxx'.tr
    printer.text(
      '${trBg('vat_rate', locale)}        ${trBg('gross', locale)}       ${trBg('net', locale)}       ${trBg('vat', locale)}',
      styles: const PosStyles(bold: true, align: PosAlign.left),
    );

    for (var tax in order.brutto_netto_summary!) {
      _printTaxSummaryLine(
        printer: printer,
        left: '${(tax.taxRate ?? 0.0).toStringAsFixed(0)} %',
        middle1: formatAmount(tax.brutto ?? 0.0),
        middle2: formatAmount(tax.netto ?? 0.0),
        right: formatAmount(tax.tax_amount ?? 0.0),
      );
    }
    printer.hr();
    printer.feed(1);
  }




  static Future<void> printHistoryFromSavedIp({required BuildContext context, required orderHistoryResponseModel order, required String? store, required bool? auto,}) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIndex = prefs.getInt('selected_ip_index');
    if (auto == false) {
      if (selectedIndex == null) {
        _showSnackbar(context, 'no_printer_selected'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    final ip = prefs.getString('printer_ip_$selectedIndex');

    if (ip == null || ip.trim().isEmpty) {
      if (auto == false) {
        _showSnackbar(context, 'empty_printer_ip'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final result = await printer.connect(ip!, port: 9100);

      if (result == PosPrintResult.success) {
        await _printOrderHistoryDetails(printer, order, store);
        printer.disconnect();
        if (auto == false) {
          _showSnackbar(context, 'printer_success'.tr);
          Navigator.of(context).pop(true);
        }
      } else {
        if (auto == false) {
          _showSnackbar(context, '${'printer_failed'.tr}: $result');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (auto == false) {
        _showSnackbar(context, '${'printer_error'.tr}: $e');
        Navigator.of(context).pop(true);
      }
    }
  }
  static Future<void> _printOrderHistoryDetails(NetworkPrinter printer, orderHistoryResponseModel order, String? store) async {
    String formatAmount(double? amount) {
      if (amount == null) return "0";

      final locale = Get.locale?.languageCode ?? 'en';
      String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }
    final now = DateTime.now();
    final dateTimeStr = '${now.day}/${now.month}/${now.year},'
        ' ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    var amount = order.invoice?.totalAmount ?? 0.0;
    var discount = order.invoice?.discountAmount ?? 0.0;
    var delFee = order.invoice?.deliveryFee ?? 0.0;
    String guestAddress = order.guestShippingJson?.line1?.toString() ?? '';
    String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';

    final subtotal = order.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      // Item total (unit price + toppings) * quantity
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      return sum + itemTotal;
    }) ?? 0;

    final discountData = order.invoice?.discountAmount ?? 0.0;
    final deliveryFee = order.invoice?.deliveryFee ?? 0.0;
    final orderType =   order.orderType == 2 ?'pickup'.tr:'delivery'.tr;
    final note =   order.note.toString();


    printer.text(" ${store ?? ''}",
      styles: const PosStyles(align: PosAlign.center, bold: true,),);
    printer.text(
      sanitizeText(orderType),
      styles: const PosStyles(align: PosAlign.center, bold: true,),
    );
    printer.text("${'order'.tr} # ${order.id ?? ''}",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    printer.setStyles(const PosStyles(align: PosAlign.center));
    printer.text(
      sanitizeText("${'invoice_number'.tr}: ${order.invoice?.invoiceNumber ?? ''}"),
      styles: const PosStyles(bold: true),
    );
    printer.text(
      sanitizeText("${'date'.tr}: ${order.createdAt ?? dateTimeStr}"),
      styles: const PosStyles(bold: true),
    );
    printer.hr();
    printer.text(
      sanitizeText("${'customer'.tr}: ${(order.shippingAddress?.customerName != null && order.shippingAddress!.customerName!.isNotEmpty)
          ? order.shippingAddress!.customerName!
          : guestName}"),
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );

    String addressText = "${'address'.tr}: ";
    if (order.shippingAddress?.line1 != null && order.shippingAddress!.line1!.isNotEmpty) {
      addressText += "${order.shippingAddress!.line1!}, ${order.shippingAddress?.city ?? ""}";
      if (order.orderType != 2) {
        addressText += ",${order.shippingAddress?.zip ?? ""}";
      }
    } else {
      addressText += guestAddress;
    }

    printer.text(
      addressText,
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );

    printer.text(
      "${'phone'.tr}: ${(order.shippingAddress?.phone != null && order.shippingAddress!.phone!.isNotEmpty)
          ? order.shippingAddress!.phone!
          : guestPhone}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();
    printer.feed(1);

    _printOrderHistoryItems(printer, order);
    printer.hr();

    // Mixed formatting for note: bold label + light text
    printer.textEncoded(
      Uint8List.fromList([
        ...utf8.encode("${'note'.tr}: "),
        0x1B, 0x21, 0x00, // ESC command to cancel bold
        ...utf8.encode(order.note ?? "")
      ]),
      styles: const PosStyles(align: PosAlign.left, bold: true), // Start with bold
    );

    printer.hr();
    _printItemWithNote(
        printer: printer,
        left: "${'subtotal'.tr}:",
        right: formatAmount(subtotal),
        note: '');

    if (discountData != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'discount'.tr}:",
          right: formatAmount(discount),
          note: '');
    }

    if (delFee != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'delivery_fee'.tr}:",
          right: formatAmount(delFee),
          note: '');
    }

    printer.hr();
    _printItemWithNote(
      printer: printer,
      left: "${'grand_total'.tr}:",
      right: formatAmount(amount),
      note: '',
    );
    printer.hr();

    printer.text("${'invoice_number'.tr}:  ${order.invoice?.invoiceNumber ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'payment_method'.tr}:  ${order.payment?.paymentMethod ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'paid'.tr}: ${order.createdAt ?? ''}",
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();

    if (order.bruttoNettoSummary != null &&
        order.bruttoNettoSummary!.isNotEmpty) {
      _printTaxHistorySummary(printer, order);
    }

    printer.feed(1);
    printer.cut();
  }

  static void _printOrderHistoryItems(NetworkPrinter printer, orderHistoryResponseModel order) {
    if (order.items == null || order.items!.isEmpty) return;

    for (final item in order.items!) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      // Check if should show unit price (matching UI logic)
      bool shouldShowUnitPrice = (item.toppings?.isNotEmpty ?? false) && item.variant == null;

      // Print main product line (matching UI format exactly)
      String productLine = '${item.quantity ?? 0}X ${item.productName ?? "Unknown"}';
      if (shouldShowUnitPrice) {
        productLine += ' [${_formatCurrency(item.unitPrice ?? 0)}]';
      }

      final totalPriceText = _formatCurrency(itemTotal);

      _printItemWithNote(
        printer: printer,
        left: productLine,
        right: totalPriceText,
        note: '',
      );

      // Print variant info (if exists)
      if (item.variant != null) {
        final variantName = sanitizeText(item.variant!.name ?? '');
        final variantPrice = _formatCurrency(item.variant!.price ?? 0);
        final variantLine = '  ${item.quantity} × $variantName [$variantPrice]';
        printer.text(variantLine);
      }

      // Print toppings info (if exists)
      if (item.toppings != null && item.toppings!.isNotEmpty) {
        for (final topping in item.toppings!) {
          final tQty = topping.quantity ?? 1;
          final tName = sanitizeText(topping.name ?? '');
          final totalToppingPrice = (topping.price ?? 0) * tQty;
          final tPrice = _formatCurrency(totalToppingPrice);
          final toppingLine = '  $tQty × $tName [$tPrice]';
          printer.text(toppingLine);
        }
      }

      // Print note if exists
      if (item.note != null && item.note!.trim().isNotEmpty) {
        printer.text('  + ${sanitizeText(item.note!.trim())}');
      }

      printer.feed(1); // Add spacing between different items
    }
  }

  static void _printTaxHistorySummary(NetworkPrinter printer, orderHistoryResponseModel order) {String formatAmount(double? amount) {
    if (amount == null) return "0";

    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.00#', localeToUse).format(amount);
  }

  printer.text(
    '${'vat_rate'.tr}        ${'gross'.tr}       ${'net'.tr}       ${'vat'.tr}',
    styles: const PosStyles(bold: true, align: PosAlign.left),
  );

  for (var tax in order.bruttoNettoSummary!) {
    _printTaxSummaryLine(
      printer: printer,
      left: '${(tax.taxRate ?? 0.0).toStringAsFixed(0)} %',
      middle1: formatAmount(tax.brutto ?? 0.0),
      middle2: formatAmount(tax.netto ?? 0.0),
      right: formatAmount(tax.taxAmount ?? 0.0),
    );
  }
  printer.hr();
  printer.feed(1);
  }

}

