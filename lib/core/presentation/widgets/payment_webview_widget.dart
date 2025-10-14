import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/payfast_payment_data/payfast_payment_data.dart';

/// A widget that displays a WebView for PayFast payment processing.
///
/// This widget loads the payment URL in a WebView and listens for redirections
/// to determine payment success or cancellation.
///
/// Returns `true` if payment is successful (redirects to successUrl)
/// Returns `false` if payment is cancelled (redirects to cancelUrl)
class PaymentWebViewWidget extends StatefulWidget {
  const PaymentWebViewWidget({
    required this.paymentData,
    required this.onResult,
    super.key,
    this.title = 'Payment',
    this.showAppBar = true,
  });

  /// The PayFast payment data containing URLs and payment information
  final PayfastPaymentData paymentData;

  /// Callback function called when payment result is determined
  /// - `true` for successful payment
  /// - `false` for cancelled payment
  final void Function(bool success) onResult;

  /// Title to display in the app bar
  final String title;

  /// Whether to show the app bar
  final bool showAppBar;

  @override
  State<PaymentWebViewWidget> createState() => _PaymentWebViewWidgetState();
}

class _PaymentWebViewWidgetState extends State<PaymentWebViewWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    // Load the payment URL
    final paymentUrl = widget.paymentData.paymentUrl;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(paymentUrl));
    } else {
      // Handle error - no payment URL provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onResult(false);
      });
    }
  }

  void _handleUrlChange(String url) {
    final successUrl = widget.paymentData.successUrl;
    final cancelUrl = widget.paymentData.cancelUrl;

    if (successUrl != null && url.contains(successUrl)) {
      // Payment successful
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onResult(true);
      });
    } else if (cancelUrl != null && url.contains(cancelUrl)) {
      // Payment cancelled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onResult(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => widget.onResult(false),
              ),
              actions: [
                if (_isLoading)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.reload(),
                  ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

/// A convenience method to show the PaymentWebViewWidget as a modal.
///
/// Returns a Future<bool?> where:
/// - `true` indicates successful payment
/// - `false` indicates cancelled payment
/// - `null` indicates the modal was dismissed without completion
Future<bool?> showPaymentWebView({
  required BuildContext context,
  required PayfastPaymentData paymentData,
  String title = 'Payment',
  bool isDismissible = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => isDismissible,
        child: PaymentWebViewWidget(
          paymentData: paymentData,
          title: title,
          onResult: (success) {
            Navigator.of(context).pop(success);
          },
        ),
      );
    },
  );
}
