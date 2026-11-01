class PlatformSettings {
  PlatformSettings({
    this.id,
    this.terms,
    this.privacyPolicy,
    this.cookies,
    this.emailVerification,
    this.twoFactorAuth,
    this.minBookingAmount,
    this.maxBookingAmount,
    this.allowRegistrationStylists,
    this.allowRegistrationCustomers,
    this.maintenanceMode,
    this.maintenanceMessage,
    this.emailNotifications,
    this.pushNotifications,
    this.systemAlerts,
    this.paymentAlerts,
    this.contentModeration,
    this.appointmentRescheduleThreshold,
    this.appointmentReschedulePercentage,
    this.appointmentCancelingThreshold,
    this.appointmentCancelingPercentage,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.commissionRate,
    this.currencySymbol,
    this.currencyCode,
    this.featuredMedia,
    this.professionalStylists,
    this.happyCustomers,
    this.servicesCompleted,
    this.customerSatisfaction,
    this.portfolioPriceFilters,
  });

  PlatformSettings.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    terms = _asString(json['terms']);
    privacyPolicy = _asString(json['privacy_policy']);
    cookies = _asString(json['cookies']);
    emailVerification = _asBool(json['email_verification']);
    twoFactorAuth = _asBool(json['two_factor_auth']);
    minBookingAmount = _asDouble(json['min_booking_amount']);
    maxBookingAmount = _asDouble(json['max_booking_amount']);
    allowRegistrationStylists = _asBool(json['allow_registration_stylists']);
    allowRegistrationCustomers = _asBool(json['allow_registration_customers']);
    maintenanceMode = _asBool(json['maintenance_mode']);
    maintenanceMessage = _asString(json['maintenance_message']);
    emailNotifications = _asBool(json['email_notifications']);
    pushNotifications = _asBool(json['push_notifications']);
    systemAlerts = _asBool(json['system_alerts']);
    paymentAlerts = _asBool(json['payment_alerts']);
    contentModeration = _asBool(json['content_moderation']);
    appointmentRescheduleThreshold =
        _asInt(json['appointment_reschedule_threshold']);
    appointmentReschedulePercentage =
        _asDouble(json['appointment_reschedule_percentage']);
    appointmentCancelingThreshold =
        _asInt(json['appointment_canceling_threshold']);
    appointmentCancelingPercentage =
        _asDouble(json['appointment_canceling_percentage']);
    updatedBy = _asInt(json['updated_by']);
    createdAt = _asString(json['created_at']);
    updatedAt = _asString(json['updated_at']);
    commissionRate = _asDouble(json['commission_rate']);
    currencySymbol = _asString(json['currency_symbol']);
    currencyCode = _asString(json['currency_code']);
    final media = json['featured_media'];
    featuredMedia = media is List ? media.whereType<String>().toList() : null;
    professionalStylists = _asInt(json['professional_stylists']);
    happyCustomers = _asInt(json['happy_customers']);
    servicesCompleted = _asInt(json['services_completed']);
    customerSatisfaction = _asDouble(json['customer_satisfaction']);
    final filters = json['portfolio_price_filters'];
    if (filters is List) {
      portfolioPriceFilters = filters
          .whereType<Map<String, dynamic>>()
          .map(PortfolioPriceFilters.fromJson)
          .toList();
    }
  }
  int? id;
  String? terms;
  String? privacyPolicy;
  String? cookies;
  bool? emailVerification;
  bool? twoFactorAuth;

  /// Money: Laravel casts these to float (e.g. `30.0`, `30.5`).
  double? minBookingAmount;
  double? maxBookingAmount;
  bool? allowRegistrationStylists;
  bool? allowRegistrationCustomers;
  bool? maintenanceMode;
  String? maintenanceMessage;
  bool? emailNotifications;
  bool? pushNotifications;
  bool? systemAlerts;
  bool? paymentAlerts;
  bool? contentModeration;
  int? appointmentRescheduleThreshold;
  double? appointmentReschedulePercentage;
  int? appointmentCancelingThreshold;
  double? appointmentCancelingPercentage;

  /// Id of the admin who last edited the settings (`admins` foreign key).
  int? updatedBy;
  String? createdAt;
  String? updatedAt;
  double? commissionRate;
  String? currencySymbol;
  String? currencyCode;
  List<String>? featuredMedia;
  int? professionalStylists;
  int? happyCustomers;
  int? servicesCompleted;
  double? customerSatisfaction;
  List<PortfolioPriceFilters>? portfolioPriceFilters;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['terms'] = terms;
    data['privacy_policy'] = privacyPolicy;
    data['cookies'] = cookies;
    data['email_verification'] = emailVerification;
    data['two_factor_auth'] = twoFactorAuth;
    data['min_booking_amount'] = minBookingAmount;
    data['max_booking_amount'] = maxBookingAmount;
    data['allow_registration_stylists'] = allowRegistrationStylists;
    data['allow_registration_customers'] = allowRegistrationCustomers;
    data['maintenance_mode'] = maintenanceMode;
    data['maintenance_message'] = maintenanceMessage;
    data['email_notifications'] = emailNotifications;
    data['push_notifications'] = pushNotifications;
    data['system_alerts'] = systemAlerts;
    data['payment_alerts'] = paymentAlerts;
    data['content_moderation'] = contentModeration;
    data['appointment_reschedule_threshold'] = appointmentRescheduleThreshold;
    data['appointment_reschedule_percentage'] = appointmentReschedulePercentage;
    data['appointment_canceling_threshold'] = appointmentCancelingThreshold;
    data['appointment_canceling_percentage'] = appointmentCancelingPercentage;
    data['updated_by'] = updatedBy;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['commission_rate'] = commissionRate;
    data['currency_symbol'] = currencySymbol;
    data['currency_code'] = currencyCode;
    data['featured_media'] = featuredMedia;
    data['professional_stylists'] = professionalStylists;
    data['happy_customers'] = happyCustomers;
    data['services_completed'] = servicesCompleted;
    data['customer_satisfaction'] = customerSatisfaction;
    if (portfolioPriceFilters != null) {
      data['portfolio_price_filters'] =
          portfolioPriceFilters!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PortfolioPriceFilters {
  PortfolioPriceFilters({this.label, this.max, this.min, this.isDefault});

  PortfolioPriceFilters.fromJson(Map<String, dynamic> json) {
    label = _asString(json['label']);
    max = _asInt(json['max']);
    min = _asInt(json['min']);
    isDefault = _asBool(json['is_default']);
  }
  String? label;
  int? max;
  int? min;
  bool? isDefault;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['label'] = label;
    data['max'] = max;
    data['min'] = min;
    data['is_default'] = isDefault;
    return data;
  }
}

