import 'package:flutter/foundation.dart';

/// Temporary, concise logging for the Peach Payments flows.
///
/// Only high-level milestones and non-sensitive identifiers are logged.
/// Never pass tokens, authorization headers, Peach client credentials,
/// webhook secrets, card data or raw HTTP payloads to this helper.
void peachLog(String message) {
  if (!kDebugMode) return;
  debugPrint('[PEACH] $message');
}

/// Reduces a hosted-checkout redirect URL to `scheme://host/path` so the
/// destination is visible without leaking query-string credentials/tokens.
String redactedCheckoutUrl(String? url) {
  if (url == null || url.isEmpty) return 'none';
  final uri = Uri.tryParse(url);
  if (uri == null) return 'unparseable';
  final path = uri.path.isEmpty ? '' : uri.path;
  final query = uri.hasQuery ? ' (+query redacted)' : '';
  return '${uri.scheme}://${uri.host}$path$query';
}
