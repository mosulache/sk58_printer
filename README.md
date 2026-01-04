# SK58 Printer

Flutter library for SK58 thermal printer via Bluetooth.

## Features

- Bluetooth device scanning
- Connect/disconnect to SK58 thermal printer
- Print text with alignment (left, center, right)
- Print QR codes
- Support for Android and Linux

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sk58_printer:
    git:
      url: https://github.com/mosu/sk58_printer.git
      ref: main
```

## Usage

```dart
import 'package:sk58_printer/sk58_printer.dart';

// Create scanner and scan for devices
final scanner = Sk58Scanner();
await scanner.startScan();

// Listen for discovered devices
scanner.deviceStream.listen((device) {
  print('Found: ${device.name}');
});

// Connect to a device
final printer = await Sk58Printer.connect(device);

// Print text
await printer.printText('Hello World!');
await printer.printText('Centered', align: Sk58Align.center);

// Print QR code
await printer.printQrCode('https://example.com');

// Feed paper and disconnect
await printer.feedLines(3);
await printer.disconnect();
```

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Linux

Ensure BlueZ is installed and your user has bluetooth permissions.

## License

MIT License
