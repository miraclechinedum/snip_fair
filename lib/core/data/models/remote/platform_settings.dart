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
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    terms = json['terms'] as String?;
    privacyPolicy = json['privacy_policy'] as String?;
    cookies = json['cookies'] as String?;
    emailVerification = json['email_verification'] as bool?;
    twoFactorAuth = json['two_factor_auth'] as bool?;
    minBookingAmount = json['min_booking_amount'] is int
        ? json['min_booking_amount'] as int
        : int.tryParse(json['min_booking_amount']?.toString() ?? '');
    maxBookingAmount = json['max_booking_amount'] is int
        ? json['max_booking_amount'] as int
        : int.tryParse(json['max_booking_amount']?.toString() ?? '');
    allowRegistrationStylists = json['allow_registration_stylists'] as bool?;
    allowRegistrationCustomers = json['allow_registration_customers'] as bool?;
    maintenanceMode = json['maintenance_mode'] as bool?;
    maintenanceMessage = json['maintenance_message'] as String?;
    emailNotifications = json['email_notifications'] as bool?;
    pushNotifications = json['push_notifications'] as bool?;
    systemAlerts = json['system_alerts'] as bool?;
    paymentAlerts = json['payment_alerts'] as bool?;
    contentModeration = json['content_moderation'] as bool?;
    appointmentRescheduleThreshold =
        json['appointment_reschedule_threshold'] is int
            ? json['appointment_reschedule_threshold'] as int
            : int.tryParse(
                json['appointment_reschedule_threshold']?.toString() ?? '');
    appointmentReschedulePercentage =
        json['appointment_reschedule_percentage'] is int
            ? json['appointment_reschedule_percentage'] as int
            : int.tryParse(
                json['appointment_reschedule_percentage']?.toString() ?? '');
    appointmentCancelingThreshold =
        json['appointment_canceling_threshold'] is int
            ? json['appointment_canceling_threshold'] as int
            : int.tryParse(
                json['appointment_canceling_threshold']?.toString() ?? '');
    appointmentCancelingPercentage =
        json['appointment_canceling_percentage'] is int
            ? json['appointment_canceling_percentage'] as int
            : int.tryParse(
                json['appointment_canceling_percentage']?.toString() ?? '');
    updatedBy = json['updated_by'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
    commissionRate = json['commission_rate'] is int
        ? json['commission_rate'] as int
        : int.tryParse(json['commission_rate']?.toString() ?? '');
    currencySymbol = json['currency_symbol'] as String?;
    currencyCode = json['currency_code'] as String?;
    featuredMedia = json['featured_media'] != null
        ? List<String>.from(json['featured_media'] as List<dynamic>)
        : null;
    professionalStylists = json['professional_stylists'] is int
        ? json['professional_stylists'] as int
        : int.tryParse(json['professional_stylists']?.toString() ?? '');
    happyCustomers = json['happy_customers'] is int
        ? json['happy_customers'] as int
        : int.tryParse(json['happy_customers']?.toString() ?? '');
    servicesCompleted = json['services_completed'] is int
        ? json['services_completed'] as int
        : int.tryParse(json['services_completed']?.toString() ?? '');
    customerSatisfaction = json['customer_satisfaction'] is double
        ? json['customer_satisfaction'] as double
        : json['customer_satisfaction'] != null
            ? double.tryParse(json['customer_satisfaction'].toString())
            : null;
    if (json['portfolio_price_filters'] != null) {
      portfolioPriceFilters = <PortfolioPriceFilters>[];
      for (final v in (json['portfolio_price_filters'] as List<dynamic>)) {
        portfolioPriceFilters!
            .add(PortfolioPriceFilters.fromJson(v as Map<String, dynamic>));
      }
    }
  }
  int? id;
  String? terms;
  String? privacyPolicy;
  String? cookies;
  bool? emailVerification;
  bool? twoFactorAuth;
  int? minBookingAmount;
  int? maxBookingAmount;
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
  int? appointmentReschedulePercentage;
  int? appointmentCancelingThreshold;
  int? appointmentCancelingPercentage;
  String? updatedBy;
  String? createdAt;
  String? updatedAt;
  int? commissionRate;
  String? currencySymbol;
  String? currencyCode;
  List<String>? featuredMedia;
  int? professionalStylists;
  int? happyCustomers;
  int? servicesCompleted;
  double? customerSatisfaction;
  List<PortfolioPriceFilters>? portfolioPriceFilters;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
    label = json['label'] as String?;
    max = json['max'] is int
        ? json['max'] as int
        : int.tryParse(json['max']?.toString() ?? '');
    min = json['min'] is int
        ? json['min'] as int
        : int.tryParse(json['min']?.toString() ?? '');
    isDefault = json['is_default'] as bool?;
  }
  String? label;
  int? max;
  int? min;
  bool? isDefault;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = label;
    data['max'] = max;
    data['min'] = min;
    data['is_default'] = isDefault;
    return data;
  }
}
