import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';

/// Shaped like Laravel's `/api/platform-settings`: `WebsiteConfiguration`
/// casts numerics to float (PHP encodes 30.0 as `30.0`), `updated_by` is an
/// integer admin id, and the controller appends keys the app ignores.
Map<String, dynamic> _laravelPayload() => {
      'id': 1,
      'terms': '<p>Terms</p>',
      'privacy_policy': '<p>Privacy</p>',
      'cookies': null,
      'email_verification': true,
      'two_factor_auth': false,
      'min_booking_amount': 30.0,
      'max_booking_amount': 3000.0,
      'allow_registration_stylists': true,
      'allow_registration_customers': true,
      'maintenance_mode': false,
      'maintenance_message': null,
      'email_notifications': true,
      'push_notifications': true,
      'system_alerts': true,
      'payment_alerts': true,
      'content_moderation': true,
      'appointment_reschedule_threshold': 3.0,
      'appointment_reschedule_percentage': 10.0,
      'appointment_canceling_threshold': 24.0,
      'appointment_canceling_percentage': 50.0,
      'updated_by': 2,
      'created_at': '2025-08-05T11:07:18.000000Z',
      'updated_at': '2026-10-01T09:00:00.000000Z',
      'commission_rate': 30.0,
      'currency_symbol': 'R',
      'currency_code': 'ZAR',
      'featured_media': ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg'],
      'professional_stylists': 120.0,
      'happy_customers': 4500.0,
      'services_completed': 9800.0,
      'customer_satisfaction': 4.8,
      'disable_booking_message': '',
      'default_collection_processor': 'payfast',
      'default_payout_processor': 'peachpayment',
      'api_payment_made': true,
      'portfolio_price_filters': [
        {'label': 'Any', 'max': null, 'min': 0, 'is_default': true},
        {'label': 'Below R500', 'max': 500, 'min': 0, 'is_default': false},
      ],
    };

