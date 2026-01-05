/// High-level API for SK58 thermal printer.
library;

import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import '../driver/printer_config.dart';
import '../driver/printer_connection.dart';
import '../utils/barcode_generator.dart';
import '../utils/image_processor.dart';
import 'esc_pos_commands.dart';
import 'label_commands.dart';
import 'print_builder.dart';
import 'templates.dart';
import 'text_style.dart';

/// High-level API for interacting with SK58 thermal printer.
///
/// This class provides a simple interface for printing text, QR codes,
/// and controlling the printer.
///
/// Usage:
/// ```dart
/// // Connect to a discovered device
/// final printer = await Sk58Printer.connect(device);
///
/// // Print some text
/// await printer.printText('Hello World!');
/// await printer.printText('Centered', align: Sk58Align.center);
/// await printer.printText('BOLD', style: Sk58TextStyle.boldStyle);
///
/// // Print a QR code
/// await printer.printQrCode('https://example.com');
///
/// // Feed paper and disconnect
/// await printer.feedLines(3);
/// await printer.disconnect();
/// ```
class Sk58Printer {
  final Sk58Connection _connection;

  Sk58Printer._(this._connection);

  /// Connects to a Bluetooth device and returns a printer instance.
  ///
  /// [device] - The BLE device to connect to (from [Sk58Scanner]).
  ///
  /// Throws [Sk58ConnectionException] if connection fails.
  static Future<Sk58Printer> connect(BleDevice device) async {
    final connection = Sk58Connection();
    await connection.connect(device);

    final printer = Sk58Printer._(connection);

    // Initialize printer
    await printer._initialize();

    return printer;
  }

  /// Whether the printer is currently connected.
  bool get isConnected => _connection.isConnected;

  /// The connected device, if any.
  BleDevice? get device => _connection.connectedDevice;

  /// Initializes the printer to default state.
  Future<void> _initialize() async {
    await _connection.writeCommands(EscPosCommands.initialize);
  }

  /// Prints text with optional styling and alignment.
  ///
  /// [text] - The text to print.
  /// [style] - Text style (bold, underline, size). Defaults to normal.
  /// [align] - Text alignment. Defaults to left.
  ///
  /// Example:
  /// ```dart
  /// await printer.printText('Normal text');
  /// await printer.printText('Centered', align: Sk58Align.center);
  /// await printer.printText('BOLD', style: Sk58TextStyle.boldStyle);
  /// await printer.printText('Big & Bold',
  ///   style: Sk58TextStyle(bold: true, size: Sk58FontSize.large),
  ///   align: Sk58Align.center,
  /// );
  /// ```
  Future<void> printText(
    String text, {
    Sk58TextStyle style = const Sk58TextStyle(),
    Sk58Align align = Sk58Align.left,
  }) async {
    final commands = EscPosCommands.textCommand(
      text,
      alignment: align.value,
      bold: style.bold,
      underline: style.underline,
      widthMultiplier: style.size.widthMultiplier,
      heightMultiplier: style.size.heightMultiplier,
    );

    await _connection.writeCommands(commands);
  }

  /// Prints a QR code.
  ///
  /// [data] - The data to encode in the QR code (URL, text, etc.).
  /// [size] - Module size (1-16). Default is 8.
  /// [errorCorrection] - Error correction level:
  ///   - [QrErrorCorrection.L] - 7% recovery
  ///   - [QrErrorCorrection.M] - 15% recovery
  ///   - [QrErrorCorrection.Q] - 25% recovery
  ///   - [QrErrorCorrection.H] - 30% recovery (default)
  /// [centered] - Whether to center the QR code. Default is true.
  ///
  /// Example:
  /// ```dart
  /// await printer.printQrCode('https://example.com');
  /// await printer.printQrCode('Small QR', size: 4);
  /// ```
  Future<void> printQrCode(
    String data, {
    int size = 8,
    QrErrorCorrection errorCorrection = QrErrorCorrection.H,
    bool centered = true,
  }) async {
    final List<int> commands = [];

    // Set alignment if centering
    if (centered) {
      commands.addAll(EscPosCommands.alignCenter);
    }

    // Add QR code commands
    commands.addAll(EscPosCommands.printQrCode(
      data,
      moduleSize: size,
      errorCorrectionLevel: errorCorrection.value,
    ));

    // Add line feed after QR
    commands.addAll(EscPosCommands.lineFeed);

    // Reset alignment to left
    if (centered) {
      commands.addAll(EscPosCommands.alignLeft);
    }

    await _connection.writeCommands(commands);
  }

