import 'package:intl/intl.dart';
import '../constants/app_strings.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final _shortDateFormat = DateFormat('dd MMM');

  static String currency(num amount, {bool showSymbol = true}) {
    final formatted = _currencyFormat.format(amount);
    if (showSymbol) {
      return '$formatted ${AppStrings.currency}';
    }
    return formatted;
  }

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  static String mriScore(double score) => score.toStringAsFixed(1);

  static String percentage(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  static String truncateHash(String hash, {int length = 12}) {
    if (hash.length <= length) return hash;
    return '${hash.substring(0, length)}...';
  }
}
