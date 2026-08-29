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

/// Nombre: letras (incluye ñ, tildes). No corta el IME del teclado español
/// (n + virgulilla → ñ) ni los diacríticos combinados.
class PersonNameFormatter extends TextInputFormatter {
  static final _illegal = RegExp(
    r"[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-\u0300-\u036f]",
    unicode: true,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    final filtered = newValue.text.replaceAll(_illegal, '');
    if (filtered == newValue.text) return newValue;
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

final digitsOnly = DigitsOnlyFormatter();
final cardNumberFormatter = CardNumberFormatter();
final cardExpiryFormatter = CardExpiryFormatter();
final yapePhoneFormatter = YapePhoneFormatter();
final personNameFormatter = PersonNameFormatter();

List<TextInputFormatter> digitsMax(int n) => [
      DigitsOnlyFormatter(),
      LengthLimitingTextInputFormatter(n),
    ];

class AppInputFormatters {
  static List<TextInputFormatter> get phonePe => digitsMax(9);
  static List<TextInputFormatter> get dni => digitsMax(8);
  static List<TextInputFormatter> get ruc => digitsMax(11);
  static List<TextInputFormatter> get cvv => digitsMax(3);
  static List<TextInputFormatter> get personName => [personNameFormatter];
}
