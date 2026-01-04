/// High-level API for SK58 thermal printer.
library;

import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import '../driver/printer_connection.dart';
import 'esc_pos_commands.dart';
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