// ---------------------------------------------------------------------------
// Tolerant field parsers. `/platform-settings` mixes Laravel float casts
// (`30.0`), integer foreign keys and booleans, and the app also re-parses its
// own cached `toJson()` output. A value of the wrong shape becomes null for
// that field only — it never fails the whole settings object.
// ---------------------------------------------------------------------------

/// Whole numbers given as `3`, `3.0`, `"3"` or `"3.0"`. Fractional or
/// non-numeric values are rejected rather than silently truncated.
int? _asInt(Object? value) {
  if (value is int) return value;
  final number = value is num ? value : num.tryParse(_trimmed(value) ?? '');
  if (number == null || !number.isFinite || number != number.truncate()) {
    return null;
  }
  return number.toInt();
}

double? _asDouble(Object? value) {
  final number = value is num ? value : num.tryParse(_trimmed(value) ?? '');
  if (number == null || !number.isFinite) return null;
  return number.toDouble();
}

/// `true`/`false`, plus the `1`/`0` a MySQL tinyint yields without a cast.
bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value == 1 || value == '1' || value == 'true') return true;
  if (value == 0 || value == '0' || value == 'false') return false;
  return null;
}

String? _asString(Object? value) => value is String ? value : null;

String? _trimmed(Object? value) => value is String ? value.trim() : null;
