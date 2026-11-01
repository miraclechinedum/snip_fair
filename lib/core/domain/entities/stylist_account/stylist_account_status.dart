import 'package:equatable/equatable.dart';

/// The backend's activation states (`App\Services\StylistActivation`).
enum StylistAccountState {
  active,
  incomplete,
  notSubmitted,
  pendingApproval,
  rejected,
  unavailable,
  flagged,
  banned,

  /// A state this app version does not know yet.
  unknown;

  static StylistAccountState fromApi(Object? value) => switch (value) {
        'active' => active,
        'incomplete' => incomplete,
        'not_submitted' => notSubmitted,
        'pending_approval' => pendingApproval,
        'rejected' => rejected,
        'unavailable' => unavailable,
        'flagged' => flagged,
        'banned' => banned,
        _ => unknown,
      };
}

/// One verification step, as listed by the backend (in its order).
class StylistAccountRequirement extends Equatable {
  const StylistAccountRequirement({
    required this.key,
    required this.label,
    required this.completed,
  });

  final String key;
  final String label;
  final bool completed;

  static StylistAccountRequirement? tryParse(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    if (key is! String || key.isEmpty) return null;
    final label = json['label'];
    return StylistAccountRequirement(
      key: key,
      label: label is String && label.isNotEmpty ? label : key,
      completed: json['completed'] == true,
    );
  }

  @override
  List<Object?> get props => [key, label, completed];
}

/// The `stylist_account` block returned by login, stylist registration and
/// `GET /stylist/profile`. The backend is the source of truth: [isActive]
/// alone decides whether the stylist is active.
class StylistAccountStatus extends Equatable {
  const StylistAccountStatus({
    required this.isActive,
    required this.state,
    required this.rawState,
    this.verificationComplete,
    this.approvalStatus,
    this.isAvailable,
    this.requirements = const [],
    this.missingRequirements = const [],
    this.message,
  });

  final bool isActive;
  final StylistAccountState state;

  /// The state string as sent, kept for diagnostics.
  final String? rawState;
  final bool? verificationComplete;
  final String? approvalStatus;
  final bool? isAvailable;
  final List<StylistAccountRequirement> requirements;
  final List<String> missingRequirements;
  final String? message;

  /// Null unless [json] is a map with a boolean `is_active` — without it the
  /// block cannot say whether the stylist is active, so it is not trusted.
  static StylistAccountStatus? tryParse(Object? json) {
    if (json is! Map) return null;
    final isActive = json['is_active'];
    if (isActive is! bool) return null;
    final rawState = json['state'];
    final requirements = json['requirements'];
    final missing = json['missing_requirements'];
    final message = json['message'];
    final approval = json['approval_status'];
    return StylistAccountStatus(
      isActive: isActive,
      state: StylistAccountState.fromApi(rawState),
      rawState: rawState is String ? rawState : null,
      verificationComplete: json['verification_complete'] is bool
          ? json['verification_complete'] as bool
          : null,
      approvalStatus: approval is String ? approval : null,
      isAvailable:
          json['is_available'] is bool ? json['is_available'] as bool : null,
      requirements: requirements is List
          ? requirements
              .map(StylistAccountRequirement.tryParse)
              .whereType<StylistAccountRequirement>()
              .toList()
          : const [],
      missingRequirements: missing is List
          ? missing.whereType<String>().toList()
          : const [],
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
    );
  }

  /// Outstanding steps in the backend's order. Uses `missing_requirements`
  /// when sent, otherwise the incomplete entries of `requirements`.
  List<StylistAccountRequirement> get outstandingRequirements {
    if (missingRequirements.isEmpty) {
      return requirements.where((r) => !r.completed).toList();
    }
    final byKey = {for (final r in requirements) r.key: r};
    return [
      for (final key in missingRequirements)
        byKey[key] ??
            StylistAccountRequirement(key: key, label: key, completed: false),
    ];
  }

  @override
  List<Object?> get props => [
        isActive,
        state,
        rawState,
        verificationComplete,
        approvalStatus,
        isAvailable,
        requirements,
        missingRequirements,
        message,
      ];
}
