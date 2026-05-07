class GetAdminReportResponseModel {
  String? generatedAt;
  int? totalStores;
  List<Reports>? reports;

  GetAdminReportResponseModel(
      {this.generatedAt, this.totalStores, this.reports});

  GetAdminReportResponseModel.fromJson(Map<String, dynamic> json) {
    generatedAt = json['generated_at'];
    totalStores = json['total_stores'];
    if (json['reports'] != null) {
      reports = <Reports>[];
      json['reports'].forEach((v) {
        reports!.add(Reports.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['generated_at'] = generatedAt;
    data['total_stores'] = totalStores;
    if (reports != null) {
      data['reports'] = reports!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reports {
  int? storeId;
  String? storeName;
  bool? hasData;
  Report? report;

  Reports({this.storeId, this.storeName, this.hasData, this.report});

  Reports.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    hasData = json['has_data'];
    report =
    json['report'] != null ? Report.fromJson(json['report']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['has_data'] = hasData;
    if (report != null) {
      data['report'] = report!.toJson();
    }
    return data;
  }
}

class Report {
  double? totalSales;
  int? totalOrders;
  double? cashTotal;
  double? onlineTotal;
  double? discountTotal;
  double? deliveryTotal;
  double? totalTax;
  double? netTotal;
  TaxBreakdown? taxBreakdown;
  PaymentMethods? paymentMethods;
  OrderTypes? orderTypes;
  ApprovalStatuses? approvalStatuses;
  List<TopItems>? topItems;
  ByCategory? byCategory;
  double? totalSalesDelivery;
  List<DetailedOrders>? detailedOrders;

  Report(
      {this.totalSales,
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
        this.detailedOrders});

  Report.fromJson(Map<String, dynamic> json) {
    totalSales = json['total_sales'];
    totalOrders = json['total_orders'];
    cashTotal = json['cash_total'];
    onlineTotal = json['online_total'];
    discountTotal = json['discount_total'];
    deliveryTotal = json['delivery_total'];
    totalTax = json['total_tax'];
    netTotal = json['net_total'];
    taxBreakdown = json['tax_breakdown'] != null
        ? TaxBreakdown.fromJson(json['tax_breakdown'])
        : null;
    paymentMethods = json['payment_methods'] != null
        ? PaymentMethods.fromJson(json['payment_methods'])
        : null;
    orderTypes = json['order_types'] != null
        ? OrderTypes.fromJson(json['order_types'])
        : null;
    approvalStatuses = json['approval_statuses'] != null
        ? ApprovalStatuses.fromJson(json['approval_statuses'])
        : null;
    if (json['top_items'] != null) {
      topItems = <TopItems>[];
      json['top_items'].forEach((v) {
        topItems!.add(TopItems.fromJson(v));
      });
    }
    byCategory = json['by_category'] != null
        ? ByCategory.fromJson(json['by_category'])
        : null;
    totalSalesDelivery = json['total_sales + delivery'];
    if (json['detailed_orders'] != null) {
      detailedOrders = <DetailedOrders>[];
      json['detailed_orders'].forEach((v) {
        detailedOrders!.add(DetailedOrders.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_sales'] = totalSales;
    data['total_orders'] = totalOrders;
    data['cash_total'] = cashTotal;
    data['online_total'] = onlineTotal;
    data['discount_total'] = discountTotal;
    data['delivery_total'] = deliveryTotal;
    data['total_tax'] = totalTax;
    data['net_total'] = netTotal;
    if (taxBreakdown != null) {
      data['tax_breakdown'] = taxBreakdown!.toJson();
    }
    if (paymentMethods != null) {
      data['payment_methods'] = paymentMethods!.toJson();
    }
    if (orderTypes != null) {
      data['order_types'] = orderTypes!.toJson();
    }
    if (approvalStatuses != null) {
      data['approval_statuses'] = approvalStatuses!.toJson();
    }
    if (topItems != null) {
      data['top_items'] = topItems!.map((v) => v.toJson()).toList();
    }
    if (byCategory != null) {
      data['by_category'] = byCategory!.toJson();
    }
    data['total_sales + delivery'] = totalSalesDelivery;
    if (detailedOrders != null) {
      data['detailed_orders'] =
          detailedOrders!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TaxBreakdown {
  double? d7;
  double? d19;

  TaxBreakdown({this.d7});

  TaxBreakdown.fromJson(Map<String, dynamic> json) {
    d7 = json['7'];
    d7 = json['19'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['7'] = d7;
    data['19'] = d19;
    return data;
  }
}

class PaymentMethods {
  int? cash;

  PaymentMethods({this.cash});

  PaymentMethods.fromJson(Map<String, dynamic> json) {
    cash = json['cash'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cash'] = cash;
    return data;
  }
}

class OrderTypes {
  int? delivery;
  int? pickup;
  int? dineIn;

  OrderTypes({this.delivery, this.pickup, this.dineIn});

  OrderTypes.fromJson(Map<String, dynamic> json) {
    delivery = json['delivery'];
    pickup = json['pickup'];
    dineIn = json['dine_in'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['delivery'] = delivery;
    data['pickup'] = pickup;
    data['dine_in'] = dineIn;
    return data;
  }
}

class ApprovalStatuses {
  int? pending;
  int? accepted;
  int? declined;

  ApprovalStatuses({this.pending, this.accepted, this.declined});

  ApprovalStatuses.fromJson(Map<String, dynamic> json) {
    pending = json['pending'];
    accepted = json['accepted'];
    declined = json['declined'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pending'] = pending;
    data['accepted'] = accepted;
    data['declined'] = declined;
    return data;
  }
}

class TopItems {
  String? name;
  int? qty;
  double? revenue;

  TopItems({this.name, this.qty, this.revenue});

  TopItems.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    qty = json['qty'];
    revenue = json['revenue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['qty'] = qty;
    data['revenue'] = revenue;
    return data;
  }
}

class ByCategory {
  int? fleischgerichte;

  ByCategory({this.fleischgerichte});

  ByCategory.fromJson(Map<String, dynamic> json) {
    fleischgerichte = json['Fleischgerichte'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Fleischgerichte'] = fleischgerichte;
    return data;
  }
}

class DetailedOrders {
  String? invoiceNumber;
  String? orderType;
  double? total;

  DetailedOrders({this.invoiceNumber, this.orderType, this.total});

  DetailedOrders.fromJson(Map<String, dynamic> json) {
    invoiceNumber = json['invoice_number'];
    orderType = json['order_type'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['invoice_number'] = invoiceNumber;
    data['order_type'] = orderType;
    data['total'] = total;
    return data;
  }
}