class AppConfig {
  const AppConfig({
    required this.appEnabled,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.minimumAndroidVersion,
    required this.minimumIosVersion,
    this.forceLogout = false,
    this.featureFlags = const <String, bool>{},
    this.announcements = const <String>[],
  });

  factory AppConfig.defaults() {
    return const AppConfig(
      appEnabled: true,
      maintenanceMode: false,
      maintenanceMessage: 'Service temporarily unavailable.',
      minimumAndroidVersion: 1,
      minimumIosVersion: 1,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final flags = json['feature_flags'];
    final announcements = json['announcements'];

    return AppConfig(
      appEnabled: json['app_enabled'] as bool? ?? true,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String? ??
          'Service temporarily unavailable.',
      minimumAndroidVersion: _readInt(json['minimum_android_version']) ?? 1,
      minimumIosVersion: _readInt(json['minimum_ios_version']) ?? 1,
      forceLogout: json['force_logout'] as bool? ?? false,
      featureFlags: flags is Map
          ? flags.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const <String, bool>{},
      announcements: announcements is List
          ? announcements.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }

  final bool appEnabled;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final int minimumAndroidVersion;
  final int minimumIosVersion;
  final bool forceLogout;
  final Map<String, bool> featureFlags;
  final List<String> announcements;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'app_enabled': appEnabled,
      'maintenance_mode': maintenanceMode,
      'maintenance_message': maintenanceMessage,
      'minimum_android_version': minimumAndroidVersion,
      'minimum_ios_version': minimumIosVersion,
      'force_logout': forceLogout,
      'feature_flags': featureFlags,
      'announcements': announcements,
    };
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
