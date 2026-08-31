import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';

void main() {
  test('parses appointment checkout data from the Laravel Peach contract', () {
    final data = CheckoutPaymentData.fromJson({
      'appointment_id': '456',
      'status': 'processing',
      'payment': {
        'status': true,
        'processor': 'peachpayment',
        'deposit_id': 789,
        'checkoutId': 'checkout-id',
        'redirectUrl': 'https://secure.peachpayments.com/checkout',
      },
    });

    expect(data.appointmentId, '456');
    expect(data.depositId, '789');
    expect(data.canOpenCheckout, isTrue);
  });

  test('parses wallet checkout data and nullable appointment IDs', () {
    final data = CheckoutPaymentData.fromJson({
      'status': true,
      'processor': 'peachpayment',
      'deposit_id': 789,
      'checkoutId': 'checkout-id',
      'redirectUrl': 'https://secure.peachpayments.com/checkout',
    });

    expect(data.appointmentId, isNull);
    expect(data.canOpenCheckout, isTrue);
  });

  test('only settled successful reconciliation is successful', () {
    final successful = PaymentReconciliation.fromJson({
      'deposit_id': '789',
      'purpose': 'appointment',
      'status': 'successful',
      'settled': true,
      'appointment_id': '456',
      'currency': 'ZAR',
    });
    final pending = PaymentReconciliation.fromJson({
      'deposit_id': '789',
      'status': 'pending',
      'settled': false,
    });

    expect(successful.isSuccessful, isTrue);
    expect(pending.isSuccessful, isFalse);
    expect(pending.isPending, isTrue);
  });
}
