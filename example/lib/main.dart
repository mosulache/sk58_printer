import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

import 'screens/barcode_demo.dart';
import 'screens/basic_print.dart';
import 'screens/builder_demo.dart';
import 'screens/image_demo.dart';
import 'screens/labels_demo.dart';
import 'widgets/printer_status.dart';

void main() {
  runApp(const Sk58PrinterExampleApp());
}

/// Example app demonstrating all sk58_printer library features.
class Sk58PrinterExampleApp extends StatelessWidget {
  /// Creates the example app.
  const Sk58PrinterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SK58 Printer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

/// Main screen with tab navigation.
class MainScreen extends StatefulWidget {
  /// Creates the main screen.
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Sk58Scanner _scanner = Sk58Scanner();

  String _status = 'Not connected';
  List<BleDevice> _devices = [];
  bool _isScanning = false;
  Sk58Printer? _printer;
  int _currentIndex = 0;

  final List<_TabItem> _tabs = const [
    _TabItem(icon: Icons.text_fields, label: 'Text'),
    _TabItem(icon: Icons.qr_code_2, label: 'Barcode'),
    _TabItem(icon: Icons.label, label: 'Labels'),
    _TabItem(icon: Icons.image, label: 'Image'),
    _TabItem(icon: Icons.construction, label: 'Builder'),
  ];

  @override
  void initState() {
    super.initState();
    _scanner.deviceStream.listen((device) {
      if (mounted) {
        setState(() {
          if (!_devices.any((d) => d.deviceId == device.deviceId)) {
            _devices.add(device);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    _printer?.disconnect();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _devices = [];
      _isScanning = true;
      _status = 'Scanning...';
    });

    final result = await _scanner.startScan();

    if (result != null && result != Sk58PermissionResult.granted) {
      setState(() {
        _isScanning = false;
        _status = 'Permission denied: $result';
      });
      return;
    }

    // Wait for scan
    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      _scanner.stopScan();
      setState(() {
        _isScanning = false;
        _status = _devices.isEmpty
            ? 'No devices found'
            : 'Found ${_devices.length} devices';
      });
    }
  }

  Future<void> _connectTo(BleDevice device) async {
    _scanner.stopScan();

    final deviceName = device.name?.isNotEmpty == true
        ? device.name!
        : 'Device ${device.deviceId}';

    setState(() {
      _status = 'Connecting to $deviceName...';
    });

    try {
      _printer = await Sk58Printer.connect(device);
      setState(() {
        _status = 'Connected to $deviceName';
      });
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
        _printer = null;
      });
    }
  }

  Future<void> _disconnect() async {
    await _printer?.disconnect();
    setState(() {
      _printer = null;
      _status = 'Disconnected';
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return BasicPrintScreen(printer: _printer);
      case 1:
        return BarcodeDemoScreen(printer: _printer);
      case 2:
        return LabelsDemoScreen(printer: _printer);
      case 3:
        return ImageDemoScreen(printer: _printer);
      case 4:
        return BuilderDemoScreen(printer: _printer);
      default:
        return BasicPrintScreen(printer: _printer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SK58 Printer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Printer status at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PrinterStatus(
              status: _status,
              printer: _printer,
              isScanning: _isScanning,
              devices: _devices,
              onScan: _startScan,
              onConnect: _connectTo,
              onDisconnect: _disconnect,
            ),
          ),

          // Current tab content
          Expanded(child: _buildCurrentScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _tabs
            .map((tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

/// Tab item data.
class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}
