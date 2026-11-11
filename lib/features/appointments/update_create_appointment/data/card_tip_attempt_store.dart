import 'dart:convert';
import 'dart:developer';

import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

/// The minimum needed to recover an unresolved card tip after the app was
/// closed: which booking, which Peach deposit (what Laravel verifies), the
/// checkout id and transaction reference when known, when it started and
/// the last status seen. No card data, tokens, URLs or personal details.
class CardTipAttempt {
  const CardTipAttempt({
    required this.appointmentId,
    required this.depositId,
    required this.createdAt,
    this.checkoutId,
    this.reference,
    this.amount,
    this.lastStatus = statusCheckoutStarted,
  });

  /// Checkout handed out; the customer may be paying.
  static const statusCheckoutStarted = 'checkout_started';

  /// `tip.status: pending` (or an unrecognised status): not decided yet.
  static const statusPending = 'pending';

  /// No verdict from Laravel (503, network, timeout).
  static const statusUnknown = 'unknown';

  final String appointmentId;
  final String depositId;
  final String? checkoutId;

  /// Laravel's `transaction_reference`, once a status check has returned it.
  final String? reference;

  /// The tip amount in rands, for the customer-facing outcome.
  final double? amount;
  final DateTime createdAt;
  final String lastStatus;

  CardTipAttempt copyWith({String? lastStatus, String? reference}) =>
      CardTipAttempt(
        appointmentId: appointmentId,
        depositId: depositId,
        checkoutId: checkoutId,
        reference: reference ?? this.reference,
        amount: amount,
        createdAt: createdAt,
        lastStatus: lastStatus ?? this.lastStatus,
      );

  Map<String, dynamic> toJson(String ownerId) => {
        'owner_id': ownerId,
        'appointment_id': appointmentId,
        'deposit_id': depositId,
        if (checkoutId != null) 'checkout_id': checkoutId,
        if (reference != null) 'reference': reference,
        if (amount != null) 'amount': amount,
        'created_at': createdAt.toUtc().toIso8601String(),
        'last_status': lastStatus,
      };

  /// Null for anything malformed, or recorded for another customer.
  static CardTipAttempt? tryParse(Object? json, {required String ownerId}) {
    if (json is! Map) return null;
    final owner = json['owner_id'];
    final appointmentId = json['appointment_id'];
    final depositId = json['deposit_id'];
    final createdAt = json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null;
    final lastStatus = json['last_status'];
    final amount = json['amount'];
    if (owner != ownerId ||
        appointmentId is! String ||
        appointmentId.isEmpty ||
        depositId is! String ||
        depositId.isEmpty ||
        createdAt == null ||
        lastStatus is! String) {
      return null;
    }
    return CardTipAttempt(
      appointmentId: appointmentId,
      depositId: depositId,
      checkoutId: json['checkout_id'] is String
          ? json['checkout_id'] as String
          : null,
      reference:
          json['reference'] is String ? json['reference'] as String : null,
      amount: amount is num ? amount.toDouble() : null,
      createdAt: createdAt,
      lastStatus: lastStatus,
    );
  }
}

/// Per-customer persistence of unresolved [CardTipAttempt]s.
abstract class CardTipAttemptStore {
  List<CardTipAttempt> load(String ownerId);

  Future<void> save(String ownerId, List<CardTipAttempt> attempts);
}

/// [CardTipAttemptStore] on the app's [LocalKeyStorage] (SharedPreferences),
/// one key per customer — the convention of `LocalPaymentRequestAttemptStore`.
/// Kept through logout (`LocalKeyStorage.clearData`) so a customer who signs
/// back in still sees what became of a card tip; another customer's key is
/// never read.
class LocalCardTipAttemptStore implements CardTipAttemptStore {
  const LocalCardTipAttemptStore();

  static String keyFor(String ownerId) =>
      '${SharedPrefKey.cardTipAttemptsPrefix}$ownerId';

  LocalKeyStorage? get _storage => getIt.isRegistered<LocalKeyStorage>()
      ? getIt<LocalKeyStorage>()
      : null;

  @override
  List<CardTipAttempt> load(String ownerId) {
    final raw = _storage?.getString(keyFor(ownerId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((json) => CardTipAttempt.tryParse(json, ownerId: ownerId))
          .whereType<CardTipAttempt>()
          .toList();
    } catch (e) {
      log('Discarding unreadable card tip attempts: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<void> save(String ownerId, List<CardTipAttempt> attempts) async {
    final storage = _storage;
    if (storage == null) return;
    if (attempts.isEmpty) {
      await storage.removeKey(keyFor(ownerId));
      return;
    }
    await storage.storeString(
      key: keyFor(ownerId),
      value: jsonEncode([for (final a in attempts) a.toJson(ownerId)]),
    );
  }
}

/// In-memory [CardTipAttemptStore] (tests, or no storage available).
class MemoryCardTipAttemptStore implements CardTipAttemptStore {
  final Map<String, List<CardTipAttempt>> saved = {};

  @override
  List<CardTipAttempt> load(String ownerId) => saved[ownerId] ?? const [];

  @override
  Future<void> save(String ownerId, List<CardTipAttempt> attempts) async {
    if (attempts.isEmpty) {
      saved.remove(ownerId);
    } else {
      saved[ownerId] = [...attempts];
    }
  }
}
