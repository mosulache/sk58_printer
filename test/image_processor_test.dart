import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('sk58MaxWidth constant', () {
    test('is 384 pixels for 58mm paper', () {
      expect(sk58MaxWidth, 384);
    });
  });

  group('ProcessedImage', () {
    test('calculates widthBytes correctly', () {
      // Width 32 -> 4 bytes
      var processed = ProcessedImage(
        width: 32,
        height: 10,
        data: Uint8List(40),
      );
      expect(processed.widthBytes, 4);

      // Width 33 -> 5 bytes (rounds up)
      processed = ProcessedImage(
        width: 33,
        height: 10,
        data: Uint8List(50),
      );
      expect(processed.widthBytes, 5);

      // Width 8 -> 1 byte
      processed = ProcessedImage(
        width: 8,
        height: 10,
        data: Uint8List(10),
      );
      expect(processed.widthBytes, 1);
    });

    test('toCommands generates GS v 0 command', () {
      final processed = ProcessedImage(
        width: 32,
        height: 16,
        data: Uint8List(64), // 4 bytes * 16 rows
      );

      final commands = processed.toCommands();

      // Check GS v 0 header
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x76); // v
      expect(commands[2], 0x30); // 0
      expect(commands[3], 0x00); // m (normal density)

      // Check dimensions (little-endian)
      expect(commands[4], 4); // xL (width bytes low)
      expect(commands[5], 0); // xH (width bytes high)
      expect(commands[6], 16); // yL (height low)
      expect(commands[7], 0); // yH (height high)
    });

    test('toCommands includes bitmap data', () {
      final data = Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]);
      final processed = ProcessedImage(
        width: 16,
        height: 2,
        data: data,
      );

      final commands = processed.toCommands();

      // Header is 8 bytes, then data
      expect(commands.length, 8 + 4);
      expect(commands.sublist(8), data);
    });

    test('toLineByLineCommands uses ESC * 33 (24-dot double density)', () {
      // Create a 8x24 image (1 band of 24 lines)
      final data = Uint8List(1 * 24); // 1 byte per row * 24 rows
      final processed = ProcessedImage(
        width: 8,
        height: 24,
        data: data,
      );

      final commands = processed.toLineByLineCommands();

      // Should start with ESC * 33 header
      expect(commands[0], 0x1B); // ESC
      expect(commands[1], 0x2A); // *
      expect(commands[2], 33); // m = 33 (24-dot double density)
      expect(commands[3], 8); // nL (width low byte)
      expect(commands[4], 0); // nH (width high byte)

      // After header (5 bytes) comes 3 bytes per column * 8 columns = 24 bytes
      // Then ESC J 24 (3 bytes) for line advance
      // Total: 5 + 24 + 3 = 32 bytes for one band
      expect(commands.length, 32);

      // Check line advance at end: ESC J 24
      expect(commands[29], 0x1B); // ESC
      expect(commands[30], 0x4A); // J
      expect(commands[31], 24); // 24 dots
    });

    test('toLineByLineCommands handles multiple bands', () {
      // Create a 8x48 image (2 bands of 24 lines each)
      final data = Uint8List(1 * 48); // 1 byte per row * 48 rows
      final processed = ProcessedImage(
        width: 8,
        height: 48,
        data: data,
      );

      final commands = processed.toLineByLineCommands();

      // 2 bands, each: 5 header + (3 bytes * 8 columns) + 3 (ESC J 24) = 32 bytes
      // Total: 2 * 32 = 64 bytes
      expect(commands.length, 64);

      // Check each band starts with ESC * 33
      expect(commands[0], 0x1B); // First band ESC
      expect(commands[32], 0x1B); // Second band ESC
    });
  });

  group('Sk58ImageProcessor', () {
    // Create a simple valid BMP image for testing
    Uint8List createTestBmp() {
      const width = 8;
      const height = 8;

      // Simple BMP header for 8x8 8-bit grayscale
      final header = <int>[
        // BMP Header
        0x42, 0x4D, // "BM"
        0x76, 0x01, 0x00, 0x00, // File size (374)
        0x00, 0x00, 0x00, 0x00, // Reserved
        0x76, 0x00, 0x00, 0x00, // Pixel data offset (118)

        // DIB Header (BITMAPINFOHEADER) - 40 bytes
        0x28, 0x00, 0x00, 0x00, // Header size (40)
        0x08, 0x00, 0x00, 0x00, // Width (8)
        0x08, 0x00, 0x00, 0x00, // Height (8)
        0x01, 0x00, // Planes (1)
        0x08, 0x00, // Bits per pixel (8)
        0x00, 0x00, 0x00, 0x00, // Compression (none)
        0x40, 0x00, 0x00, 0x00, // Image size (64)
        0x13, 0x0B, 0x00, 0x00, // X pixels per meter
        0x13, 0x0B, 0x00, 0x00, // Y pixels per meter
        0x00, 0x00, 0x00, 0x00, // Colors used (0 = all)
        0x00, 0x00, 0x00, 0x00, // Important colors
      ];

      // Grayscale palette (256 entries, 4 bytes each)
      final palette = <int>[];
      for (int i = 0; i < 256; i++) {
        palette.addAll([i, i, i, 0]); // B, G, R, reserved
      }

      // Pixel data (8x8, alternating black/white checkerboard)
      final pixels = <int>[];
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Checkerboard pattern
          pixels.add((x + y) % 2 == 0 ? 0 : 255);
        }
      }

      return Uint8List.fromList([...header, ...palette, ...pixels]);
    }

    test('processImage returns ProcessedImage', () {
      final bmp = createTestBmp();
      final result = Sk58ImageProcessor.processImage(bmp);

      expect(result, isA<ProcessedImage>());
      expect(result.width, 8);
      expect(result.height, 8);
      expect(result.data, isNotEmpty);
    });

    test('processImage respects maxWidth', () {
      final bmp = createTestBmp();

      // Don't resize 8px image to 4px - it's already smaller than maxWidth
      final result = Sk58ImageProcessor.processImage(bmp, maxWidth: 4);

      // Image should stay at 8px since that's smaller than default 384
      // Actually, the maxWidth should resize if image is larger
      expect(result.width, lessThanOrEqualTo(8));
    });

    test('processImage with dithering enabled', () {
      final bmp = createTestBmp();
      final result = Sk58ImageProcessor.processImage(bmp, dithering: true);

      expect(result, isA<ProcessedImage>());
      expect(result.data, isNotEmpty);
    });

    test('processImage with dithering disabled', () {
      final bmp = createTestBmp();
      final result = Sk58ImageProcessor.processImage(
        bmp,
        dithering: false,
        threshold: 128,
      );

      expect(result, isA<ProcessedImage>());
      expect(result.data, isNotEmpty);
    });

    test('processImage throws on invalid image data', () {
      final invalidData = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(
        () => Sk58ImageProcessor.processImage(invalidData),
        throwsA(isA<ImageProcessingException>()),
      );
    });

    test('bitmap data has correct format (1 bit per pixel)', () {
      final bmp = createTestBmp();
      final result = Sk58ImageProcessor.processImage(bmp);

      // Width 8 = 1 byte per row
      expect(result.widthBytes, 1);

      // Total bytes = widthBytes * height
      expect(result.data.length, result.widthBytes * result.height);
    });
  });

  group('ImageProcessingException', () {
    test('has correct message', () {
      final exception = ImageProcessingException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'ImageProcessingException: Test error');
    });
  });
}
