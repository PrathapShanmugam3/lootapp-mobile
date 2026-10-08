import 'package:flutter/services.dart';

/// Keyboard input rules for payout fields, so invalid text can't be typed
/// at all (instead of only being flagged after submit).
class InputRules {
  InputRules._();

  /// Rupee amount: digits with up to two decimals, never above [max].
  static TextInputFormatter amount({required num max}) => _AmountFormatter(max);

  /// Digits only, at most [length] of them (bank account numbers).
  static List<TextInputFormatter> digits(int length) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ];

  /// Letters/digits only, upper-cased, at most [length] (IFSC codes).
  static List<TextInputFormatter> alphanumericUpper(int length) => [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        _UpperCaseFormatter(),
        LengthLimitingTextInputFormatter(length),
      ];

  /// No whitespace, at most [length] characters (UPI IDs).
  static List<TextInputFormatter> noSpaces(int length) => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(length),
      ];
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class _AmountFormatter extends TextInputFormatter {
  _AmountFormatter(this.max);

  final num max;
  static final _shape = RegExp(r'^\d*(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!_shape.hasMatch(text)) return oldValue;
    final value = double.tryParse(text);
    if (value != null && value > max) return oldValue;
    return newValue;
  }
}
