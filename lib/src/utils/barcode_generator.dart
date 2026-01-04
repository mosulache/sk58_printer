/// Barcode generation utilities for SK58 thermal printer.
library;

/// Supported barcode types for ESC/POS printers.
enum BarcodeType {
  /// Code 128 - High density, alphanumeric.
  /// Supports: ASCII 0-127.
  code128(73, 'Code 128'),

  /// EAN-13 - European Article Number.
  /// Requires exactly 13 digits (or 12 + auto checksum).
  ean13(67, 'EAN-13'),

  /// UPC-A - Universal Product Code.
  /// Requires exactly 12 digits (or 11 + auto checksum).
  upcA(65, 'UPC-A'),

  /// Code 39 - Alphanumeric, self-checking.
  /// Supports: 0-9, A-Z, space, - . $ / + %
  code39(69, 'Code 39');

  /// The ESC/POS command code for this barcode type.
  final int commandCode;

  /// Human-readable name of the barcode type.
  final String displayName;

  const BarcodeType(this.commandCode, this.displayName);
}

/// Position of Human Readable Interpretation (HRI) text.
enum BarcodeHriPosition {
  /// No HRI text printed.
  none(0),

  /// HRI text above the barcode.
  above(1),

  /// HRI text below the barcode.
  below(2),

  /// HRI text both above and below.
  both(3);

  /// The ESC/POS value for this position.
  final int value;

  const BarcodeHriPosition(this.value);
}

/// Barcode configuration options.
class BarcodeConfig {
  /// Height of barcode in dots (1-255). Default is 80.
  final int height;

  /// Width multiplier (2-6). Default is 3.
  final int width;

  /// Position of human readable text. Default is below.
  final BarcodeHriPosition hriPosition;

  /// Creates barcode configuration.
  const BarcodeConfig({
    this.height = 80,
    this.width = 3,
    this.hriPosition = BarcodeHriPosition.below,
  });

  /// Default barcode configuration.
  static const BarcodeConfig defaultConfig = BarcodeConfig();
}

/// ESC/POS barcode command generator.
class BarcodeCommands {
  BarcodeCommands._();

  /// Set barcode height.
  /// [height] - Height in dots (1-255).
  static List<int> setHeight(int height) {
    return [0x1D, 0x68, height.clamp(1, 255)];
  }

  /// Set barcode width.
  /// [width] - Width multiplier (2-6).
  static List<int> setWidth(int width) {
    return [0x1D, 0x77, width.clamp(2, 6)];
  }

  /// Set HRI (Human Readable Interpretation) position.
  static List<int> setHriPosition(BarcodeHriPosition position) {
    return [0x1D, 0x48, position.value];
  }

  /// Set HRI font (0 = Font A, 1 = Font B).
  static List<int> setHriFont(int font) {
    return [0x1D, 0x66, font.clamp(0, 1)];
  }

  /// Generate barcode print commands.
  ///
  /// [data] - The data to encode.
  /// [type] - Type of barcode.
  /// [config] - Barcode configuration (height, width, HRI position).
  ///
  /// Returns list of ESC/POS command bytes.
  static List<int> printBarcode(
    String data,
    BarcodeType type, {
    BarcodeConfig config = BarcodeConfig.defaultConfig,
  }) {
    // Validate data for specific barcode types
    _validateBarcodeData(data, type);

    final List<int> commands = [];

    // Set barcode height
    commands.addAll(setHeight(config.height));

    // Set barcode width
    commands.addAll(setWidth(config.width));

    // Set HRI position
    commands.addAll(setHriPosition(config.hriPosition));

    // Set HRI font to Font A (more readable)
    commands.addAll(setHriFont(0));

    // GS k m n d1...dn (Function B format)
    // 0x1D 0x6B m n d1...dn
    final dataBytes = data.codeUnits;
    commands.addAll([
      0x1D, // GS
      0x6B, // k
      type.commandCode, // m (barcode type)
      dataBytes.length, // n (data length)
    ]);
    commands.addAll(dataBytes);

    return commands;
  }

  /// Validate barcode data for the specific type.
  static void _validateBarcodeData(String data, BarcodeType type) {
    switch (type) {
      case BarcodeType.ean13:
        if (data.length < 12 || data.length > 13) {
          throw BarcodeException(
            'EAN-13 requires 12-13 digits, got ${data.length}',
          );
        }
        if (!_isNumeric(data)) {
          throw BarcodeException('EAN-13 requires only digits');
        }
        break;

      case BarcodeType.upcA:
        if (data.length < 11 || data.length > 12) {
          throw BarcodeException(
            'UPC-A requires 11-12 digits, got ${data.length}',
          );
        }
        if (!_isNumeric(data)) {
          throw BarcodeException('UPC-A requires only digits');
        }
        break;

      case BarcodeType.code39:
        // Code 39 supports: 0-9, A-Z, space, - . $ / + %
        final validChars = RegExp(r'^[0-9A-Z\s\-\.\$\/\+\%]+$');
        if (!validChars.hasMatch(data.toUpperCase())) {
          throw BarcodeException(
            'Code 39 supports only: 0-9, A-Z, space, - . \$ / + %',
          );
        }
        break;

      case BarcodeType.code128:
        // Code 128 supports ASCII 0-127
        if (data.codeUnits.any((c) => c > 127)) {
          throw BarcodeException('Code 128 supports only ASCII characters');
        }
        break;
    }
  }

  /// Check if string contains only digits.
  static bool _isNumeric(String s) {
    return RegExp(r'^[0-9]+$').hasMatch(s);
  }
}

/// Exception thrown when barcode data is invalid.
class BarcodeException implements Exception {
  /// Error message describing the problem.
  final String message;

  /// Creates a barcode exception.
  BarcodeException(this.message);

  @override
  String toString() => 'BarcodeException: $message';
}
