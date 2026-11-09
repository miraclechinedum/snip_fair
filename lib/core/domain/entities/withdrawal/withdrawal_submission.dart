import 'package:equatable/equatable.dart';

/// Laravel's answer to an accepted `POST /wallet/withdraw`: HTTP 204 with no
/// body. It means the request was recorded and the balance reserved — not
/// that the bank transfer has happened; the payout runs afterwards.
class WithdrawalSubmission extends Equatable {
  const WithdrawalSubmission({required this.amount, this.replayed = false});

  final double amount;

  /// `Idempotent-Replayed: true`: the backend had already accepted this exact
  /// request (same key, amount and method), so nothing new was created.
  final bool replayed;

  @override
  List<Object?> get props => [amount, replayed];
}
