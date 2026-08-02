// lib/core/utils/input_formatters.dart
import 'package:flutter/services.dart';

/// Solo dígitos 0-9.
class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// Número de tarjeta con espacios cada 4 dígitos (máx 16 dígitos).
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 16) d = d.substring(0, 16);
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Expiración MM/AA.
class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 4) d = d.substring(0, 4);
    var text = d;
    if (d.length >= 3) {
      text = '${d.substring(0, 2)}/${d.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Celular Yape: +51 9xxxxxxxx
class YapePhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var body = digits;
    if (body.startsWith('51')) body = body.substring(2);
    if (body.startsWith('9')) {
      body = body.substring(1);
    }
    if (body.length > 8) body = body.substring(0, 8);
    final text = '+51 9$body';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Atajos comunes
final digitsOnly = DigitsOnlyFormatter();
final cardNumberFormatter = CardNumberFormatter();
final cardExpiryFormatter = CardExpiryFormatter();
final yapePhoneFormatter = YapePhoneFormatter();

List<TextInputFormatter> digitsMax(int n) => [
      DigitsOnlyFormatter(),
      LengthLimitingTextInputFormatter(n),
    ];
