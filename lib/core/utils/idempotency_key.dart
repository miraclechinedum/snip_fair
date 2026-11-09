import 'dart:math';

/// Produces the value sent in the `Idempotency-Key` header of a money-moving
/// request. Injected so tests can supply predictable keys.
typedef IdempotencyKeyGenerator = String Function();

final Random _secureRandom = Random.secure();

/// A random (version 4) RFC 4122 UUID, e.g.
/// `3b241101-e2bb-4255-8caf-4136c566a962`, from a cryptographically secure
/// source.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
