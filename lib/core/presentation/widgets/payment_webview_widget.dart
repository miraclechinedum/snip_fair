import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';

/// Laravel's shopper-result endpoint. Peach redirects the browser here after
/// the shopper finishes (or abandons) checkout. Reaching it means "checkout is
/// over", NOT "payment succeeded" — callers must still reconcile with Laravel.
const _shopperResultPath = '/payment/return/peach';

/// A provider-neutral hosted-checkout WebView.
///
/// Closing or navigating away from checkout is never payment confirmation.
/// Callers must reconcile the attempt with Laravel after this widget returns.
class PaymentWebViewWidget extends StatefulWidget {
  const PaymentWebViewWidget({
    required this.paymentData,
    required this.onResult,
    super.key,
    this.title = 'Payment',
    this.showAppBar = true,
  });

  /// Safe checkout session data returned by Laravel.
  final CheckoutPaymentData paymentData;

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

  /// Guards against reporting a result twice (e.g. the shopper-result page
  /// finishing while the user also taps close).
  bool _hasReported = false;

  static bool _isShopperResult(String url) =>
      Uri.tryParse(url)?.path.contains(_shopperResultPath) ?? false;

  /// Single exit point. [success] is only ever `false` here: this widget never
  /// claims a payment succeeded — the caller reconciles with Laravel.
  void _report({required bool success}) {
    if (_hasReported) return;
    _hasReported = true;
    widget.onResult(success);
  }

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
            if (!mounted) return;
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Close once Laravel's return page has actually loaded, so its
            // handler has run. Closing is not payment proof — the caller
            // reconciles the deposit right after this widget returns.
            if (_isShopperResult(url)) {
              peachLog('Shopper-result page loaded, closing checkout');
              _report(success: false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isShopperResult(request.url)) {
              peachLog('Shopper-result redirect reached (not payment proof)');
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    final redirectUrl = widget.paymentData.redirectUrl;
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(redirectUrl));
    } else {
      // Handle error - no payment URL provided
      peachLog('Hosted checkout has no redirect URL, closing');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _report(success: false);
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
                onPressed: () {
                  peachLog('Hosted checkout closed by user');
                  _report(success: false);
                },
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
  required CheckoutPaymentData paymentData,
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
