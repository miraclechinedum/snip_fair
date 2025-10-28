import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';

// extension WidgetSpacing on num {
//   SizedBox get verticalSpace => SizedBox(height: toDouble());
//   SizedBox get horizontalSpace => SizedBox(width: toDouble());
// }

extension MoneyFormatter on num {
  String formatAmount() {
    final currencyFormat = NumberFormat.currency(name: 'R');

    return currencyFormat.format(this);
  }
}

extension BuildContextHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
}

extension DateFormatter on DateTime? {
  String toTimeAgo() {
    final dateTime = this;
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  String toShortDateString() {
    final dateTime = this;
    if (dateTime == null) return '';
    final formatter = DateFormat('dd MMM, yyyy');
    return formatter.format(dateTime.toLocal());
  }

  String toLongDateString() {
    final dateTime = this;
    if (dateTime == null) return '';
    final formatter = DateFormat('EEEE, dd MMMM yyyy, hh:mm a');
    return formatter.format(dateTime.toLocal());
  }
}

extension ImageUrlCompleter on String? {
  String completeImagePath() {
    final config = Environment().config;
    var imageLink = this;
    if (imageLink != null) {
      if (imageLink[0] == '/') {
        imageLink = imageLink.substring(1);
      }
      return '${config.apiHost.replaceAll('/api', '')}/storage/$imageLink';
    }
    return '';
  }
}

extension MagicString on String? {
  double convertToDouble() {
    if (this == null) return 0;
    return double.tryParse(this!) ?? 0;
  }

  int pickNumber() {
    final text = this;
    if (text == null) return 0;
    final match = RegExp(r'\d+').firstMatch(text);
    if (match != null) {
      final number = int.parse(match.group(0)!);
      return number;
    }
    return 0;
  }

  bool get isLocalFilePath {
    final text = this;
    if (text == null) return false;
    final value = text.trim();

    // Reject empty strings or URLs
    if (value.isEmpty) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }

    // On Unix (Linux, macOS) — starts with "/" or relative path (e.g., ./file or ../file)
    return value.startsWith('/') ||
        value.startsWith('./') ||
        value.startsWith('../');
  }

  String showLast4Digits() {
    final text = this;
    if (text == null) return '';
    if (text.length <= 4) return text;

    return text.substring(text.length - 4).padLeft(text.length, '*');
  }

  String capitalizeFirstLetter() {
    if (this == null || this!.isEmpty) {
      return ''; // Handle empty string case
    }
    return '${this![0].toUpperCase()}${this!.substring(1)}';
  }

  String toTimeAgo() {
    final text = this;
    if (text == null) return '';
    final dateTime = DateTime.tryParse(text);
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}

extension StatusCodeMapper on String? {
  // All Status processing, pending, approved, confirmed, completed, canceled, escalated.

  Color toStatusColor() {
    final status = this;
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.lightGreen;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return AppColors.primaryColor;
      case 'canceled':
      case 'rescheduled':
        return Colors.red;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String toStatusText() {
    final status = this;
    if (status == null) return '';
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Awaiting stylist approval';
      case 'approved':
        return 'Appointment Approved';
      case 'confirmed':
        return 'Appointment Started';
      case 'completed':
        return 'Appointment Completed';
      case 'canceled':
        return 'Appointment Canceled';
      case 'escalated':
        return 'Appointment Escalated';
      case 'rescheduled':
        return 'Appointment Rescheduled';
      default:
        return 'Unknown';
    }
  }

  bool get isPendingStatus {
    final status = this;
    if (status == null) return false;
    return status.toLowerCase() == 'pending';
  }

  bool get isCompletedStatus {
    final status = this;
    if (status == null) return false;
    return status.toLowerCase() == 'completed';
  }

  bool get isCanceledStatus {
    final status = this;
    if (status == null) return false;
    return status.toLowerCase() == 'canceled';
  }

  bool get isEscalatedStatus {
    final status = this;
    if (status == null) return false;
    return status.toLowerCase() == 'escalated';
  }

  bool get isProcessingStatus {
    final status = this;
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'processing';
  }

  bool get isApprovedStatus {
    final status = this;
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'approved';
  }

  bool get isConfirmedStatus {
    final status = this;
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'confirmed';
  }

  String removeAMPM() {
    final text = this;
    if (text == null) return '';
    return text.replaceAll(RegExp(r'\s?(AM|PM)$', caseSensitive: false), '');
  }
}
