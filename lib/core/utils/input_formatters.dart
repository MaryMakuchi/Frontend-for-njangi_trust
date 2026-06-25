import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input with thousand separators as the user types,
/// e.g. "50000" -> "50,000".
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final value = int.parse(digitsOnly);
    final formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
