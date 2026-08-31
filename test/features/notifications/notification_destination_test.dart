import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/features/notifications/notification_destination.dart';

void main() {
  group('resolveNotificationDestination', () {
    test('opens the exact conversation for a payment-request notification', () {
      // Complaint #9: the backend creates a "New Payment Request"
      // notification with type = conversation and type_identifier = the
      // conversation id. Tapping it must open THAT thread, where the
      // payment-request card is actionable.
      final destination = resolveNotificationDestination(
        type: 'conversation',
        typeIdentifier: 314,
      );

      expect(destination.kind, NotificationDestinationKind.conversation);
      expect(destination.conversationId, '314');
    });

    test('handles a string identifier the same way as an int', () {
      final destination = resolveNotificationDestination(
        type: 'conversation',
        typeIdentifier: '314',
      );

      expect(destination.conversationId, '314');
    });

    test('routes a legacy payment_request type into the conversation too', () {
      final destination = resolveNotificationDestination(
        type: 'payment_request',
        typeIdentifier: 88,
      );

      expect(destination.kind, NotificationDestinationKind.conversation);
      expect(destination.conversationId, '88');
    });

    test('falls back to the list only when the identifier is missing', () {
      for (final missing in <dynamic>[null, '', '  ', 'null', 0, '0']) {
        final destination = resolveNotificationDestination(
          type: 'conversation',
          typeIdentifier: missing,
        );
        expect(
          destination.kind,
          NotificationDestinationKind.conversationList,
          reason: 'identifier: $missing',
        );
      }
    });

    test('chat and message types reach the same conversation route', () {
      for (final type in ['chat', 'message']) {
        expect(
          resolveNotificationDestination(type: type, typeIdentifier: 5),
          const NotificationDestination(
            NotificationDestinationKind.conversation,
            conversationId: '5',
          ),
          reason: type,
        );
      }
    });

    test('appointment notifications still carry their id', () {
      final destination = resolveNotificationDestination(
        type: 'appointment',
        typeIdentifier: 42,
      );

      expect(destination.kind, NotificationDestinationKind.appointment);
      expect(destination.id, '42');
    });

    test('an appointment notification without an id is a no-op', () {
      expect(
        resolveNotificationDestination(
          type: 'appointment',
          typeIdentifier: null,
        ).kind,
        NotificationDestinationKind.none,
      );
    });

    test('wallet and payment both go to the wallet/earnings screen', () {
      expect(
        resolveNotificationDestination(type: 'wallet').kind,
        NotificationDestinationKind.wallet,
      );
      expect(
        resolveNotificationDestination(type: 'payment').kind,
        NotificationDestinationKind.wallet,
      );
    });

    test('an unknown type does not navigate anywhere', () {
      expect(
        resolveNotificationDestination(type: 'something_new').kind,
        NotificationDestinationKind.none,
      );
    });
  });
}
