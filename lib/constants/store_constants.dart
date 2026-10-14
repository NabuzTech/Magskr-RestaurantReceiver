// Hardcoded values used across the app (API + UI), collected in one place.
// Usage example: if (roleId == RoleId.superAdmin) ...

/// `role_id` (SharedPrefs key: valueShared_ROLE_ID). Decides the home screen after login.
class RoleId {
  static const int superAdmin = 1; // SuperAdmin() – all stores, AdminOrder / SuperAdminReport tabs
  static const int storeUser = 2; // HomeScreen() – single store (any other id also goes here)
  static const int storeOwner = 5; // StoreOwnerStores() – multi-store owner, limited drawer
  static const int storeDriver = 4; // driver of the single store to deliver order
}

/// `store_type` (SharedPrefs key: valueShared_STORE_TYPE). Stored as a String.
class StoreType {
  static const String restaurant = '0'; // normal restaurant (order, reservation , all function )
  static const String pos = '1'; // POS tab, Online/POS source tabs, Refresh/Sync buttons
  static const String simple = '2'; // no Toppings/Topping Group/Group/Product Group/Store menu, shows full address
}

/// `order_type` of an order.
class OrderType {
  static const int delivery = 1;
  static const int pickup = 2; // a.k.a. collection
  static const int dineIn = 3; // default for orders created from POS
}

/// `approval_status` of an order (accept / decline).
/// Note: AppController.getHistoryOrderStatus uses 0/1/2 instead – does not match this.
class ApprovalStatus {
  static const int pending = 1;
  static const int accepted = 2;
  static const int declined = 3;
}

/// Local UI state in OrderDetailEnglish (the `orderType` field there – not a real order type).
class OrderActionState {
  static const int none = 0; // Accept / Decline buttons shown
  static const int manualAccept = 1;
  static const int manualDecline = 2;
}

/// Reservation `status` (String, sent to updateReservationV2 / reservation_details).
class ReservationStatus {
  static const String pending = 'pending';
  static const String booked = 'booked'; // accept
  static const String cancelled = 'cancelled'; // decline
  // Old flow also handles 'accepted' / 'declined'.
}

/// `day_of_week` – Store timing / delivery & pickup timing (store_hour_bottomsheet, delivery_pickup_timing).
class DayOfWeek {
  static const int monday = 0;
  static const int tuesday = 1;
  static const int wednesday = 2;
  static const int thursday = 3;
  static const int friday = 4;
  static const int saturday = 5;
  static const int sunday = 6;
}

/// `day_of_week` – Category availability (category_management) uses a DIFFERENT mapping: Sunday = 0.
class CategoryDayOfWeek {
  static const int sunday = 0;
  static const int monday = 1;
  static const int tuesday = 2;
  static const int wednesday = 3;
  static const int thursday = 4;
  static const int friday = 5;
  static const int saturday = 6;
}

/// Printer `type` sent when adding / editing a printer IP.
class PrinterType {
  static const int network = 0; // only value used
}

/// Product `type`.
class ProductType {
  static const String simple = 'simple';
  static const String variable = 'variable';
}

/// Default payment method.
class PaymentMethod {
  static const String cash = 'cash';
}
