/// Bluetooth connection management for SK58 printer.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'constants.dart';

/// Manages Bluetooth connection to an SK58 thermal printer.
///
/// Usage:
/// ```dart
/// final connection = Sk58Connection();
/// await connection.connect(device);
///
/// await connection.writeData(someBytes);
///
/// await connection.disconnect();
/// ```
class Sk58Connection {
  BleDevice? _connectedDevice;
  bool _isConnected = false;
  bool _servicesDiscovered = false;

  /// The currently connected device, if any.
  BleDevice? get connectedDevice => _connectedDevice;

  /// Whether currently connected to a printer.
  bool get isConnected => _isConnected;

  /// Connects to the specified Bluetooth device.
  ///
  /// [device] - The BLE device to connect to.
  ///
  /// Throws [Sk58ConnectionException] if connection fails.
  Future<void> connect(BleDevice device) async {
    if (_isConnected) {
      throw Sk58ConnectionException('Already connected to a device');
    }

    final deviceName = device.name?.isNotEmpty == true
        ? device.name!
        : 'Unknown (${device.deviceId})';

    debugPrint('SK58: Connecting to $deviceName...');

    // Setup connection change handler
    final connectionCompleter = Completer<bool>();

    UniversalBle.onConnectionChange = (
      String deviceId,
      bool isConnected,
      String? error,
    ) {
      debugPrint(
          'SK58: Connection change - deviceId: $deviceId, connected: $isConnected, error: $error');

      if (deviceId == device.deviceId) {
        if (isConnected) {
          _connectedDevice = device;
          _isConnected = true;
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(true);
          }
        } else {
          _connectedDevice = null;
          _isConnected = false;
          _servicesDiscovered = false;
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false);
          }
        }
      }
    };

    try {
      await UniversalBle.connect(device.deviceId).timeout(
        const Duration(seconds: Sk58Constants.connectionTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out after ${Sk58Constants.connectionTimeoutSeconds}s',
          );
        },
      );

      // Wait for connection callback
      final connected = await connectionCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => _isConnected,
      );

      if (!connected && !_isConnected) {
        throw Sk58ConnectionException('Connection callback indicated failure');
      }

      // Discover services
      await _discoverServices(device.deviceId);

      debugPrint('SK58: Connected to $deviceName');
    } catch (e) {
      _connectedDevice = null;
      _isConnected = false;
      _servicesDiscovered = false;

      if (e is Sk58ConnectionException) rethrow;
      throw Sk58ConnectionException('Failed to connect: $e');
    }
  }

  Future<void> _discoverServices(String deviceId) async {
    debugPrint('SK58: Discovering services...');

    try {
      await UniversalBle.discoverServices(deviceId);
      _servicesDiscovered = true;
      debugPrint('SK58: Services discovered');
    } catch (e) {
      debugPrint('SK58: Failed to discover services: $e');
      throw Sk58ConnectionException('Failed to discover services: $e');
    }
  }

  /// Disconnects from the currently connected printer.
  ///
  /// Does nothing if not connected.
  Future<void> disconnect() async {
    if (_connectedDevice == null) {
      debugPrint('SK58: No device connected, nothing to disconnect');
      return;
    }

    final deviceId = _connectedDevice!.deviceId;
    final deviceName = _connectedDevice!.name ?? deviceId;

    debugPrint('SK58: Disconnecting from $deviceName...');

    try {
      await UniversalBle.disconnect(deviceId);
    } catch (e) {
      debugPrint('SK58: Error during disconnect: $e');
    } finally {
      _connectedDevice = null;
      _isConnected = false;
      _servicesDiscovered = false;
      debugPrint('SK58: Disconnected');
    }
  }

  /// Writes data to the connected printer.
  ///
  /// [data] - The bytes to send to the printer.
  ///
  /// Data is sent in chunks of [Sk58Constants.chunkSize] bytes with
  /// [Sk58Constants.chunkDelayMs] delay between chunks to prevent
  /// buffer overflow.
  ///
  /// Throws [Sk58ConnectionException] if not connected or write fails.
  Future<void> writeData(Uint8List data) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Sk58ConnectionException('Not connected to a printer');
    }

    if (!_servicesDiscovered) {
      throw Sk58ConnectionException('Services not yet discovered');
    }

    final deviceId = _connectedDevice!.deviceId;
    final totalBytes = data.length;
    const chunkSize = Sk58Constants.chunkSize;

    debugPrint('SK58: Sending $totalBytes bytes in chunks of $chunkSize...');

    for (var i = 0; i < totalBytes; i += chunkSize) {
      final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
      final chunk = data.sublist(i, end);

      try {
        // ignore: deprecated_member_use
        await UniversalBle.writeValue(
          deviceId,
          Sk58Constants.printerServiceUuid,
          Sk58Constants.printerCharacteristicUuid,
          Uint8List.fromList(chunk),
          BleOutputProperty.withoutResponse,
        );

        debugPrint('SK58: Sent chunk ${(i ~/ chunkSize) + 1}: ${chunk.length} bytes');

        // Delay between chunks
        if (end < totalBytes) {
          await Future.delayed(const Duration(milliseconds: Sk58Constants.chunkDelayMs));
        }
      } catch (e) {
        debugPrint('SK58: Error writing chunk: $e');
        throw Sk58ConnectionException('Failed to write data: $e');
      }
    }

    debugPrint('SK58: All data sent successfully');
  }

  /// Writes a list of command bytes to the printer.
  ///
  /// Convenience method that converts `List<int>` to `Uint8List`.
  Future<void> writeCommands(List<int> commands) async {
    await writeData(Uint8List.fromList(commands));
  }
}

/// Exception thrown when printer connection operations fail.
class Sk58ConnectionException implements Exception {
  /// The error message.
  final String message;

  /// Creates a connection exception with the given message.
  Sk58ConnectionException(this.message);

  @override
  String toString() => 'Sk58ConnectionException: $message';
}
