/// Bluetooth scanner for discovering SK58 printers.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'constants.dart';
import 'permissions.dart';

/// Bluetooth scanner for discovering SK58 thermal printers.
///
/// Usage:
/// ```dart
/// final scanner = Sk58Scanner();
/// await scanner.startScan();
///
/// scanner.deviceStream.listen((device) {
///   print('Found: ${device.name}');
/// });
///
/// // Later...
/// scanner.stopScan();
/// ```
class Sk58Scanner {
  final StreamController<BleDevice> _deviceController =
      StreamController<BleDevice>.broadcast();

  final List<BleDevice> _discoveredDevices = [];

  bool _isScanning = false;
  Timer? _scanTimer;

  /// Stream of discovered Bluetooth devices.
  ///
  /// Subscribe to this stream to receive devices as they are discovered.
  Stream<BleDevice> get deviceStream => _deviceController.stream;

  /// List of all discovered devices during the current or last scan.
  List<BleDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  /// Whether the scanner is currently scanning.
  bool get isScanning => _isScanning;

  /// Starts scanning for Bluetooth devices.
  ///
  /// [timeout] - Duration after which scanning automatically stops.
  ///   Defaults to [Sk58Constants.defaultScanTimeoutSeconds].
  /// [platform] - Override platform for testing. Uses current platform if null.
  ///
  /// Returns [Sk58PermissionResult] if permissions are not granted,
  /// or null if scan started successfully.
  ///
  /// Throws [Sk58ScanException] if Bluetooth is not available or scan fails.
  Future<Sk58PermissionResult?> startScan({
    Duration? timeout,
    TargetPlatform? platform,
  }) async {
    // Check permissions first
    final permissionResult = await Sk58Permissions.checkAndRequestPermissions(
      platform: platform,
    );

    if (permissionResult != Sk58PermissionResult.granted) {
      return permissionResult;
    }

    final targetPlatform = platform ?? defaultTargetPlatform;

    // Check Bluetooth availability (skip on Linux where it may not be supported)
    if (targetPlatform != TargetPlatform.linux) {
      try {
        final state = await UniversalBle.getBluetoothAvailabilityState();
        if (state != AvailabilityState.poweredOn) {
          throw const Sk58ScanException('Bluetooth is not powered on');
        }
      } catch (e) {
        if (e is Sk58ScanException) rethrow;
        debugPrint('SK58: Could not check Bluetooth state: $e');
        throw const Sk58ScanException('Could not verify Bluetooth state');
      }
    }

    if (_isScanning) {
      debugPrint('SK58: Scan already in progress');
      return null;
    }

    // Clear previous results
    _discoveredDevices.clear();
    _isScanning = true;

    // Setup scan result handler
    UniversalBle.onScanResult = (BleDevice device) {
      if (!_discoveredDevices.any((d) => d.deviceId == device.deviceId)) {
        _discoveredDevices.add(device);
        _deviceController.add(device);
        debugPrint('SK58: Found device: ${device.name ?? device.deviceId}');
      }
    };

    // Start scanning
    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [], withNamePrefix: []),
      );

      // Set timeout
      final scanTimeout = timeout ??
          const Duration(seconds: Sk58Constants.defaultScanTimeoutSeconds);
      _scanTimer = Timer(scanTimeout, stopScan);

      debugPrint('SK58: Scan started, timeout: ${scanTimeout.inSeconds}s');
      return null;
    } catch (e) {
      _isScanning = false;
      debugPrint('SK58: Failed to start scan: $e');
      throw const Sk58ScanException('Failed to start scan');
    }
  }

  /// Stops the current Bluetooth scan.
  void stopScan() {
    if (!_isScanning) return;

    _scanTimer?.cancel();
    _scanTimer = null;

    UniversalBle.stopScan();
    _isScanning = false;

    debugPrint(
        'SK58: Scan stopped, found ${_discoveredDevices.length} devices');
  }

  /// Disposes of resources used by the scanner.
  ///
  /// Call this when done with the scanner to prevent memory leaks.
  void dispose() {
    stopScan();
    _deviceController.close();
  }
}

/// Exception thrown when scanning for Bluetooth devices fails.
class Sk58ScanException implements Exception {
  /// The error message.
  final String message;

  /// Creates a scan exception with the given message.
  const Sk58ScanException(this.message);

  @override
  String toString() => 'Sk58ScanException: $message';
}
