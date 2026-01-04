/// Generic label templates for SK58 thermal printer.
library;

import '../utils/barcode_generator.dart';
import 'esc_pos_commands.dart';
import 'text_style.dart';

/// Base class for all printable templates.
abstract class Sk58Template {
  /// Generates the ESC/POS commands for this template.
  List<int> toCommands();
}

/// A simple label with title, optional subtitle, and optional QR/barcode.
///
/// Example:
/// ```dart
/// final label = Sk58Label(
///   title: 'TORX 4x50',
///   subtitle: 'Cap T20 - Inox A2',
///   qrData: 'SKU-12345',
/// );
/// await printer.printTemplate(label);
/// ```
class Sk58Label extends Sk58Template {
  /// Main title text (required).
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional QR code data. If provided, prints a QR code.
  final String? qrData;

  /// Optional barcode data. If provided, prints a barcode.
  /// Note: If both qrData and barcodeData are provided, only QR is printed.
  final String? barcodeData;

  /// Barcode type if using barcode. Default is Code128.
  final BarcodeType barcodeType;

  /// Title text style. Default is bold large centered.
  final Sk58TextStyle titleStyle;

  /// Subtitle text style. Default is normal centered.
  final Sk58TextStyle subtitleStyle;

  /// QR code size (1-16). Default is 6.
  final int qrSize;

  /// Lines to feed after label. Default is 3.
  final int feedAfter;

  /// Creates a simple label.
  Sk58Label({
    required this.title,
    this.subtitle,
    this.qrData,
    this.barcodeData,
    this.barcodeType = BarcodeType.code128,
    this.titleStyle = const Sk58TextStyle(
      bold: true,
      size: Sk58FontSize.large,
    ),
    this.subtitleStyle = const Sk58TextStyle(),
    this.qrSize = 6,
    this.feedAfter = 3,
  });

  @override
  List<int> toCommands() {
    final List<int> commands = [];

    // Center alignment
    commands.addAll(EscPosCommands.alignCenter);

    // Title
    commands.addAll(EscPosCommands.textCommand(
      title,
      alignment: Sk58Align.center.value,
      bold: titleStyle.bold,
      underline: titleStyle.underline,
      widthMultiplier: titleStyle.size.widthMultiplier,
      heightMultiplier: titleStyle.size.heightMultiplier,
    ));

    // Subtitle if provided
    if (subtitle != null && subtitle!.isNotEmpty) {
      commands.addAll(EscPosCommands.textCommand(
        subtitle!,
        alignment: Sk58Align.center.value,
        bold: subtitleStyle.bold,
        underline: subtitleStyle.underline,
        widthMultiplier: subtitleStyle.size.widthMultiplier,
        heightMultiplier: subtitleStyle.size.heightMultiplier,
      ));
    }

    // QR code or barcode
    if (qrData != null && qrData!.isNotEmpty) {
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.printQrCode(qrData!, moduleSize: qrSize));
      commands.addAll(EscPosCommands.lineFeed);
    } else if (barcodeData != null && barcodeData!.isNotEmpty) {
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.printBarcode(barcodeData!, barcodeType));
      commands.addAll(EscPosCommands.lineFeed);
    }

    // Reset alignment
    commands.addAll(EscPosCommands.alignLeft);

    // Feed lines
    if (feedAfter > 0) {
      commands.addAll(EscPosCommands.feedLines(feedAfter));
    }

    return commands;
  }
}

/// A label with a title and rows of key-value pairs.
///
/// Example:
/// ```dart
/// final label = Sk58TwoColumnLabel(
///   title: 'Product Info',
///   rows: [
///     ('Type', 'TORX'),
///     ('Size', '4x50mm'),
///     ('Head', 'T20'),
///   ],
/// );
/// await printer.printTemplate(label);
/// ```
class Sk58TwoColumnLabel extends Sk58Template {
  /// Title text displayed at the top.
  final String? title;

  /// List of key-value pairs to display.
  final List<(String key, String value)> rows;

  /// Optional QR code data.
  final String? qrData;

  /// Optional barcode data.
  final String? barcodeData;

  /// Barcode type if using barcode. Default is Code128.
  final BarcodeType barcodeType;

  /// Separator character between key and value. Default is ':'.
  final String separator;

  /// Width of the key column in characters. Default is 12.
  final int keyWidth;

  /// Total line width in characters. Default is 32 (for 58mm paper).
  final int lineWidth;

  /// Title text style. Default is bold centered.
  final Sk58TextStyle titleStyle;

  /// QR code size (1-16). Default is 6.
  final int qrSize;

  /// Lines to feed after label. Default is 3.
  final int feedAfter;

  /// Whether to print a separator line after title. Default is true.
  final bool showTitleSeparator;

  /// Creates a two-column label.
  Sk58TwoColumnLabel({
    this.title,
    required this.rows,
    this.qrData,
    this.barcodeData,
    this.barcodeType = BarcodeType.code128,
    this.separator = ':',
    this.keyWidth = 12,
    this.lineWidth = 32,
    this.titleStyle = const Sk58TextStyle(bold: true),
    this.qrSize = 6,
    this.feedAfter = 3,
    this.showTitleSeparator = true,
  });

  @override
  List<int> toCommands() {
    final List<int> commands = [];

    // Title if provided
    if (title != null && title!.isNotEmpty) {
      commands.addAll(EscPosCommands.textCommand(
        title!,
        alignment: Sk58Align.center.value,
        bold: titleStyle.bold,
        underline: titleStyle.underline,
        widthMultiplier: titleStyle.size.widthMultiplier,
        heightMultiplier: titleStyle.size.heightMultiplier,
      ));

      if (showTitleSeparator) {
        commands.addAll(EscPosCommands.encodeText('-' * lineWidth));
        commands.addAll(EscPosCommands.lineFeed);
      }
    }

    // Rows
    for (final (key, value) in rows) {
      final formattedLine = _formatRow(key, value);
      commands.addAll(EscPosCommands.encodeText(formattedLine));
      commands.addAll(EscPosCommands.lineFeed);
    }

    // QR code or barcode
    if (qrData != null && qrData!.isNotEmpty) {
      commands.addAll(EscPosCommands.alignCenter);
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.printQrCode(qrData!, moduleSize: qrSize));
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.alignLeft);
    } else if (barcodeData != null && barcodeData!.isNotEmpty) {
      commands.addAll(EscPosCommands.alignCenter);
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.printBarcode(barcodeData!, barcodeType));
      commands.addAll(EscPosCommands.lineFeed);
      commands.addAll(EscPosCommands.alignLeft);
    }

    // Feed lines
    if (feedAfter > 0) {
      commands.addAll(EscPosCommands.feedLines(feedAfter));
    }

    return commands;
  }

  /// Format a key-value row.
  String _formatRow(String key, String value) {
    final keyPart = '$key$separator'.padRight(keyWidth);
    final availableWidth = lineWidth - keyWidth;

    if (value.length > availableWidth) {
      // Truncate if too long
      return '$keyPart${value.substring(0, availableWidth)}';
    }

    return '$keyPart$value';
  }
}