  /// Prints a barcode.
  ///
  /// [data] - The data to encode in the barcode.
  /// [type] - Type of barcode. Default is Code128.
  /// [height] - Barcode height in dots (1-255). Default is 80.
  /// [width] - Width multiplier (2-6). Default is 3.
  /// [hriPosition] - Position of human readable text. Default is below.
  /// [centered] - Whether to center the barcode. Default is true.
  ///
  /// Example:
  /// ```dart
  /// await printer.printBarcode('123456789012', BarcodeType.code128);
  /// await printer.printBarcode('5901234123457', BarcodeType.ean13);
  /// ```
  ///
  /// Throws [BarcodeException] if data is invalid for the barcode type.
  Future<void> printBarcode(
    String data, {
    BarcodeType type = BarcodeType.code128,
    int height = 80,
    int width = 3,
    BarcodeHriPosition hriPosition = BarcodeHriPosition.below,
    bool centered = true,
  }) async {
    final config = BarcodeConfig(
      height: height,
      width: width,
      hriPosition: hriPosition,
    );

    final List<int> commands = [];

    // Set alignment if centering
    if (centered) {
      commands.addAll(EscPosCommands.alignCenter);
    }

    // Add barcode commands
    commands.addAll(EscPosCommands.printBarcode(data, type, config: config));

    // Add line feed after barcode
    commands.addAll(EscPosCommands.lineFeed);

    // Reset alignment to left
    if (centered) {
      commands.addAll(EscPosCommands.alignLeft);
    }

    await _connection.writeCommands(commands);
  }

  /// Prints an image.
  ///
  /// [imageBytes] - Raw image bytes (PNG, JPEG, GIF, etc.).
  /// [maxWidth] - Maximum width in pixels. Default is 384 (full width for 58mm).
  /// [dithering] - Apply Floyd-Steinberg dithering for better grayscale. Default is true.
  /// [threshold] - Brightness threshold for B&W (0-255). Default is 128.
  /// [centered] - Whether to center the image. Default is true.
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await File('logo.png').readAsBytes();
  /// await printer.printImage(imageBytes);
  /// await printer.printImage(imageBytes, maxWidth: 200); // smaller
  /// ```
  ///
  /// Throws [ImageProcessingException] if image cannot be processed.
  Future<void> printImage(
    Uint8List imageBytes, {
    int maxWidth = sk58MaxWidth,
    bool dithering = true,
    int threshold = 128,
    bool centered = true,
  }) async {
    // Process image
    final processed = Sk58ImageProcessor.processImage(
      imageBytes,
      maxWidth: maxWidth,
      dithering: dithering,
      threshold: threshold,
    );

    final List<int> commands = [];

    // Center if needed
    if (centered) {
      commands.addAll(EscPosCommands.alignCenter);
    }

    // Add image commands
    commands.addAll(processed.toCommands());

    // Add line feed
    commands.addAll(EscPosCommands.lineFeed);

    // Reset alignment
    if (centered) {
      commands.addAll(EscPosCommands.alignLeft);
    }

    await _connection.writeCommands(commands);
  }

  /// Feeds the specified number of lines.
  ///
  /// [count] - Number of lines to feed. Default is 1.
  Future<void> feedLines([int count = 1]) async {
    await _connection.writeCommands(EscPosCommands.feedLines(count));
  }

  /// Prints a line feed.
  Future<void> lineFeed() async {
    await _connection.writeCommands(EscPosCommands.lineFeed);
  }

  /// Prints a horizontal line (using dashes).
  ///
  /// [width] - Number of characters. Default is 32 (full width for 58mm).
  /// [char] - Character to use for the line. Default is '-'.
  Future<void> printLine({int width = 32, String char = '-'}) async {
    final line = char * width;
    await printText(line);
  }

  /// Prints a template (label, receipt, etc.).
  ///
  /// [template] - The template to print (Sk58Label, Sk58TwoColumnLabel, etc.).
  ///
  /// Example:
  /// ```dart
  /// await printer.printTemplate(
  ///   Sk58Label(
  ///     title: 'TORX 4x50',
  ///     subtitle: 'Cap T20 - Inox A2',
  ///     qrData: 'SKU-12345',
  ///   ),
  /// );
  /// ```
  Future<void> printTemplate(Sk58Template template) async {
    final commands = template.toCommands();
    await _connection.writeCommands(commands);
  }

  /// Creates a fluent print builder for complex print jobs.
  ///
  /// Example:
  /// ```dart
  /// await printer.build()
  ///   .header('RECEIPT')
  ///   .line()
  ///   .row('Item 1', '\$10.00')
  ///   .row('Item 2', '\$15.00')
  ///   .doubleLine()
  ///   .row('TOTAL', '\$25.00')
  ///   .feed(3)
  ///   .execute();
  /// ```
  Sk58PrintBuilder build() {
    return Sk58PrintBuilder((commands) => printRaw(commands));
  }

  /// Prints raw ESC/POS commands.
  ///
  /// For advanced users who need direct control.
  Future<void> printRaw(List<int> commands) async {
    await _connection.writeCommands(commands);
  }

