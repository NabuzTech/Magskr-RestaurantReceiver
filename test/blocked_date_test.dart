import 'package:flutter_test/flutter_test.dart';
import 'package:food_receiver/models/blocked_date_model.dart';

void main() {
  test('single day sends end == start, reservation drops service_id', () {
    final body = blockedDateBody(
      storeId: 43,
      name: ' Silvester ',
      start: DateTime(2026, 12, 31),
      appliesTo: 'reservation',
      serviceId: 5,
      isActive: true,
    );
    expect(body['start_date'], '2026-12-31');
    expect(body['end_date'], '2026-12-31');
    expect(body['service_id'], isNull);
    expect(body['name'], 'Silvester');
  });

  test('booking range keeps service_id', () {
    final body = blockedDateBody(
      storeId: 43,
      name: '',
      start: DateTime(2026, 12, 24),
      end: DateTime(2026, 12, 26),
      appliesTo: 'booking',
      serviceId: 5,
      isActive: true,
    );
    expect(body['end_date'], '2026-12-26');
    expect(body['service_id'], 5);
  });
}
