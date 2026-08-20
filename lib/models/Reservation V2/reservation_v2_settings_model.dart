class GetReservationV2SettingsModel {
  int? storeId;
  bool? enabled;
  int? maxCovers;
  int? slotIntervalMinutes;
  int? defaultDurationMinutes;
  int? maxPartySize;
  int? leadTimeMinutes;
  int? bookingWindowDays;

  GetReservationV2SettingsModel(
      {this.storeId,
        this.enabled,
        this.maxCovers,
        this.slotIntervalMinutes,
        this.defaultDurationMinutes,
        this.maxPartySize,
        this.leadTimeMinutes,
        this.bookingWindowDays});

  GetReservationV2SettingsModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    enabled = json['enabled'];
    maxCovers = json['max_covers'];
    slotIntervalMinutes = json['slot_interval_minutes'];
    defaultDurationMinutes = json['default_duration_minutes'];
    maxPartySize = json['max_party_size'];
    leadTimeMinutes = json['lead_time_minutes'];
    bookingWindowDays = json['booking_window_days'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['enabled'] = this.enabled;
    data['max_covers'] = this.maxCovers;
    data['slot_interval_minutes'] = this.slotIntervalMinutes;
    data['default_duration_minutes'] = this.defaultDurationMinutes;
    data['max_party_size'] = this.maxPartySize;
    data['lead_time_minutes'] = this.leadTimeMinutes;
    data['booking_window_days'] = this.bookingWindowDays;
    return data;
  }
}