  /// Prints raw bytes.
  ///
  /// For advanced users who need direct control.
  Future<void> printBytes(Uint8List data) async {
    await _connection.writeData(data);
  }

  /// Resets the printer to default state.
  Future<void> reset() async {
    await _initialize();
  }

  /// Disconnects from the printer.
  Future<void> disconnect() async {
    await _connection.disconnect();
  }

  // ==========================================================================
  // LABEL PRINTING METHODS
  // ==========================================================================

  /// Configure printer for label printing.
  ///
  /// [labelSize] - Predefined label size from [Sk58LabelSize].
  /// [paperType] - Paper type (gap or black mark detection).
  /// [density] - Print density 1-5 (default 3).
  /// [speed] - Print speed 1-3 (default 2).
  ///
  /// Example:
  /// ```dart
  /// await printer.configureForLabel(
  ///   Sk58LabelSize.label50x30,
  ///   paperType: Sk58PaperType.labelWithGap,
  /// );
  /// await printer.printText('Product Name');
  /// await printer.feedToNextLabel();
  /// ```
  Future<void> configureForLabel(
    Sk58LabelSize labelSize, {
    Sk58PaperType paperType = Sk58PaperType.labelWithGap,
    int density = 3,
    int speed = 2,
  }) async {
    final config = LabelPrintConfig(
      paperType: paperType,
      widthMm: labelSize.widthMm.toDouble(),
      heightMm: labelSize.heightMm.toDouble(),
      density: density,
      speed: speed,
    );
    await _connection.writeCommands(config.toCommands());
  }

  /// Configure printer for custom label size.
  ///
  /// [widthMm] - Label width in mm (max printable: 48mm).
  /// [heightMm] - Label height in mm.
  /// [paperType] - Paper type (gap or black mark detection).
  /// [density] - Print density 1-5 (default 3).
  /// [speed] - Print speed 1-3 (default 2).
  Future<void> configureForCustomLabel({
    required double widthMm,
    required double heightMm,
    Sk58PaperType paperType = Sk58PaperType.labelWithGap,
    int density = 3,
    int speed = 2,
  }) async {
    final config = LabelPrintConfig(
      paperType: paperType,
      widthMm: widthMm,
      heightMm: heightMm,
      density: density,
      speed: speed,
    );
    await _connection.writeCommands(config.toCommands());
  }

  /// Set paper type for label detection.
  ///
  /// [type] - Paper type: continuous, gap detection, or black mark.
  Future<void> setPaperType(Sk58PaperType type) async {
    await _connection.writeCommands(LabelCommands.setPaperType(type));
  }

  /// Feed paper to the next label.
  ///
  /// In label mode, this advances to the next label gap/mark.
  /// In continuous mode, this acts as a form feed/page break.
  Future<void> feedToNextLabel() async {
    await _connection.writeCommands(LabelCommands.feedToNextLabel);
  }

  /// Calibrate label detection.
  ///
  /// Call this after loading new paper to help the printer
  /// detect label boundaries correctly.
  Future<void> calibrateLabels() async {
    await _connection.writeCommands(LabelCommands.calibrateLabels);
  }

  /// Set print density (darkness).
  ///
  /// [level] - Density level 1-5 (1=lightest, 5=darkest).
  Future<void> setDensity(int level) async {
    await _connection.writeCommands(LabelCommands.setPrintDensity(level));
  }

  /// Set print speed.
  ///
  /// [level] - Speed level 1-3 (1=slowest/best quality, 3=fastest).
  Future<void> setSpeed(int level) async {
    await _connection.writeCommands(LabelCommands.setPrintSpeed(level));
  }

  /// Set print rotation.
  ///
  /// [degrees] - Rotation: 0, 90, 180, or 270 degrees.
  Future<void> setRotation(int degrees) async {
    await _connection.writeCommands(LabelCommands.setRotation(degrees));
  }

  /// Get characters per line for a label size.
  ///
  /// Useful for calculating text wrapping and formatting.
  int getCharsPerLine(Sk58LabelSize labelSize) {
    return labelSize.charsPerLine;
  }

  /// Get characters per line for current effective print width.
  ///
  /// Returns 32 characters (for 48mm / 384 dots at 12 dots/char).
  int get maxCharsPerLine => Sk58Specs.charsPerLine(Sk58Specs.effectivePrintWidthMm);
}

/// QR code error correction levels.
enum QrErrorCorrection {
  /// Low - 7% recovery capacity.
  L(0x30),

  /// Medium - 15% recovery capacity.
  M(0x31),

  /// Quartile - 25% recovery capacity.
  Q(0x32),

  /// High - 30% recovery capacity.
  H(0x33);

  /// The ESC/POS command value for this error correction level.
  final int value;

  const QrErrorCorrection(this.value);
}
