class GetTodayReceivedBookingV2Model {
  String? date;
  List<int>? storeIds;
  Summary? summary;
  List<Booking>? bookings;

  GetTodayReceivedBookingV2Model({
    this.date,
    this.storeIds,
    this.summary,
    this.bookings,
  });

  GetTodayReceivedBookingV2Model.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    storeIds = json['store_ids'] != null
        ? List<int>.from(json['store_ids'])
        : null;

    summary = json['summary'] != null
        ? Summary.fromJson(json['summary'])
        : null;

    if (json['bookings'] != null) {
      bookings = <Booking>[];
      json['bookings'].forEach((v) {
        bookings!.add(Booking.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['date'] = date;
    data['store_ids'] = storeIds;

    if (summary != null) {
      data['summary'] = summary!.toJson();
    }

    if (bookings != null) {
      data['bookings'] = bookings!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Summary {
  int? total;
  int? pending;
  int? booked;
  int? cancelled;
  int? activeTotal;
  int? guests;
  int? pendingGuests;
  int? bookedGuests;
  double? revenueBooked;
  double? revenuePaid;
  int? upcomingPending;
  int? upcomingBooked;
  int? upcomingTotal;
  int? upcomingPendingGuests;
  int? upcomingBookedGuests;
  String? nextUpcomingDate;
  bool? upcomingPendingTruncated;

  Summary({
    this.total,
    this.pending,
    this.booked,
    this.cancelled,
    this.activeTotal,
    this.guests,
    this.pendingGuests,
    this.bookedGuests,
    this.revenueBooked,
    this.revenuePaid,
    this.upcomingPending,
    this.upcomingBooked,
    this.upcomingTotal,
    this.upcomingPendingGuests,
    this.upcomingBookedGuests,
    this.nextUpcomingDate,
    this.upcomingPendingTruncated,
  });

  Summary.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    pending = json['pending'];
    booked = json['booked'];
    cancelled = json['cancelled'];
    activeTotal = json['active_total'];
    guests = json['guests'];
    pendingGuests = json['pending_guests'];
    bookedGuests = json['booked_guests'];
    revenueBooked = (json['revenue_booked'] as num?)?.toDouble();
    revenuePaid = (json['revenue_paid'] as num?)?.toDouble();
    upcomingPending = json['upcoming_pending'];
    upcomingBooked = json['upcoming_booked'];
    upcomingTotal = json['upcoming_total'];
    upcomingPendingGuests = json['upcoming_pending_guests'];
    upcomingBookedGuests = json['upcoming_booked_guests'];
    nextUpcomingDate = json['next_upcoming_date'];
    upcomingPendingTruncated = json['upcoming_pending_truncated'];
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'booked': booked,
      'cancelled': cancelled,
      'active_total': activeTotal,
      'guests': guests,
      'pending_guests': pendingGuests,
      'booked_guests': bookedGuests,
      'revenue_booked': revenueBooked,
      'revenue_paid': revenuePaid,
      'upcoming_pending': upcomingPending,
      'upcoming_booked': upcomingBooked,
      'upcoming_total': upcomingTotal,
      'upcoming_pending_guests': upcomingPendingGuests,
      'upcoming_booked_guests': upcomingBookedGuests,
      'next_upcoming_date': nextUpcomingDate,
      'upcoming_pending_truncated': upcomingPendingTruncated,
    };
  }
}

class Booking {
  int? id;
  int? storeId;
  int? userId;
  int? serviceId;
  int? resourceId;
  String? reference;
  String? startAt;
  String? endAt;
  String? blockedUntil;
  int? durationMinutes;
  int? partySize;
  int? units;
  String? status;
  String? paymentStatus;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  Map<String, dynamic>? formData;
  List<SelectedOption>? selectedOptions;
  double? priceTotal;
  double? depositAmount;
  String? currency;
  String? createdAt;

  Booking({
    this.id,
    this.storeId,
    this.userId,
    this.serviceId,
    this.resourceId,
    this.reference,
    this.startAt,
    this.endAt,
    this.blockedUntil,
    this.durationMinutes,
    this.partySize,
    this.units,
    this.status,
    this.paymentStatus,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.note,
    this.formData,
    this.selectedOptions,
    this.priceTotal,
    this.depositAmount,
    this.currency,
    this.createdAt,
  });

  Booking.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    userId = json['user_id'];
    serviceId = json['service_id'];
    resourceId = json['resource_id'];
    reference = json['reference'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    blockedUntil = json['blocked_until'];
    durationMinutes = json['duration_minutes'];
    partySize = json['party_size'];
    units = json['units'];
    status = json['status'];
    paymentStatus = json['payment_status'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];

    formData = json['form_data'] != null
        ? Map<String, dynamic>.from(json['form_data'])
        : null;

    if (json['selected_options'] != null) {
      selectedOptions = <SelectedOption>[];

      json['selected_options'].forEach((v) {
        selectedOptions!.add(SelectedOption.fromJson(v));
      });
    }

    priceTotal = (json['price_total'] as num?)?.toDouble();
    depositAmount = (json['deposit_amount'] as num?)?.toDouble();
    currency = json['currency'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['id'] = id;
    data['store_id'] = storeId;
    data['user_id'] = userId;
    data['service_id'] = serviceId;
    data['resource_id'] = resourceId;
    data['reference'] = reference;
    data['start_at'] = startAt;
    data['end_at'] = endAt;
    data['blocked_until'] = blockedUntil;
    data['duration_minutes'] = durationMinutes;
    data['party_size'] = partySize;
    data['units'] = units;
    data['status'] = status;
    data['payment_status'] = paymentStatus;
    data['customer_name'] = customerName;
    data['customer_phone'] = customerPhone;
    data['customer_email'] = customerEmail;
    data['note'] = note;
    data['form_data'] = formData;

    if (selectedOptions != null) {
      data['selected_options'] =
          selectedOptions!.map((v) => v.toJson()).toList();
    }

    data['price_total'] = priceTotal;
    data['deposit_amount'] = depositAmount;
    data['currency'] = currency;
    data['created_at'] = createdAt;

    return data;
  }
}

class SelectedOption {
  int? id;
  String? name;
  String? priceMode;
  double? priceDelta;

  SelectedOption({
    this.id,
    this.name,
    this.priceMode,
    this.priceDelta,
  });

  SelectedOption.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    priceMode = json['price_mode'];
    priceDelta = (json['price_delta'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_mode': priceMode,
      'price_delta': priceDelta,
    };
  }
}