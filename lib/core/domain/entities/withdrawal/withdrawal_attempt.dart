import 'package:equatable/equatable.dart';

/// Where a [WithdrawalAttempt] stands from the app's point of view.
enum WithdrawalAttemptStatus {
  /// Saved and about to be (or being) sent. Restored after an app restart
  /// as [unknown]: the request may have reached the backend.
  sending,

  /// The last send got no answer (timeout, lost connection, 5xx), or a
  /// retry of such a send was refused before Laravel's replay check. It may
  /// or may not have been recorded; only the same key may be resent.
  unknown,

  /// The first send was refused outright (400/403/422/429/503). Laravel did
  /// not store the key, so nothing was recorded; the key is kept for an
  /// identical resend.
  rejected,

  /// 409: the key is on record for different details. Resolved by reloading
  /// the balance and history, then dropping the attempt.
  conflict,
}

/// One withdrawal the stylist asked for, bound to the `Idempotency-Key` that
/// identifies it to `POST /wallet/withdraw`.
///
/// Laravel stores the key per stylist, once a request is recorded, with a
/// fingerprint of the amount (in cents) and payout method. Resending the same
/// key with the same details is a safe replay (no second deduction); the same
/// key with different details is rejected with 409. So a key is only ever
/// resent for the exact details it was created for — see [matches].
class WithdrawalAttempt extends Equatable {
  const WithdrawalAttempt({
    required this.idempotencyKey,
    required this.paymentMethodId,
    required this.amount,
    this.status = WithdrawalAttemptStatus.sending,
  });

  final String idempotencyKey;
  final String paymentMethodId;
  final double amount;
  final WithdrawalAttemptStatus status;

  /// Amount in cents, the precision Laravel fingerprints on (`"100.00"` and
  /// `100` are the same request).
  static int toCents(double amount) => (amount * 100).round();

  /// The backend may have recorded this request (or, for a 409 conflict, an
  /// earlier one): no different withdrawal may be started until it is
  /// resolved.
  bool get isUnresolved => status != WithdrawalAttemptStatus.rejected;

  /// The outcome of a send is unknown: the stylist is offered a retry.
  bool get outcomeUnknown =>
      status == WithdrawalAttemptStatus.unknown ||
      status == WithdrawalAttemptStatus.sending;

  /// Whether a submission of [amount] to [paymentMethodId] is a retry of this
  /// attempt (and must reuse its key) rather than a new withdrawal.
  bool matches(String paymentMethodId, double amount) =>
      this.paymentMethodId == paymentMethodId &&
      toCents(this.amount) == toCents(amount);

  WithdrawalAttempt withStatus(WithdrawalAttemptStatus status) =>
      WithdrawalAttempt(
        idempotencyKey: idempotencyKey,
        paymentMethodId: paymentMethodId,
        amount: amount,
        status: status,
      );

  @override
  List<Object?> get props => [idempotencyKey, paymentMethodId, amount, status];

  /// The key is left out: state changes are logged by the app's
  /// `BlocObserver`.
  @override
  String toString() => 'WithdrawalAttempt(method: $paymentMethodId, '
      'amount: $amount, status: ${status.name})';
}
