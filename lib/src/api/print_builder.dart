/// Fluent builder for creating complex print jobs.
library;

import 'dart:typed_data';

import '../utils/barcode_generator.dart';
import '../utils/image_processor.dart';
import 'esc_pos_commands.dart';
import 'text_style.dart';

/// Fluent builder for creating complex print jobs.
///
/// Example:
/// ```dart
/// await printer.build()
///   .text('HEADER', style: Sk58TextStyle.boldLarge, align: Sk58Align.center)
///   .line()
///   .text('Item 1')
///   .text('Item 2')
///   .qrCode('https://example.com')
///   .feed(3)
///   .execute();
/// ```
class Sk58PrintBuilder {
  final List<int> _commands = [];
  final Future<void> Function(List<int>) _executor;

  /// Creates a new print builder.
  ///
  /// [executor] - Function to execute the final commands (usually printer.printRaw).
  Sk58PrintBuilder(this._executor);

  /// Add text to the print job.
  ///
  /// [text] - The text to print.
  /// [style] - Text style (bold, underline, size). Default is normal.
  /// [align] - Text alignment. Default is left.
  Sk58PrintBuilder text(
    String text, {
    Sk58TextStyle style = const Sk58TextStyle(),
    Sk58Align align = Sk58Align.left,
  }) {
    _commands.addAll(EscPosCommands.textCommand(
      text,
      alignment: align.value,
      bold: style.bold,
      underline: style.underline,
      widthMultiplier: style.size.widthMultiplier,
      heightMultiplier: style.size.heightMultiplier,
    ));
    return this;
  }

  /// Add a QR code to the print job.
  ///
  /// [data] - Data to encode in the QR code.
  /// [size] - Module size (1-16). Default is 8.
  /// [centered] - Whether to center the QR code. Default is true.
  Sk58PrintBuilder qrCode(
    String data, {
    int size = 8,
    bool centered = true,
  }) {
    if (centered) {
      _commands.addAll(EscPosCommands.alignCenter);
    }
    _commands.addAll(EscPosCommands.printQrCode(data, moduleSize: size));
    _commands.addAll(EscPosCommands.lineFeed);
    if (centered) {
      _commands.addAll(EscPosCommands.alignLeft);
    }
    return this;
  }

  /// Add a barcode to the print job.
  ///
  /// [data] - Data to encode in the barcode.
  /// [type] - Type of barcode. Default is Code128.
  /// [height] - Barcode height in dots. Default is 80.
  /// [width] - Width multiplier (2-6). Default is 3.
  /// [hriPosition] - Position of human readable text. Default is below.
  /// [centered] - Whether to center the barcode. Default is true.
  Sk58PrintBuilder barcode(
    String data, {
    BarcodeType type = BarcodeType.code128,
    int height = 80,
    int width = 3,
    BarcodeHriPosition hriPosition = BarcodeHriPosition.below,
    bool centered = true,
  }) {
    if (centered) {
      _commands.addAll(EscPosCommands.alignCenter);
    }
    _commands.addAll(EscPosCommands.printBarcode(
      data,
      type,
      config: BarcodeConfig(
        height: height,
        width: width,
        hriPosition: hriPosition,
      ),
    ));
    _commands.addAll(EscPosCommands.lineFeed);
    if (centered) {
      _commands.addAll(EscPosCommands.alignLeft);
    }
    return this;
  }

  /// Add an image to the print job.
  ///
  /// [imageBytes] - Raw image bytes (PNG, JPEG, etc.).
  /// [maxWidth] - Maximum width in pixels. Default is 384.
  /// [dithering] - Apply Floyd-Steinberg dithering. Default is true.
  /// [threshold] - Brightness threshold (0-255). Default is 128.
  /// [centered] - Whether to center the image. Default is true.
  Sk58PrintBuilder image(
    Uint8List imageBytes, {
    int maxWidth = sk58MaxWidth,
    bool dithering = true,
    int threshold = 128,
    bool centered = true,
  }) {
    final processed = Sk58ImageProcessor.processImage(
      imageBytes,
      maxWidth: maxWidth,
      dithering: dithering,
      threshold: threshold,
    );

    if (centered) {
      _commands.addAll(EscPosCommands.alignCenter);
    }
    _commands.addAll(processed.toCommands());
    _commands.addAll(EscPosCommands.lineFeed);
    if (centered) {
      _commands.addAll(EscPosCommands.alignLeft);
    }
    return this;
  }

  /// Add a horizontal line.
  ///
  /// [width] - Number of characters. Default is 32.
  /// [char] - Character to use. Default is '-'.
  Sk58PrintBuilder line({int width = 32, String char = '-'}) {
    _commands.addAll(EscPosCommands.encodeText(char * width));
    _commands.addAll(EscPosCommands.lineFeed);
    return this;
  }

  /// Add a double line separator.
  ///
  /// [width] - Number of characters. Default is 32.
  Sk58PrintBuilder doubleLine({int width = 32}) {
    return line(width: width, char: '=');
  }

  /// Add empty lines (paper feed).
  ///
  /// [count] - Number of lines to feed. Default is 1.
  Sk58PrintBuilder feed([int count = 1]) {
    _commands.addAll(EscPosCommands.feedLines(count));
    return this;
  }

  /// Add a single line feed.
  Sk58PrintBuilder newLine() {
    _commands.addAll(EscPosCommands.lineFeed);
    return this;
  }

  /// Set text alignment for subsequent text.
  ///
  /// Note: This affects text added after this call until changed.
  Sk58PrintBuilder align(Sk58Align alignment) {
    _commands.addAll(EscPosCommands.setAlignment(alignment.value));
    return this;
  }

  /// Add raw ESC/POS commands.
  Sk58PrintBuilder raw(List<int> commands) {
    _commands.addAll(commands);
    return this;
  }

  /// Add two-column text (left and right aligned).
  ///
  /// [left] - Text on the left side.
  /// [right] - Text on the right side.
  /// [width] - Total line width. Default is 32.
  Sk58PrintBuilder row(String left, String right, {int width = 32}) {
    final padding = width - left.length - right.length;
    final spaces = padding > 0 ? ' ' * padding : ' ';
    final line = '$left$spaces$right';
    _commands.addAll(EscPosCommands.encodeText(
      line.length > width ? line.substring(0, width) : line,
    ));
    _commands.addAll(EscPosCommands.lineFeed);
    return this;
  }

  /// Add bold text.
  Sk58PrintBuilder bold(String text, {Sk58Align align = Sk58Align.left}) {
    return this.text(text, style: Sk58TextStyle.boldStyle, align: align);
  }

  /// Add large centered text (typically for headers).
  Sk58PrintBuilder header(String text) {
    return this.text(
      text,
      style: const Sk58TextStyle(bold: true, size: Sk58FontSize.large),
      align: Sk58Align.center,
    );
  }

  /// Execute the print job.
  ///
  /// Sends all accumulated commands to the printer.
  Future<void> execute() async {
    if (_commands.isEmpty) return;
    await _executor(_commands);
  }

  /// Get the accumulated commands without executing.
  ///
  /// Useful for debugging or batch operations.
  List<int> getCommands() => List.unmodifiable(_commands);

  /// Clear all accumulated commands.
  void clear() {
    _commands.clear();
  }
}
