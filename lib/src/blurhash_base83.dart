import 'dart:math';

int decode83(String str) {
  var value = 0;
  final units = str.codeUnits;
  final digits = _characters.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final code = units.elementAt(i);
    final digit = digits.indexOf(code);
    if (digit == -1) {
      throw ArgumentError.value(str, 'str');
    }
    value = value * 83 + digit;
  }
  return value;
}

String encode83(int value, int length) {
  assert(value >= 0 && length >= 0);

  final buffer = StringBuffer();
  for (var i = 1; i <= length; ++i) {
    final digit = (value / pow(83, length - i)) % 83;
    buffer.write(_characters[digit.toInt()]);
  }
  return buffer.toString();
}

const _characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~";
