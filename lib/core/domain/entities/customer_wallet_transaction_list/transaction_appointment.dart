import 'package:intl/intl.dart';

/// The booking an appointment payment paid for: the `appointment` object
/// `GET /wallet/transactions` adds to `payment` rows tied to a booking
/// (`App\Support\TransactionHistoryRow`). Every field is optional; rows from
/// older servers simply have no appointment.
class TransactionAppointment {
  const TransactionAppointment({
    this.id,
    this.bookingId,
    this.appointmentCode,
    this.serviceName,
    this.stylistName,
    this.date,
    this.time,
    this.status,
  });

  /// Null unless [json] is an object; wrong-typed fields are dropped, never
  /// thrown on, so one odd row cannot break the history list.
  static TransactionAppointment? tryParse(Object? json) {
    if (json is! Map) return null;
    return TransactionAppointment(
      id: _text(json['id']),
      bookingId: _text(json['booking_id']),
      appointmentCode: _text(json['appointment_code']),
      serviceName: _text(json['service_name']),
      stylistName: _text(json['stylist_name']),
      date: _text(json['date']),
      time: _text(json['time']),
      status: _text(json['status']),
    );
  }

  final String? id;
  final String? bookingId;
  final String? appointmentCode;
  final String? serviceName;

  /// The stylist's business name, or their name when they have none.
  final String? stylistName;

  /// `yyyy-MM-dd`, as stored by Laravel.
  final String? date;

  /// `HH:mm:ss`, as stored by Laravel.
  final String? time;
  final String? status;

  /// The appointment's own reference: the booking id, else its code.
  String? get reference => bookingId ?? appointmentCode;

  /// Wall-clock start of the appointment (no time zone is sent).
  DateTime? get startsAt {
    final d = date;
    if (d == null) return null;
    return DateTime.tryParse(time == null ? d : '${d}T$time') ??
        DateTime.tryParse(d);
  }

  /// e.g. `Fri, 20 Nov 2026 · 2:30 PM`, or just the date when no time.
  String? get scheduleLabel {
    final start = startsAt;
    if (start == null) return null;
    final day = DateFormat('EEE, d MMM yyyy', 'en_US').format(start);
    return time == null
        ? day
        : '$day · ${DateFormat('h:mm a', 'en_US').format(start)}';
  }

  static String? _text(Object? value) {
    if (value is num) return value.toString();
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
