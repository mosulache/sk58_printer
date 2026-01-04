/// Permission handling for Bluetooth operations.
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of permission check operation.
enum Sk58PermissionResult {
  /// All required permissions are granted.
  granted,

  /// Bluetooth scan permission is denied.
  bluetoothScanDenied,

  /// Bluetooth connect permission is denied.
  bluetoothConnectDenied,

  /// Location permission is denied (required on Android for BLE scanning).
  locationDenied,
}

/// Handles platform-specific permission requests for Bluetooth operations.
class Sk58Permissions {
  Sk58Permissions._();

  /// Checks and requests all required permissions for Bluetooth operations.
  ///
  /// On Linux, permissions are handled by the system (BlueZ), so this
  /// always returns [Sk58PermissionResult.granted].
  ///
  /// On Android, requests Bluetooth scan, connect, and location permissions.
  ///
  /// Returns [Sk58PermissionResult] indicating the result of the check.
  static Future<Sk58PermissionResult> checkAndRequestPermissions({
    TargetPlatform? platform,
  }) async {
    final targetPlatform = platform ?? defaultTargetPlatform;

    // Linux handles permissions differently (via BlueZ/system)
    if (targetPlatform == TargetPlatform.linux) {
      debugPrint('SK58: Running on Linux - permissions handled by system');
      return Sk58PermissionResult.granted;
    }

    // Request Bluetooth scan permission
    if (!await Permission.bluetoothScan.request().isGranted) {
      debugPrint('SK58: Bluetooth scan permission denied');
      return Sk58PermissionResult.bluetoothScanDenied;
    }

    // Request Bluetooth connect permission
    if (!await Permission.bluetoothConnect.request().isGranted) {
      debugPrint('SK58: Bluetooth connect permission denied');
      return Sk58PermissionResult.bluetoothConnectDenied;
    }

    // On Android, location permission is required for BLE scanning
    if (targetPlatform == TargetPlatform.android) {
      if (!await Permission.location.request().isGranted) {
        debugPrint('SK58: Location permission denied');
        return Sk58PermissionResult.locationDenied;
      }
    }

    debugPrint('SK58: All permissions granted');
    return Sk58PermissionResult.granted;
  }

  /// Checks if all required permissions are already granted without requesting.
  static Future<bool> arePermissionsGranted({
    TargetPlatform? platform,
  }) async {
    final targetPlatform = platform ?? defaultTargetPlatform;

    if (targetPlatform == TargetPlatform.linux) {
      return true;
    }

    final bluetoothScan = await Permission.bluetoothScan.isGranted;
    final bluetoothConnect = await Permission.bluetoothConnect.isGranted;

    if (!bluetoothScan || !bluetoothConnect) {
      return false;
    }

    if (targetPlatform == TargetPlatform.android) {
      return await Permission.location.isGranted;
    }

    return true;
  }
}
