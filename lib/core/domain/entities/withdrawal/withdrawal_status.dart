import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';

/// Where a withdrawal stands, as far as `GET /wallet/transactions` shows it.
///
/// The API exposes no payout state of its own (`payout_state`, manual review,
/// Peach status are all backend-only), so this is read from the `withdraw`
/// row's `status` alone, using Laravel's mapping:
/// - `pending`    → recorded, payout not yet with the bank (queued, being
///   submitted, or held for manual handling);
/// - `processing` → with the payout provider, outcome not final;
/// - `completed`  → sent to the stylist's bank by the payout provider (the
///   bank may take some time to credit it), shown as [withdrawalSentLabel];
/// - `failed`     → not paid; the amount comes back as a separate `refund`
///   row referenced `WDR-{id}-REFUND`;
/// - `reversed`   → paid, then reversed by the bank;
/// - `approved` / `declined` → rows from before the payout ledger.
enum WithdrawalStatus {
  submitted,
  processing,
  successful,
  failed,
  reversed,
  approved,
  declined,
}

/// `reference` is not a stable identifier (the backend rewrites it, e.g. to
/// `WDR-{id}-PEACHPAYOUTID-…` and back) and is only used, best-effort, to
/// pair a refund with its withdrawal. Rows are identified by `id`.
///
/// `WDR-{withdrawalId}`, optionally followed by `-…`.
final _withdrawalReference = RegExp(r'^WDR-(\d+)(?:-|$)');

/// `WDR-{withdrawalId}-REFUND`: the wallet credit for a failed withdrawal.
final _withdrawalRefundReference = RegExp(r'^WDR-(\d+)-REFUND$');

extension WithdrawalTransactionX on UserTransaction {
  bool get isWithdrawal => type == 'withdraw';

  /// A `refund` row: money returned to the wallet (for a stylist, the
  /// credit for a failed or rejected withdrawal).
  bool get isRefund => type == 'refund';

  /// A refund whose reference ties it to a withdrawal. Best-effort.
  bool get isWithdrawalRefund =>
      isRefund && _withdrawalRefundReference.hasMatch(reference?.trim() ?? '');

  /// The backend withdrawal id carried in [reference], if any. Best-effort:
  /// only used to pair refunds with withdrawals.
  String? get withdrawalId {
    final ref = reference?.trim() ?? '';
    return (_withdrawalRefundReference.firstMatch(ref) ??
            _withdrawalReference.firstMatch(ref))
        ?.group(1);
  }

  /// Null for non-withdrawal rows and for status strings the API does not
  /// document, which are then shown as sent.
  WithdrawalStatus? get withdrawalStatus {
    if (!isWithdrawal) return null;
    return switch (status?.trim().toLowerCase()) {
      'pending' => WithdrawalStatus.submitted,
      'processing' => WithdrawalStatus.processing,
      'completed' => WithdrawalStatus.successful,
      'failed' => WithdrawalStatus.failed,
      'reversed' => WithdrawalStatus.reversed,
      'approved' => WithdrawalStatus.approved,
      'declined' => WithdrawalStatus.declined,
      _ => null,
    };
  }
}

/// Badge for a withdrawal the payout provider has paid out: sent, which does
/// not mean the bank has credited it yet.
const withdrawalSentLabel = 'Sent to bank';

/// Status badge text for a Transactions row. [refundedWithdrawalIds] are the
/// withdrawal ids whose `WDR-{id}-REFUND` row is in the loaded list, so a
/// failed withdrawal is only called refunded when the refund is visible.
String transactionStatusLabel(
  UserTransaction transaction, {
  Set<String> refundedWithdrawalIds = const {},
}) {
  if (transaction.isRefund) {
    return transaction.status?.trim().toLowerCase() == 'completed'
        ? 'Refunded'
        : transaction.status ?? 'N/A';
  }
  return switch (transaction.withdrawalStatus) {
    WithdrawalStatus.submitted => 'Submitted',
    WithdrawalStatus.processing => 'Processing',
    WithdrawalStatus.successful => withdrawalSentLabel,
    WithdrawalStatus.failed =>
      refundedWithdrawalIds.contains(transaction.withdrawalId)
          ? 'Failed · Refunded'
          : 'Failed',
    WithdrawalStatus.reversed => 'Reversed',
    WithdrawalStatus.approved => withdrawalSentLabel,
    WithdrawalStatus.declined => 'Declined',
    null => transaction.status ?? 'N/A',
  };
}

/// Ids of the withdrawals refunded by rows in [transactions].
Set<String> refundedWithdrawalIds(Iterable<UserTransaction> transactions) => {
      for (final t in transactions)
        if (t.isWithdrawalRefund && t.withdrawalId != null) t.withdrawalId!,
    };
