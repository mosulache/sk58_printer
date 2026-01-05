/// SK58 Thermal Printer Library
///
/// A Flutter library for communicating with SK58 thermal printers via Bluetooth.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:sk58_printer/sk58_printer.dart';
///
/// // Scan for devices
/// final scanner = Sk58Scanner();
/// await scanner.startScan();
///
/// scanner.deviceStream.listen((device) async {
///   if (device.name?.contains('SK58') == true) {
///     scanner.stopScan();
///
///     // Connect and print
///     final printer = await Sk58Printer.connect(device);
///     await printer.printText('Hello World!');
///     await printer.printQrCode('https://example.com');
///     await printer.feedLines(3);
///     await printer.disconnect();
///   }
/// });
/// ```
///
/// ## Features
///
/// - Bluetooth device scanning
/// - Connect/disconnect to SK58 printers
/// - Print text with alignment and styling
/// - Print QR codes
/// - Support for Android and Linux
library;

// Driver layer (for advanced users)
export 'src/driver/bluetooth_scanner.dart'
    show Sk58Scanner, Sk58ScanException;
export 'src/driver/constants.dart' show Sk58Constants;
export 'src/driver/permissions.dart'
    show Sk58Permissions, Sk58PermissionResult;
export 'src/driver/printer_connection.dart'
    show Sk58Connection, Sk58ConnectionException;
export 'src/driver/printer_config.dart'
    show Sk58Specs, Sk58LabelSize, Sk58CustomLabel, BlackMarkPositions;

// API layer (main public API)
export 'src/api/esc_pos_commands.dart' show EscPosCommands;
export 'src/api/label_commands.dart'
    show LabelCommands, LabelPrintConfig, Sk58PaperType;
export 'src/api/print_builder.dart' show Sk58PrintBuilder;
export 'src/api/printer.dart' show Sk58Printer, QrErrorCorrection;
export 'src/api/templates.dart'
    show Sk58Template, Sk58Label, Sk58TwoColumnLabel;
export 'src/api/text_style.dart' show Sk58Align, Sk58FontSize, Sk58TextStyle;

// Utils layer (barcode, image processing)
export 'src/utils/barcode_generator.dart'
    show BarcodeType, BarcodeHriPosition, BarcodeConfig, BarcodeException;
export 'src/utils/image_processor.dart'
    show
        Sk58ImageProcessor,
        ProcessedImage,
        ImageProcessingException,
        sk58MaxWidth;

// Re-export BleDevice for convenience
export 'package:universal_ble/universal_ble.dart' show BleDevice;
