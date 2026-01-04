/// Constants for SK58 thermal printer communication.
///
/// WARNING: These UUIDs were discovered through trial & error!
/// DO NOT MODIFY without testing on a physical device!
library;

/// Configuration constants for SK58 printer Bluetooth communication.
class Sk58Constants {
  Sk58Constants._();

  /// Bluetooth service UUID for SK58 printer.
  ///
  /// This is the primary service UUID used to identify the printer.
  static const String printerServiceUuid =
      "000018f0-0000-1000-8000-00805f9b34fb";

  /// Bluetooth characteristic UUID for writing data to the printer.
  ///
  /// Data is written to this characteristic to send print commands.
  static const String printerCharacteristicUuid =
      "00002af1-0000-1000-8000-00805f9b34fb";

  /// Size of data chunks sent to the printer (in bytes).
  ///
  /// The printer expects data in small chunks. Larger chunks may fail.
  static const int chunkSize = 20;

  /// Delay between sending chunks (in milliseconds).
  ///
  /// This delay prevents buffer overflow on the printer.
  static const int chunkDelayMs = 100;

  /// Default scan timeout (in seconds).
  static const int defaultScanTimeoutSeconds = 10;

  /// Connection timeout (in seconds).
  static const int connectionTimeoutSeconds = 15;
}
