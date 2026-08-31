import 'dart:developer';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';

/// Unified analytics wrapper — one call dispatches to Firebase Analytics (GA4)
/// and Meta App Events. GA4 standard event names on our public surface;
/// internally each method routes to the platform's typed method where
/// available so the backing event names match Meta's Standard Events and
/// reconcile with the web Pixel.
///
/// Currency is resolved dynamically per call:
///   1) explicit `currency` argument, if provided
///   2) server-configured `platform_settings.currency_code`
///   3) `'ZAR'` fallback
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _fb = FacebookAppEvents();
  final _fa = FirebaseAnalytics.instance;

  /// Called once from bootstrap. Meta SDK auto-inits from Info.plist /
  /// AndroidManifest; Firebase Analytics auto-inits from the existing Firebase
  /// setup. We only need to seed the advertiser-tracking flag.
  Future<void> init() async {
    if (Platform.isAndroid) {
      // Android has no ATT; default advertiser tracking on.
      await _fb.setAdvertiserIdCollectionEnabled(true);
    } else {
      // iOS: default OFF until ATT is granted post-onboarding.
      await _fb.setAdvertiserIdCollectionEnabled(false);
    }
  }

  // ---------------------------------------------------------------------------
  // ATT — App Tracking Transparency (iOS 14.5+)
  // ---------------------------------------------------------------------------

  /// Shows the iOS ATT prompt if the user hasn't answered yet. Enables Meta
  /// advertiser tracking iff granted. No-op on Android. Safe to call more
  /// than once — iOS only shows the prompt on the first `notDetermined`; every
  /// subsequent call becomes a no-op display-wise, but we still sync the
  /// advertiser flag with the current authorization status.
  Future<void> requestTrackingConsentIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final current = await AppTrackingTransparency.trackingAuthorizationStatus;
      final finalStatus = current == TrackingStatus.notDetermined
          ? await AppTrackingTransparency.requestTrackingAuthorization()
          : current;
      final granted = finalStatus == TrackingStatus.authorized;
      await _fb.setAdvertiserIdCollectionEnabled(granted);
      log('ATT status=$finalStatus, tracking=$granted', name: 'Analytics');
    } catch (e, s) {
      log('ATT flow error: $e', name: 'Analytics', stackTrace: s);
    }
  }

  // ---------------------------------------------------------------------------
  // Funnel events — GA4 name / Meta Standard Event
  // ---------------------------------------------------------------------------

  /// GA4 `sign_up` · Meta `CompleteRegistration`.
  Future<void> logSignUp({required String method}) async {
    await _fa.logSignUp(signUpMethod: method);
    await _fb.logCompletedRegistration(registrationMethod: method);
  }

  /// GA4 `login` · Meta custom `login`.
  Future<void> logLogin({required String method}) async {
    await _fa.logLogin(loginMethod: method);
    await _fb.logEvent(name: 'login', parameters: {'method': method});
  }

  /// GA4 `search` · Meta `Search` (fb_mobile_search).
  Future<void> logSearch({required String query}) async {
    if (query.trim().isEmpty) return;
    await _fa.logSearch(searchTerm: query);
    // No typed helper in facebook_app_events v0.30.1 for Search; use the
    // standard event name directly.
    await _fb.logEvent(
      name: 'fb_mobile_search',
      parameters: {'fb_search_string': query},
    );
  }

  /// GA4 `view_item` · Meta `ViewContent`.
  Future<void> logViewStylist({
    required String stylistId,
    String? stylistName,
    num? price,
    String? currency,
  }) async {
    final priceD = price?.toDouble();
    final cur = _resolveCurrency(currency);
    await _fa.logViewItem(
      currency: cur,
      value: priceD,
      items: [
        AnalyticsEventItem(
          itemId: stylistId,
          itemName: stylistName,
          itemCategory: 'stylist',
          price: priceD,
        ),
      ],
    );
    await _fb.logViewContent(
      id: stylistId,
      type: 'stylist',
      price: priceD,
      currency: cur,
    );
  }

  /// GA4 `begin_checkout` · Meta `InitiateCheckout`.
  Future<void> logInitiateCheckout({
    required num amount,
    String? currency,
    int itemCount = 1,
  }) async {
    final amountD = amount.toDouble();
    final cur = _resolveCurrency(currency);
    await _fa.logBeginCheckout(value: amountD, currency: cur);
    await _fb.logInitiatedCheckout(
      totalPrice: amountD,
      currency: cur,
      numItems: itemCount,
    );
  }

  /// GA4 `purchase` · Meta `Purchase`.
  Future<void> logPurchase({
    required num amount,
    required String transactionId,
    String? currency,
  }) async {
    final amountD = amount.toDouble();
    final cur = _resolveCurrency(currency);
    await _fa.logPurchase(
      value: amountD,
      currency: cur,
      transactionId: transactionId,
    );
    await _fb.logPurchase(
      amount: amountD,
      currency: cur,
      parameters: {'transaction_id': transactionId},
    );
  }

  /// Escape hatch for one-off custom events.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _fa.logEvent(name: name, parameters: parameters);
    await _fb.logEvent(name: name, parameters: parameters);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Resolves the currency in priority order: explicit arg → server-configured
  /// `platform_settings.currency_code` → `'ZAR'` fallback.
  String _resolveCurrency(String? explicit) {
    if (explicit != null && explicit.trim().isNotEmpty) return explicit;
    try {
      if (getIt.isRegistered<AppCubit>()) {
        final code = getIt<AppCubit>().state.platformSettings?.currencyCode;
        if (code != null && code.trim().isNotEmpty) return code;
      }
    } catch (_) {
      // Fall through to default — bootstrap edge case where AppCubit isn't
      // registered yet.
    }
    return 'ZAR';
  }
}
