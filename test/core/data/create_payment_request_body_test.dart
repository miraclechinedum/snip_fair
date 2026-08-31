import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';

void main() {
  group('POST /payment-requests body', () {
    final items = [
      {'name': 'Hair serum', 'unit_price': 120.5, 'quantity': 2},
    ];

    test('omits appointment_id entirely for a standalone request', () {
      final body = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 42,
        title: 'Additional products used',
        items: items,
      );

      // Client issue #3: a payment request with no appointment must be
      // sendable. The key is omitted (this file's convention for nullable
      // fields) rather than sent as an explicit null.
      expect(body.containsKey('appointment_id'), isFalse);
      expect(body['recipient_id'], 42);
      expect(body['title'], 'Additional products used');
      expect(body['items'], items);
    });

    test('omits appointment_id when it is explicitly null', () {
      final body = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 42,
        title: 'Additional service',
        items: items,
        appointmentId: null,
      );

      expect(body.containsKey('appointment_id'), isFalse);
    });

    test('includes appointment_id when the stylist linked a booking', () {
      final body = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 42,
        title: 'Extra treatment',
        items: items,
        appointmentId: 987,
      );

      expect(body['appointment_id'], 987);
    });

    test('carries description and expiry only when supplied', () {
      final bare = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 1,
        title: 't',
        items: items,
      );
      expect(bare.containsKey('description'), isFalse);
      expect(bare.containsKey('expires_in_hours'), isFalse);

      final full = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 1,
        title: 't',
        items: items,
        description: 'why',
        expiresInHours: 24,
      );
      expect(full['description'], 'why');
      expect(full['expires_in_hours'], 24);
    });

    test('preserves per-item quantity so multi-unit items bill correctly', () {
      final body = SnipFairBackendRemoteSource.buildCreatePaymentRequestBody(
        recipientId: 1,
        title: 't',
        items: [
          {'name': 'Serum', 'unit_price': 50.0, 'quantity': 3},
          {'name': 'Wax', 'unit_price': 25.0, 'quantity': 1},
        ],
      );

      final sent = body['items']! as List<Map<String, dynamic>>;
      expect(sent.map((i) => i['quantity']), [3, 1]);
    });
  });
}
