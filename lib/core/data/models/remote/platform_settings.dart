class PlatformSettings {
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

  PlatformSettings(
      {this.id,
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
      this.customerSatisfaction});

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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['terms'] = this.terms;
    data['privacy_policy'] = this.privacyPolicy;
    data['cookies'] = this.cookies;
    data['email_verification'] = this.emailVerification;
    data['two_factor_auth'] = this.twoFactorAuth;
    data['min_booking_amount'] = this.minBookingAmount;
    data['max_booking_amount'] = this.maxBookingAmount;
    data['allow_registration_stylists'] = this.allowRegistrationStylists;
    data['allow_registration_customers'] = this.allowRegistrationCustomers;
    data['maintenance_mode'] = this.maintenanceMode;
    data['maintenance_message'] = this.maintenanceMessage;
    data['email_notifications'] = this.emailNotifications;
    data['push_notifications'] = this.pushNotifications;
    data['system_alerts'] = this.systemAlerts;
    data['payment_alerts'] = this.paymentAlerts;
    data['content_moderation'] = this.contentModeration;
    data['appointment_reschedule_threshold'] =
        this.appointmentRescheduleThreshold;
    data['appointment_reschedule_percentage'] =
        this.appointmentReschedulePercentage;
    data['appointment_canceling_threshold'] =
        this.appointmentCancelingThreshold;
    data['appointment_canceling_percentage'] =
        this.appointmentCancelingPercentage;
    data['updated_by'] = this.updatedBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['commission_rate'] = this.commissionRate;
    data['currency_symbol'] = this.currencySymbol;
    data['currency_code'] = this.currencyCode;
    data['featured_media'] = this.featuredMedia;
    data['professional_stylists'] = this.professionalStylists;
    data['happy_customers'] = this.happyCustomers;
    data['services_completed'] = this.servicesCompleted;
    data['customer_satisfaction'] = this.customerSatisfaction;
    return data;
  }
}
