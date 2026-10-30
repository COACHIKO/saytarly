import 'package:intl/intl.dart';

import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/utils/money.dart';

/// Dashboard-specific formatting helpers.
///
/// Numbers are formatted with Latin digits and thousands separators because
/// that reads fastest on an operations dashboard; the currency symbol follows
/// the business setting from [Money].
abstract final class DashboardFormat {
  DashboardFormat._();

  static final NumberFormat _grouped = NumberFormat('#,##0.##', 'en');
  static final NumberFormat _whole = NumberFormat('#,##0', 'en');
  static final DateFormat _time = DateFormat('HH:mm', 'en');

  static String money(num value) =>
      '${_grouped.format(value)} ${Money.symbol}'.trim();

  static String wholeMoney(num value) =>
      '${_whole.format(value)} ${Money.symbol}'.trim();

  static String compactMoney(num value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      final v = value / 1000000;
      return '${_trim(v)}M ${Money.symbol}'.trim();
    }
    if (abs >= 1000) {
      final v = value / 1000;
      return '${_trim(v)}K ${Money.symbol}'.trim();
    }
    return money(value);
  }

  static String number(num value) => _grouped.format(value);

  static String percent(num value, {int decimals = 0}) =>
      '${value.toStringAsFixed(decimals)}%';

  static String signedPercent(num value, {int decimals = 1}) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(decimals)}%';
  }

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value);

  static String date(DateTime value) => DateFormat(
    'd MMM',
    Str.isRtl ? 'ar' : 'en',
  ).format(value);

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
