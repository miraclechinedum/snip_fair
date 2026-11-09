import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_status.dart';

UserTransaction _tx(String type, String? status, String? reference) =>
    UserTransaction(type: type, status: status, reference: reference);

void main() {
  test('withdraw rows map every status Laravel can write', () {
    expect(
      {
        for (final s in [
          'pending',
          'processing',
          'completed',
          'failed',
          'reversed',
          'approved',
          'declined',
        ])
          s: _tx('withdraw', s, 'WDR-1').withdrawalStatus,
      },
      {
        'pending': WithdrawalStatus.submitted,
        'processing': WithdrawalStatus.processing,
        'completed': WithdrawalStatus.successful,
        'failed': WithdrawalStatus.failed,
        'reversed': WithdrawalStatus.reversed,
        'approved': WithdrawalStatus.approved,
        'declined': WithdrawalStatus.declined,
      },
    );
  });

  test('an undocumented status is shown as sent, not guessed', () {
    final tx = _tx('withdraw', 'manual_review', 'WDR-1');
    expect(tx.withdrawalStatus, isNull);
    expect(transactionStatusLabel(tx), 'manual_review');
  });

  test('a paid withdrawal is shown as sent to the bank, not received', () {
    expect(withdrawalSentLabel, 'Sent to bank');
    expect(
      transactionStatusLabel(_tx('withdraw', 'completed', 'WDR-1')),
      'Sent to bank',
    );
    // Rows from before the payout ledger.
    expect(
      transactionStatusLabel(_tx('withdraw', 'approved', 'WDR-1')),
      'Sent to bank',
    );
  });

  test('the other withdrawal statuses stay distinct', () {
    final labels = {
      for (final s in [
        'pending',
        'processing',
        'completed',
        'failed',
        'reversed',
        'declined',
      ])
        s: transactionStatusLabel(_tx('withdraw', s, 'WDR-1')),
    };
    expect(labels, {
      'pending': 'Submitted',
      'processing': 'Processing',
      'completed': 'Sent to bank',
      'failed': 'Failed',
      'reversed': 'Reversed',
      'declined': 'Declined',
    });
  });

  test('non-withdrawal rows keep their raw status', () {
    expect(transactionStatusLabel(_tx('earning', 'completed', 'BK-1')),
        'completed');
    expect(transactionStatusLabel(_tx('topup', null, null)), 'N/A');
  });

  test('withdrawal ids are read from every reference form', () {
    expect(_tx('withdraw', 'pending', 'WDR-42').withdrawalId, '42');
    expect(
      _tx('withdraw', 'processing', 'WDR-42-PEACHPAYOUTID-9f1c').withdrawalId,
      '42',
    );
    expect(_tx('refund', 'completed', 'WDR-42-REFUND').withdrawalId, '42');
    expect(_tx('withdraw', 'pending', 'WD-20260819-ABC').withdrawalId, isNull);
  });

  test('only WDR-{id}-REFUND refund rows are withdrawal refunds', () {
    expect(
        _tx('refund', 'completed', 'WDR-42-REFUND').isWithdrawalRefund, isTrue);
    expect(_tx('refund', 'completed', 'RF-1').isWithdrawalRefund, isFalse);
    expect(
        _tx('withdraw', 'failed', 'WDR-42-REFUND').isWithdrawalRefund, isFalse);
  });

  test('every completed refund is labelled Refunded, paired or not', () {
    expect(transactionStatusLabel(_tx('refund', 'completed', 'WDR-42-REFUND')),
        'Refunded');
    expect(
        transactionStatusLabel(_tx('refund', 'completed', 'RF-1')), 'Refunded');
    expect(transactionStatusLabel(_tx('refund', 'pending', null)), 'pending');
  });

  test('a failed withdrawal is called refunded only when the refund is seen',
      () {
    final failed = _tx('withdraw', 'failed', 'WDR-42');
    final refund = _tx('refund', 'completed', 'WDR-42-REFUND');
    expect(transactionStatusLabel(failed), 'Failed');
    expect(
      transactionStatusLabel(
        failed,
        refundedWithdrawalIds: refundedWithdrawalIds([failed, refund]),
      ),
      'Failed · Refunded',
    );
  });
}