void main() {
  group('PlatformSettings.fromJson', () {
    test('parses the real Laravel response without throwing', () {
      final settings = PlatformSettings.fromJson(_laravelPayload());

      expect(settings.id, 1);
      expect(settings.updatedBy, 2);
      expect(settings.minBookingAmount, 30.0);
      expect(settings.maxBookingAmount, 3000.0);
      expect(settings.appointmentRescheduleThreshold, 3);
      expect(settings.appointmentReschedulePercentage, 10.0);
      expect(settings.appointmentCancelingThreshold, 24);
      expect(settings.appointmentCancelingPercentage, 50.0);
      expect(settings.commissionRate, 30.0);
      expect(settings.professionalStylists, 120);
      expect(settings.happyCustomers, 4500);
      expect(settings.servicesCompleted, 9800);
      expect(settings.customerSatisfaction, 4.8);
      expect(settings.allowRegistrationCustomers, isTrue);
      expect(settings.maintenanceMode, isFalse);
      expect(settings.cookies, isNull);
      expect(settings.currencyCode, 'ZAR');
      expect(settings.createdAt, '2025-08-05T11:07:18.000000Z');
      expect(settings.featuredMedia, hasLength(2));
      expect(settings.portfolioPriceFilters, hasLength(2));
      expect(settings.portfolioPriceFilters!.first.max, isNull);
      expect(settings.portfolioPriceFilters!.first.isDefault, isTrue);
      expect(settings.portfolioPriceFilters!.last.max, 500);
    });

    test('accepts integer numerics as sent by plain JSON tools', () {
      final settings = PlatformSettings.fromJson({
        'min_booking_amount': 30,
        'max_booking_amount': 3000,
        'appointment_reschedule_threshold': 3,
        'appointment_reschedule_percentage': 10,
        'appointment_canceling_threshold': 24,
        'appointment_canceling_percentage': 50,
        'commission_rate': 30,
        'customer_satisfaction': 5,
      });

      expect(settings.minBookingAmount, 30.0);
      expect(settings.maxBookingAmount, 3000.0);
      expect(settings.appointmentRescheduleThreshold, 3);
      expect(settings.appointmentReschedulePercentage, 10.0);
      expect(settings.appointmentCancelingThreshold, 24);
      expect(settings.appointmentCancelingPercentage, 50.0);
      expect(settings.commissionRate, 30.0);
      expect(settings.customerSatisfaction, 5.0);
    });

    test('keeps fractional money and percentages', () {
      final settings = PlatformSettings.fromJson({
        'min_booking_amount': 30.5,
        'appointment_canceling_percentage': 12.5,
        'commission_rate': 17.25,
      });

      expect(settings.minBookingAmount, 30.5);
      expect(settings.appointmentCancelingPercentage, 12.5);
      expect(settings.commissionRate, 17.25);
    });

    test('accepts legacy string-encoded values', () {
      final settings = PlatformSettings.fromJson({
        'id': '1',
        'updated_by': '2',
        'min_booking_amount': '30.00',
        'max_booking_amount': '3000',
        'appointment_canceling_threshold': '24',
        'appointment_reschedule_threshold': '3.0',
        'happy_customers': ' 4500 ',
        'maintenance_mode': 0,
        'allow_registration_stylists': '1',
        'email_verification': 'false',
        'portfolio_price_filters': [
          {'label': 'R500 - R600', 'max': '600', 'min': 500.0},
        ],
      });

      expect(settings.id, 1);
      expect(settings.updatedBy, 2);
      expect(settings.minBookingAmount, 30.0);
      expect(settings.maxBookingAmount, 3000.0);
      expect(settings.appointmentCancelingThreshold, 24);
      expect(settings.appointmentRescheduleThreshold, 3);
      expect(settings.happyCustomers, 4500);
      expect(settings.maintenanceMode, isFalse);
      expect(settings.allowRegistrationStylists, isTrue);
      expect(settings.emailVerification, isFalse);
      expect(settings.portfolioPriceFilters!.single.max, 600);
      expect(settings.portfolioPriceFilters!.single.min, 500);
    });

    test('malformed values become null for that field only', () {
      final settings = PlatformSettings.fromJson({
        ..._laravelPayload(),
        'updated_by': {'id': 2},
        'min_booking_amount': 'thirty',
        'appointment_canceling_threshold': 24.5,
        'happy_customers': true,
        'maintenance_mode': 'sometimes',
        'terms': 42,
        'currency_code': ['ZAR'],
        'featured_media': ['https://cdn.example/a.jpg', 7, null],
        'portfolio_price_filters': [
          'not a map',
          {'label': 'Any', 'max': 'none', 'min': 0, 'is_default': 'yes'},
        ],
      });

      expect(settings.updatedBy, isNull);
      expect(settings.minBookingAmount, isNull);
      // A whole-number field is not silently truncated.
      expect(settings.appointmentCancelingThreshold, isNull);
      expect(settings.happyCustomers, isNull);
      expect(settings.maintenanceMode, isNull);
      expect(settings.terms, isNull);
      expect(settings.currencyCode, isNull);
      expect(settings.featuredMedia, ['https://cdn.example/a.jpg']);
      expect(settings.portfolioPriceFilters, hasLength(1));
      expect(settings.portfolioPriceFilters!.single.max, isNull);
      expect(settings.portfolioPriceFilters!.single.isDefault, isNull);
      // Everything else still parses.
      expect(settings.maxBookingAmount, 3000.0);
      expect(settings.commissionRate, 30.0);
      expect(settings.allowRegistrationCustomers, isTrue);
    });

    test('non-list collections are ignored', () {
      final settings = PlatformSettings.fromJson({
        'featured_media': 'https://cdn.example/a.jpg',
        'portfolio_price_filters': {'label': 'Any'},
      });

      expect(settings.featuredMedia, isNull);
      expect(settings.portfolioPriceFilters, isNull);
    });

    test('an empty payload yields an all-null settings object', () {
      final settings = PlatformSettings.fromJson(const {});

      expect(settings.id, isNull);
      expect(settings.minBookingAmount, isNull);
      expect(settings.featuredMedia, isNull);
      expect(settings.portfolioPriceFilters, isNull);
    });
  });

  test('toJson round-trips through the AppCubit cache encoding', () {
    // AppCubit stores jsonEncode(settings.toJson()) and re-parses it when
    // the network call fails.
    final original = PlatformSettings.fromJson(_laravelPayload());
    final cached = jsonDecode(jsonEncode(original.toJson()));
    final restored = PlatformSettings.fromJson(cached as Map<String, dynamic>);

    expect(restored.toJson(), original.toJson());
    expect(restored.updatedBy, 2);
    expect(restored.minBookingAmount, 30.0);
    expect(restored.appointmentCancelingThreshold, 24);
    expect(restored.portfolioPriceFilters!.last.max, 500);
  });
}
