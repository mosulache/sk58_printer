/// Image processing utilities for SK58 thermal printer.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximum effective print width for SK58 printer.
///
/// The SK58 has a 48mm effective printing width (not 58mm paper width).
/// At 203 DPI (8 dots/mm): 48mm × 8 = 384 dots.
///
/// Note: Even with 50mm label paper, max printable width is still 48mm/384 dots.
const int sk58MaxWidth = 384;

/// Image processor for converting images to printer-compatible format.
class Sk58ImageProcessor {
  Sk58ImageProcessor._();

  /// Process an image for thermal printing.
  ///
  /// [imageBytes] - Raw image bytes (PNG, JPEG, etc.).
  /// [maxWidth] - Maximum width in pixels. Default is 384 (58mm paper).
  /// [dithering] - Whether to apply Floyd-Steinberg dithering. Default is true.
  /// [threshold] - Brightness threshold for B&W conversion (0-255). Default is 128.
  ///
  /// Returns processed bitmap data ready for printing.
  ///
  /// Throws [ImageProcessingException] if image cannot be processed.
  static ProcessedImage processImage(
    Uint8List imageBytes, {
    int maxWidth = sk58MaxWidth,
    bool dithering = true,
    int threshold = 128,
  }) {
    // Decode image
    img.Image? image;
    try {
      image = img.decodeImage(imageBytes);
    } catch (e) {
      throw ImageProcessingException('Failed to decode image: $e');
    }

    if (image == null) {
      throw ImageProcessingException('Failed to decode image');
    }

    // Resize if needed
    img.Image resized;
    if (image.width > maxWidth) {
      final ratio = maxWidth / image.width;
      final newHeight = (image.height * ratio).round();
      resized = img.copyResize(image, width: maxWidth, height: newHeight);
    } else {
      resized = image;
    }

    // Convert to grayscale
    final grayscale = img.grayscale(resized);

    // Apply dithering or simple threshold
    final monochrome = dithering
        ? _applyFloydSteinbergDithering(grayscale, threshold)
        : _applyThreshold(grayscale, threshold);

    // Convert to printer bitmap format
    final bitmapData = _toBitmapData(monochrome);

    return ProcessedImage(
      width: monochrome.width,
      height: monochrome.height,
      data: bitmapData,
    );
  }

  /// Apply Floyd-Steinberg dithering to grayscale image.
  static img.Image _applyFloydSteinbergDithering(
    img.Image image,
    int threshold,
  ) {
    // Work on a copy with float precision for error diffusion
    final errors = List.generate(
      image.height,
      (y) => List.generate(image.width, (x) => 0.0),
    );

    // Get initial pixel values
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        errors[y][x] = img.getLuminance(pixel).toDouble();
      }
    }

    // Apply Floyd-Steinberg dithering
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final oldPixel = errors[y][x];
        final newPixel = oldPixel < threshold ? 0.0 : 255.0;
        final error = oldPixel - newPixel;

        errors[y][x] = newPixel;

        // Distribute error to neighbors
        if (x + 1 < image.width) {
          errors[y][x + 1] += error * 7 / 16;
        }
        if (y + 1 < image.height) {
          if (x > 0) {
            errors[y + 1][x - 1] += error * 3 / 16;
          }
          errors[y + 1][x] += error * 5 / 16;
          if (x + 1 < image.width) {
            errors[y + 1][x + 1] += error * 1 / 16;
          }
        }
      }
    }

    // Create output image
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final value = errors[y][x] < 128 ? 0 : 255;
        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Apply simple threshold to grayscale image.
  static img.Image _applyThreshold(img.Image image, int threshold) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        final value = luminance < threshold ? 0 : 255;
        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Convert monochrome image to printer bitmap data.
  ///
  /// Each byte represents 8 horizontal pixels.
  /// Bit 1 = black (print), Bit 0 = white (no print).
  static Uint8List _toBitmapData(img.Image image) {
    // Ensure width is multiple of 8
    final widthBytes = (image.width + 7) ~/ 8;
    final data = Uint8List(widthBytes * image.height);

    for (int y = 0; y < image.height; y++) {
      for (int xByte = 0; xByte < widthBytes; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < image.width) {
            final pixel = image.getPixel(x, y);
            final luminance = img.getLuminance(pixel);
            // Black pixel = 1 (print), White pixel = 0 (no print)
            if (luminance < 128) {
              byte |= (0x80 >> bit);
            }
          }
        }
        data[y * widthBytes + xByte] = byte;
      }
    }

    return data;
  }
}

/// Processed image ready for printing.
class ProcessedImage {
  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Bitmap data (1 bit per pixel, packed into bytes).
  final Uint8List data;

  /// Width in bytes (width / 8, rounded up).
  int get widthBytes => (width + 7) ~/ 8;

  /// Creates a processed image.
  ProcessedImage({
    required this.width,
    required this.height,
    required this.data,
  });

  /// Generate ESC/POS raster image commands.
  ///
  /// Uses GS v 0 command for raster bit image.
  List<int> toCommands() {
    final List<int> commands = [];

    // GS v 0 m xL xH yL yH d1...dk
    // m = 0: normal density
    // xL xH = number of bytes per line (little-endian)
    // yL yH = number of lines (little-endian)
    final xL = widthBytes & 0xFF;
    final xH = (widthBytes >> 8) & 0xFF;
    final yL = height & 0xFF;
    final yH = (height >> 8) & 0xFF;

    commands.addAll([
      0x1D, // GS
      0x76, // v
      0x30, // 0
      0x00, // m (normal)
      xL,
      xH,
      yL,
      yH,
    ]);
    commands.addAll(data);

    return commands;
  }
}

/// Exception thrown when image processing fails.
class ImageProcessingException implements Exception {
  /// Error message.
  final String message;

  /// Creates an image processing exception.
  ImageProcessingException(this.message);

  @override
  String toString() => 'ImageProcessingException: $message';
}
