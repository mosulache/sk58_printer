/// ESC/POS commands for SK58 thermal printer.
library;

import 'dart:typed_data';

import '../utils/barcode_generator.dart';

/// ESC/POS command builder for SK58 printer.
///
/// This class provides static methods to generate ESC/POS command bytes
/// for various printing operations.
class EscPosCommands {
  EscPosCommands._();

  // ==========================================================================
  // BASIC COMMANDS
  // ==========================================================================

  /// Initialize printer - resets to default settings.
  static List<int> get initialize => [0x1B, 0x40];

  /// Line feed - advances paper by one line.
  static List<int> get lineFeed => [0x0A];

  /// Generate multiple line feeds.
  static List<int> feedLines(int count) {
    return List<int>.filled(count, 0x0A);
  }

  // ==========================================================================
  // TEXT ALIGNMENT
  // ==========================================================================

  /// Set text alignment.
  ///
  /// - 0 = left
  /// - 1 = center
  /// - 2 = right
  static List<int> setAlignment(int align) => [0x1B, 0x61, align];

  /// Set left alignment.
  static List<int> get alignLeft => setAlignment(0);

  /// Set center alignment.
  static List<int> get alignCenter => setAlignment(1);

  /// Set right alignment.
  static List<int> get alignRight => setAlignment(2);

  // ==========================================================================
  // TEXT STYLE
  // ==========================================================================

  /// Enable/disable bold text.
  static List<int> setBold(bool enabled) => [0x1B, 0x45, enabled ? 1 : 0];

  /// Enable/disable underline.
  static List<int> setUnderline(bool enabled) => [0x1B, 0x2D, enabled ? 1 : 0];

  /// Set character size.
  ///
  /// [width] and [height] can be 1-8 (multiplier).
  static List<int> setCharacterSize({int width = 1, int height = 1}) {
    final w = (width - 1).clamp(0, 7);
    final h = (height - 1).clamp(0, 7);
    return [0x1D, 0x21, (w << 4) | h];
  }

  /// Reset character size to normal.
  static List<int> get resetSize => setCharacterSize(width: 1, height: 1);

  /// Double width text.
  static List<int> get doubleWidth => setCharacterSize(width: 2, height: 1);

  /// Double height text.
  static List<int> get doubleHeight => setCharacterSize(width: 1, height: 2);

  /// Double width and height text.
  static List<int> get doubleSize => setCharacterSize(width: 2, height: 2);

  // ==========================================================================
  // QR CODE
  // ==========================================================================

  /// Generate QR code print commands.
  ///
  /// [data] - The string data to encode in the QR code.
  /// [moduleSize] - Size of each QR module (1-16, default 8).
  /// [errorCorrectionLevel] - Error correction level:
  ///   - 0x30 = L (7%)
  ///   - 0x31 = M (15%)
  ///   - 0x32 = Q (25%)
  ///   - 0x33 = H (30%)
  static List<int> printQrCode(
    String data, {
    int moduleSize = 8,
    int errorCorrectionLevel = 0x33,
  }) {
    final List<int> commands = [];

    // QR Code: Select model (Model 2)
    commands.addAll([
      0x1D, 0x28, 0x6B, // GS ( k
      0x04, 0x00, // pL pH (4 bytes follow)
      0x31, 0x41, // cn fn (select model)
      0x32, 0x00, // m1 m2 (Model 2)
    ]);

    // QR Code: Set module size
    commands.addAll([
      0x1D, 0x28, 0x6B, // GS ( k
      0x03, 0x00, // pL pH (3 bytes follow)
      0x31, 0x43, // cn fn (set size)
      moduleSize.clamp(1, 16), // n (module size)
    ]);

    // QR Code: Set error correction level
    commands.addAll([
      0x1D, 0x28, 0x6B, // GS ( k
      0x03, 0x00, // pL pH (3 bytes follow)
      0x31, 0x45, // cn fn (set error correction)
      errorCorrectionLevel, // n (error correction level)
    ]);

    // QR Code: Store data
    final qrData = data.codeUnits;
    final qrDataLength = qrData.length + 3;
    final pL = qrDataLength & 0xFF;
    final pH = (qrDataLength >> 8) & 0xFF;

    commands.addAll([
      0x1D, 0x28, 0x6B, // GS ( k
      pL, pH, // pL pH (data length + 3)
      0x31, 0x50, 0x30, // cn fn m (store data)
    ]);
    commands.addAll(qrData);

    // QR Code: Print
    commands.addAll([
      0x1D, 0x28, 0x6B, // GS ( k
      0x03, 0x00, // pL pH (3 bytes follow)
      0x31, 0x51, 0x30, // cn fn m (print)
    ]);

    return commands;
  }

  // ==========================================================================
  // BARCODE
  // ==========================================================================

  /// Generate barcode print commands.
  ///
  /// [data] - The data to encode in the barcode.
  /// [type] - Type of barcode (Code128, EAN13, UPC-A, Code39).
  /// [config] - Barcode configuration (height, width, HRI position).
  ///
  /// Example:
  /// ```dart
  /// final commands = EscPosCommands.printBarcode(
  ///   '123456789012',
  ///   BarcodeType.code128,
  /// );
  /// ```
  static List<int> printBarcode(
    String data,
    BarcodeType type, {
    BarcodeConfig config = BarcodeConfig.defaultConfig,
  }) {
    return BarcodeCommands.printBarcode(data, type, config: config);
  }

  // ==========================================================================
  // TEXT ENCODING
  // ==========================================================================

  /// Encode text to bytes for printing.
  ///
  /// Uses Latin-1 encoding which covers basic ASCII and extended characters.
  static List<int> encodeText(String text) {
    return text.codeUnits;
  }

  /// Create a complete text print command with optional styling.
  static List<int> textCommand(
    String text, {
    int? alignment,
    bool bold = false,
    bool underline = false,
    int widthMultiplier = 1,
    int heightMultiplier = 1,
  }) {
    final List<int> commands = [];

    if (alignment != null) {
      commands.addAll(setAlignment(alignment));
    }

    if (bold) {
      commands.addAll(setBold(true));
    }

    if (underline) {
      commands.addAll(setUnderline(true));
    }

    if (widthMultiplier > 1 || heightMultiplier > 1) {
      commands.addAll(setCharacterSize(
        width: widthMultiplier,
        height: heightMultiplier,
      ));
    }

    commands.addAll(encodeText(text));
    commands.add(0x0A); // Line feed after text

    // Reset styles
    if (bold) {
      commands.addAll(setBold(false));
    }
    if (underline) {
      commands.addAll(setUnderline(false));
    }
    if (widthMultiplier > 1 || heightMultiplier > 1) {
      commands.addAll(resetSize);
    }

    return commands;
  }

  // ==========================================================================
  // UTILITY
  // ==========================================================================

  /// Convert command list to Uint8List for transmission.
  static Uint8List toBytes(List<int> commands) {
    return Uint8List.fromList(commands);
  }
}
