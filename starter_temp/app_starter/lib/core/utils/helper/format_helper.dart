import 'package:intl/intl.dart';

/// Helper class for formatting various data types
class FormatHelper {
  /// Format date to string
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// Format number with thousand separators
  static String formatNumber(num number) {
    return NumberFormat('#,##0').format(number);
  }

  /// Format currency
  static String formatCurrency(num amount, {String symbol = '\$'}) {
    return '$symbol${NumberFormat('#,##0.00').format(amount)}';
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
