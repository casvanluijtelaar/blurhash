// Encodes an image to a BlurHash string
import 'dart:math';
import 'dart:typed_data';

import 'blurhash_base83.dart';
import 'blurhash_utils.dart';

String blurHashEncode(
  Uint8List data,
  int width,
  int height, {
  int numCompX = 4,
  int numpCompY = 3,
}) {
  if (numCompX < 1 || numCompX > 9 || numpCompY < 1 || numCompX > 9) {
    throw Exception(
      "BlurHash components must lie between 1 and 9.",
    );
  }

  if (width * height * 4 != data.length) {
    throw Exception(
      "The width and height must match the data array."
      "The expected format is RGBA32",
    );
  }

  final factors = List<_Pixel?>.filled(numCompX*numpCompY, null);
  int i = 0;
  for (var y = 0; y < numpCompY; ++y) {
    for (var x = 0; x < numCompX; ++x) {
      final normalisation = (x == 0 && y == 0) ? 1.0 : 2.0;
      final basisFunc = (int i, int j) {
        return normalisation *
            cos((pi * x * i) / width) *
            cos((pi * y * j) / height);
      };
      factors[i++] = _multiplyBasisFunction(data, width, height, basisFunc);
    }
  }

  final dc = factors.first;
  final ac = factors.skip(1).toList();

  final blurHash = StringBuffer();
  final sizeFlag = (numCompX - 1) + (numpCompY - 1) * 9;
  blurHash.write(encode83(sizeFlag, 1));

  var maxVal = 1.0;
  if (ac.isNotEmpty) {
    final maxElem = (_Pixel? c) => max(c!.r.abs(), max(c.g.abs(), c.b.abs()));
    final actualMax = ac.map(maxElem).reduce(max);
    final quantisedMax = max(0, min(82, (actualMax * 166.0 - 0.5).floor()));
    maxVal = (quantisedMax + 1.0) / 166.0;
    blurHash.write(encode83(quantisedMax, 1));
  } else {
    blurHash.write(encode83(0, 1));
  }

  blurHash.write(encode83(_encodeDC(dc!), 4));
  for (final factor in ac) {
    blurHash.write(encode83(_encodeAC(factor!, maxVal), 2));
  }
  return blurHash.toString();
}

_Pixel _multiplyBasisFunction(
  Uint8List pixels,
  int width,
  int height,
  double basisFunction(int i, int j),
) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;

  final bytesPerRow = width * 4;

  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final basis = basisFunction(x, y);
      r += basis * sRGBToLinear(pixels[4 * x + 0 + y * bytesPerRow]);
      g += basis * sRGBToLinear(pixels[4 * x + 1 + y * bytesPerRow]);
      b += basis * sRGBToLinear(pixels[4 * x + 2 + y * bytesPerRow]);
    }
  }

  final scale = 1.0 / (width * height);
  return _Pixel(r * scale, g * scale, b * scale);
}

int _encodeDC(_Pixel color) {
  final r = linearTosRGB(color.r);
  final g = linearTosRGB(color.g);
  final b = linearTosRGB(color.b);
  return (r << 16) + (g << 8) + b;
}

int _encodeAC(_Pixel color, double maxVal) {
  final r = max(0, min(18, signPow(color.r / maxVal, 0.5) * 9 + 9.5)).floor();
  final g = max(0, min(18, signPow(color.g / maxVal, 0.5) * 9 + 9.5)).floor();
  final b = max(0, min(18, signPow(color.b / maxVal, 0.5) * 9 + 9.5)).floor();
  return r * 19 * 19 + g * 19 + b;
}

class _Pixel {
  _Pixel(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;
}
