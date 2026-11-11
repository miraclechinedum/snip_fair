import 'dart:convert';
import 'dart:developer';

import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

/// The minimum needed to resume an unresolved card payment of a payment
/// request after an app restart: which request, which Peach deposit (top-up)
/// or native card attempt, how far it got and when. No card data, tokens or
/// amounts.
class PaymentRequestAttempt {
  const PaymentRequestAttempt({
    required this.requestId,
    required this.depositId,
    required this.verified,
    required this.updatedAt,
  }) : cardPaymentId = null;

  /// A native card attempt (`payment_id`), checked with the payment
  /// request's own status endpoint.
  const PaymentRequestAttempt.card({
    required this.requestId,
    required String this.cardPaymentId,
    required this.updatedAt,
  })  : depositId = '',
        verified = false;

  final int requestId;

  /// Empty for a native card attempt.
  final String depositId;
  final String? cardPaymentId;

  bool get isNativeCard => cardPaymentId != null;

  /// The top-up was verified (money in the wallet) but `/pay` has not
  /// succeeded yet.
  final bool verified;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => isNativeCard
      ? {
          'request_id': requestId,
          'card_payment_id': cardPaymentId,
          'stage': 'card',
          'updated_at': updatedAt.toUtc().toIso8601String(),
        }
      : {
          'request_id': requestId,
          'deposit_id': depositId,
          'stage': verified ? 'verified' : 'unverified',
          'updated_at': updatedAt.toUtc().toIso8601String(),
        };

  /// Null for anything malformed.
  static PaymentRequestAttempt? tryParse(Object? json) {
    if (json is! Map) return null;
    final requestId = json['request_id'];
    final depositId = json['deposit_id'];
    final stage = json['stage'];
    final updatedAt = json['updated_at'] is String
        ? DateTime.tryParse(json['updated_at'] as String)
        : null;
    if (stage == 'card') {
      final cardPaymentId = json['card_payment_id'];
      if (requestId is! int ||
          cardPaymentId is! String ||
          cardPaymentId.isEmpty ||
          updatedAt == null) {
        return null;
      }
      return PaymentRequestAttempt.card(
        requestId: requestId,
        cardPaymentId: cardPaymentId,
        updatedAt: updatedAt,
      );
    }
    if (requestId is! int ||
        depositId is! String ||
        depositId.isEmpty ||
        (stage != 'verified' && stage != 'unverified') ||
        updatedAt == null) {
      return null;
    }
    return PaymentRequestAttempt(
      requestId: requestId,
      depositId: depositId,
      verified: stage == 'verified',
      updatedAt: updatedAt,
    );
  }
}

/// Per-customer persistence of unresolved [PaymentRequestAttempt]s.
abstract class PaymentRequestAttemptStore {
  List<PaymentRequestAttempt> load(String ownerId);

  Future<void> save(String ownerId, List<PaymentRequestAttempt> attempts);

  Future<void> clear(String ownerId);
}

/// [PaymentRequestAttemptStore] on the app's existing [LocalKeyStorage]
/// (SharedPreferences), one key per customer so attempts never cross
/// accounts. Logout also wipes it via `LocalKeyStorage.clearData`.
class LocalPaymentRequestAttemptStore implements PaymentRequestAttemptStore {
  const LocalPaymentRequestAttemptStore();

  static String keyFor(String ownerId) => 'payment_request_attempts.v1.$ownerId';

  LocalKeyStorage? get _storage => getIt.isRegistered<LocalKeyStorage>()
      ? getIt<LocalKeyStorage>()
      : null;

  @override
  List<PaymentRequestAttempt> load(String ownerId) {
    final raw = _storage?.getString(keyFor(ownerId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(PaymentRequestAttempt.tryParse)
          .whereType<PaymentRequestAttempt>()
          .toList();
    } catch (e) {
      log('Discarding unreadable payment attempts: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<void> save(String ownerId, List<PaymentRequestAttempt> attempts) async {
    await _storage?.storeString(
      key: keyFor(ownerId),
      value: jsonEncode(attempts.map((a) => a.toJson()).toList()),
    );
  }

  @override
  Future<void> clear(String ownerId) => save(ownerId, const []);
}
