import 'dart:math';

double sRGBToLinear(int value) {
  final v = value / 255;
  if (v <= 0.04045) return v / 12.92;
  else return pow((v + 0.055) / 1.055, 2.4);
}

int linearTosRGB(double value) {
  final v = max(0, min(1, value));
  if (v <= 0.0031308) return (v * 12.92 * 255 + 0.5).round();
  else return ((1.055 * pow(v, 1 / 2.4) - 0.055) * 255 + 0.5).round();
}

int sign(double n) => (n < 0 ? -1 : 1);

double signPow(double val, double exp) => sign(val) * pow(val.abs(), exp);
