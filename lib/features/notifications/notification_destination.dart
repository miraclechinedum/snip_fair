import 'package:flutter/foundation.dart';

/// Where a notification should take the user.
///
/// Kept as a plain value so the routing decision is testable without a
/// router, a BuildContext, or a live cubit — the actual `push` calls stay in
/// the widget layer.
enum NotificationDestinationKind {
  profile,
  appointment,
  wallet,

  /// A specific chat thread. [NotificationDestination.conversationId] is set.
  conversation,

  /// The conversations list — only used when a conversation notification
  /// arrives without a usable identifier.
  conversationList,

  dispute,
  none,
}

@immutable
class NotificationDestination {
  const NotificationDestination(this.kind, {this.conversationId, this.id});

  final NotificationDestinationKind kind;

  /// Set only for [NotificationDestinationKind.conversation].
  final String? conversationId;

  /// Set for appointment destinations.
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is NotificationDestination &&
      other.kind == kind &&
      other.conversationId == conversationId &&
      other.id == id;

  @override
  int get hashCode => Object.hash(kind, conversationId, id);

  @override
  String toString() => 'NotificationDestination(${kind.name}, '
      'conversationId: $conversationId, id: $id)';
}

/// Normalises a `type_identifier`, which the API sends as either an int or a
/// string, into a usable id. Blank / null / the literal strings `"null"` and
/// `"0"` are treated as absent.
String? normaliseIdentifier(dynamic identifier) {
  if (identifier == null) return null;
  final raw = identifier.toString().trim();
  if (raw.isEmpty || raw == 'null' || raw == '0') return null;
  return raw;
}

/// Maps a notification's `type` + `type_identifier` onto a destination.
///
/// Backend contract for the payment-request and chat notifications is
/// `type = conversation` with `type_identifier` = the conversation id, so
/// both land on [NotificationDestinationKind.conversation] and open that
/// exact thread — where the payment-request card is visible and actionable.
NotificationDestination resolveNotificationDestination({
  required String? type,
  dynamic typeIdentifier,
}) {
  final id = normaliseIdentifier(typeIdentifier);

  switch (type) {
    case 'profile':
      return const NotificationDestination(
        NotificationDestinationKind.profile,
      );
    case 'appointment':
      if (id == null) {
        return const NotificationDestination(
          NotificationDestinationKind.none,
        );
      }
      return NotificationDestination(
        NotificationDestinationKind.appointment,
        id: id,
      );
    case 'wallet':
    case 'payment':
      return const NotificationDestination(NotificationDestinationKind.wallet);
    case 'conversation':
    case 'chat':
    case 'message':
    case 'payment_request':
      if (id == null) {
        return const NotificationDestination(
          NotificationDestinationKind.conversationList,
        );
      }
      return NotificationDestination(
        NotificationDestinationKind.conversation,
        conversationId: id,
      );
    case 'dispute':
      return const NotificationDestination(
        NotificationDestinationKind.dispute,
      );
    default:
      return const NotificationDestination(NotificationDestinationKind.none);
  }
}
