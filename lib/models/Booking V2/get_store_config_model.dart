class BookingStoreConfigModel {
  int? storeId;
  bool? enabled;
  int? slotIntervalMinutes;
  int? leadTimeMinutes;
  int? bookingWindowDays;
  String? currency;
  bool? requirePayment;
  bool? autoAccept;

  BookingStoreConfigModel(
      {this.storeId,
        this.enabled,
        this.slotIntervalMinutes,
        this.leadTimeMinutes,
        this.bookingWindowDays,
        this.currency,
        this.requirePayment,
        this.autoAccept});

  BookingStoreConfigModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    enabled = json['enabled'];
    slotIntervalMinutes = json['slot_interval_minutes'];
    leadTimeMinutes = json['lead_time_minutes'];
    bookingWindowDays = json['booking_window_days'];
    currency = json['currency'];
    requirePayment = json['require_payment'];
    autoAccept = json['auto_accept'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['enabled'] = this.enabled;
    data['slot_interval_minutes'] = this.slotIntervalMinutes;
    data['lead_time_minutes'] = this.leadTimeMinutes;
    data['booking_window_days'] = this.bookingWindowDays;
    data['currency'] = this.currency;
    data['require_payment'] = this.requirePayment;
    data['auto_accept'] = this.autoAccept;
    return data;
  }
}