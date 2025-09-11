import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// extension WidgetSpacing on num {
//   SizedBox get verticalSpace => SizedBox(height: toDouble());
//   SizedBox get horizontalSpace => SizedBox(width: toDouble());
// }

extension MoneyFormatter on num {
  String formatAmount() {
    final currencyFormat = NumberFormat.currency(name: '₦');

    return currencyFormat.format(this);
  }
}
