import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
}
