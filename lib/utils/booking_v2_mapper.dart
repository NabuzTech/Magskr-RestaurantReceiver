import '../models/Booking V2/booking_v2_history_model.dart';
import '../models/Booking V2/get_bookingV2_detail_model.dart';
import '../models/Booking V2/get_today_booking_V2_model.dart';

// Shared field-for-field converters so a single booking fetched by id
// (after a push notification) can be spliced into any of the V2 list
// widgets, which each carry their own near-identical booking model.

Bookings bookingV2ToBookings(BookingV2DetailsModel d) {
  return Bookings(
    id: d.id,
    storeId: d.storeId,
    userId: d.userId,
    serviceId: d.serviceId,
    resourceId: d.resourceId,
    reference: d.reference,
    startAt: d.startAt,
    endAt: d.endAt,
    blockedUntil: d.blockedUntil,
    durationMinutes: d.durationMinutes,
    partySize: d.partySize,
    units: d.units,
    status: d.status,
    paymentStatus: d.paymentStatus,
    customerName: d.customerName,
    customerPhone: d.customerPhone,
    customerEmail: d.customerEmail,
    note: d.note,
    priceTotal: d.priceTotal,
    depositAmount: d.depositAmount,
    currency: d.currency,
    createdAt: d.createdAt,
  );
}

BookingV2HistoryModel bookingV2ToHistory(BookingV2DetailsModel d) {
  return BookingV2HistoryModel(
    id: d.id,
    storeId: d.storeId,
    userId: d.userId,
    serviceId: d.serviceId,
    resourceId: d.resourceId,
    reference: d.reference,
    startAt: d.startAt,
    endAt: d.endAt,
    blockedUntil: d.blockedUntil,
    durationMinutes: d.durationMinutes,
    partySize: d.partySize,
    units: d.units,
    status: d.status,
    paymentStatus: d.paymentStatus,
    customerName: d.customerName,
    customerPhone: d.customerPhone,
    customerEmail: d.customerEmail,
    note: d.note,
    priceTotal: d.priceTotal,
    depositAmount: d.depositAmount,
    currency: d.currency,
    createdAt: d.createdAt,
  );
}

bool isSameLocalDay(String? iso, DateTime day) {
  final dt = DateTime.tryParse(iso ?? '')?.toLocal();
  if (dt == null) return false;
  return dt.year == day.year && dt.month == day.month && dt.day == day.day;
}
