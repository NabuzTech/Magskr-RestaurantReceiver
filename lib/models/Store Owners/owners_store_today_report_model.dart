class OwnersStoreTodayReportModel {
  final String? generatedAt;
  final int? totalStores;
  final List<Reports>? reports;

  OwnersStoreTodayReportModel({
    this.generatedAt,
    this.totalStores,
    this.reports,
  });

  factory OwnersStoreTodayReportModel.fromJson(
      Map<String, dynamic> json) {
    return OwnersStoreTodayReportModel(
      generatedAt: json['generated_at'],
      totalStores: json['total_stores'],
      reports: (json['reports'] as List?)
          ?.map((e) => Reports.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt,
      'total_stores': totalStores,
      'reports': reports?.map((e) => e.toJson()).toList(),
    };
  }
}

class Reports {
  final int? storeId;
  final String? storeName;
  final bool? hasData;
  final Report? report;

  Reports({
    this.storeId,
    this.storeName,
    this.hasData,
    this.report,
  });

  factory Reports.fromJson(Map<String, dynamic> json) {
    return Reports(
      storeId: json['store_id'],
      storeName: json['store_name'],
      hasData: json['has_data'],
      report:
      json['report'] != null ? Report.fromJson(json['report']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'has_data': hasData,
      'report': report?.toJson(),
    };
  }
}

class Report {
  final double? totalSales;
  final int? totalOrders;
  final double? cashTotal;
  final double? onlineTotal;
  final double? discountTotal;
  final double? deliveryTotal;
  final double? totalTax;
  final double? netTotal;

  final Map<String, dynamic>? taxBreakdown;
  final Map<String, dynamic>? paymentMethods;
  final OrderTypes? orderTypes;
  final ApprovalStatuses? approvalStatuses;

  final List<TopItems>? topItems;

  final Map<String, dynamic>? byCategory;

  final double? totalSalesDelivery;

  final List<DetailedOrders>? detailedOrders;

  Report({
    this.totalSales,
    this.totalOrders,
    this.cashTotal,
    this.onlineTotal,
    this.discountTotal,
    this.deliveryTotal,
    this.totalTax,
    this.netTotal,
    this.taxBreakdown,
    this.paymentMethods,
    this.orderTypes,
    this.approvalStatuses,
    this.topItems,
    this.byCategory,
    this.totalSalesDelivery,
    this.detailedOrders,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      totalSales: (json['total_sales'] as num?)?.toDouble(),
      totalOrders: json['total_orders'],
      cashTotal: (json['cash_total'] as num?)?.toDouble(),
      onlineTotal: (json['online_total'] as num?)?.toDouble(),
      discountTotal: (json['discount_total'] as num?)?.toDouble(),
      deliveryTotal: (json['delivery_total'] as num?)?.toDouble(),
      totalTax: (json['total_tax'] as num?)?.toDouble(),
      netTotal: (json['net_total'] as num?)?.toDouble(),
      taxBreakdown:
      Map<String, dynamic>.from(json['tax_breakdown'] ?? {}),
      paymentMethods:
      Map<String, dynamic>.from(json['payment_methods'] ?? {}),
      orderTypes: json['order_types'] != null
          ? OrderTypes.fromJson(json['order_types'])
          : null,
      approvalStatuses: json['approval_statuses'] != null
          ? ApprovalStatuses.fromJson(
          json['approval_statuses'])
          : null,
      topItems: (json['top_items'] as List?)
          ?.map((e) => TopItems.fromJson(e))
          .toList(),
      byCategory:
      Map<String, dynamic>.from(json['by_category'] ?? {}),
      totalSalesDelivery:
      (json['total_sales + delivery'] as num?)
          ?.toDouble(),
      detailedOrders: (json['detailed_orders'] as List?)
          ?.map((e) => DetailedOrders.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'cash_total': cashTotal,
      'online_total': onlineTotal,
      'discount_total': discountTotal,
      'delivery_total': deliveryTotal,
      'total_tax': totalTax,
      'net_total': netTotal,
      'tax_breakdown': taxBreakdown,
      'payment_methods': paymentMethods,
      'order_types': orderTypes?.toJson(),
      'approval_statuses': approvalStatuses?.toJson(),
      'top_items':
      topItems?.map((e) => e.toJson()).toList(),
      'by_category': byCategory,
      'total_sales + delivery': totalSalesDelivery,
      'detailed_orders':
      detailedOrders?.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderTypes {
  final int? delivery;
  final int? pickup;
  final int? dineIn;

  OrderTypes({
    this.delivery,
    this.pickup,
    this.dineIn,
  });

  factory OrderTypes.fromJson(Map<String, dynamic> json) {
    return OrderTypes(
      delivery: json['delivery'],
      pickup: json['pickup'],
      dineIn: json['dine_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery': delivery,
      'pickup': pickup,
      'dine_in': dineIn,
    };
  }
}

class ApprovalStatuses {
  final int? pending;
  final int? accepted;
  final int? declined;

  ApprovalStatuses({
    this.pending,
    this.accepted,
    this.declined,
  });

  factory ApprovalStatuses.fromJson(
      Map<String, dynamic> json) {
    return ApprovalStatuses(
      pending: json['pending'],
      accepted: json['accepted'],
      declined: json['declined'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending': pending,
      'accepted': accepted,
      'declined': declined,
    };
  }
}

class TopItems {
  final String? name;
  final int? qty;
  final double? revenue;

  TopItems({
    this.name,
    this.qty,
    this.revenue,
  });

  factory TopItems.fromJson(Map<String, dynamic> json) {
    return TopItems(
      name: json['name'],
      qty: json['qty'],
      revenue:
      (json['revenue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'revenue': revenue,
    };
  }
}

class DetailedOrders {
  final String? invoiceNumber;
  final String? orderType;
  final double? total;

  DetailedOrders({
    this.invoiceNumber,
    this.orderType,
    this.total,
  });

  factory DetailedOrders.fromJson(
      Map<String, dynamic> json) {
    return DetailedOrders(
      invoiceNumber: json['invoice_number'],
      orderType: json['order_type'],
      total: (json['total'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'order_type': orderType,
      'total': total,
    };
  }
}