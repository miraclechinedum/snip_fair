import 'package:flutter/material.dart';

import '../../../core/domain/entities/payfast_payment_data/payfast_payment_data.dart';
import '../../../core/presentation/widgets/payment_webview_widget.dart';

/// Example of how to use the PaymentWebViewWidget
class PaymentExampleUsage extends StatelessWidget {
  const PaymentExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showPaymentDialog(context),
          child: const Text('Start Payment'),
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    // Example PayFast payment data
    final paymentData = PayfastPaymentData(
      paymentUrl: 'https://sandbox.payfast.co.za/eng/process',
      successUrl: 'https://yourapp.com/payment/success',
      cancelUrl: 'https://yourapp.com/payment/cancel',
      amount: 10000, // Amount in cents
      payfastUuid: 'example-uuid',
    );

    // Show payment widget as a modal dialog
    final result = await showPaymentWebView(
      context: context,
      paymentData: paymentData,
      title: 'Complete Payment',
      isDismissible: false,
    );

    if (context.mounted) {
      // Handle the payment result
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled or failed!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Alternative usage: Navigate to a full screen payment page
  // ignore: unused_element
  void _navigateToPaymentScreen(BuildContext context) {
    final paymentData = PayfastPaymentData(
      paymentUrl: 'https://sandbox.payfast.co.za/eng/process',
      successUrl: 'https://yourapp.com/payment/success',
      cancelUrl: 'https://yourapp.com/payment/cancel',
      amount: 10000,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute<bool>(
        builder: (context) => PaymentWebViewWidget(
          paymentData: paymentData,
          title: 'Payment',
          onResult: (success) {
            Navigator.of(context).pop(success);
          },
        ),
      ),
    )
        .then((result) {
      if (context.mounted && result != null) {
        // Handle payment result
        final message = result ? 'Payment successful!' : 'Payment cancelled!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }
}
