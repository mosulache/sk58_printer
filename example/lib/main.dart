import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  runApp(const Sk58PrinterExampleApp());
}

/// Example app widget demonstrating sk58_printer library usage.
class Sk58PrinterExampleApp extends StatelessWidget {
  /// Creates the example app.
  const Sk58PrinterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SK58 Printer Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PrinterScreen(),
    );
  }
}

/// Main screen widget for printer operations.
class PrinterScreen extends StatefulWidget {
  /// Creates the printer screen.
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final TextEditingController _textController = TextEditingController();
  final Sk58Scanner _scanner = Sk58Scanner();

  String _status = 'Not connected';
  List<BleDevice> _devices = [];
  bool _isScanning = false;
  Sk58Printer? _printer;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _textController.text = 'SK58 Printer Test';

    // Listen for discovered devices
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
    _textController.dispose();
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

    // Wait for scan to complete
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

  Future<void> _printLabel() async {
    if (_printer == null || _isPrinting) return;

    final text = _textController.text;
    if (text.isEmpty) {
      _showMessage('Please enter some text');
      return;
    }

    setState(() {
      _isPrinting = true;
      _status = 'Printing...';
    });

    try {
      // Print QR code centered
      await _printer!.printQrCode(text);

      // Print text below QR
      await _printer!.printText(text, align: Sk58Align.center);

      // Feed some paper
      await _printer!.feedLines(3);

      setState(() {
        _status = 'Print complete!';
      });
      _showMessage('Print successful!');
    } catch (e) {
      setState(() {
        _status = 'Print error: $e';
      });
      _showMessage('Print failed: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _printer?.isConnected == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SK58 Printer Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: _disconnect,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: isConnected ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to print (also used for QR)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Scan button
            ElevatedButton.icon(
              onPressed: _isScanning || _status.contains('Connecting')
                  ? null
                  : _startScan,
              icon: const Icon(Icons.search),
              label: Text(_isScanning ? 'Scanning...' : 'Scan for Printers'),
            ),

            const SizedBox(height: 16),

            // Device list
            Expanded(
              child: Card(
                child: _devices.isEmpty
                    ? Center(
                        child: Text(
                          _isScanning
                              ? 'Searching for devices...'
                              : 'No devices found.\nTap "Scan" to search.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          final isThisConnected =
                              _printer?.device?.deviceId == device.deviceId;
                          final name = device.name?.isNotEmpty == true
                              ? device.name!
                              : 'Unknown Device';

                          return ListTile(
                            leading: Icon(
                              isThisConnected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth,
                              color: isThisConnected ? Colors.blue : null,
                            ),
                            title: Text(name),
                            subtitle: Text(device.deviceId),
                            trailing: isThisConnected
                                ? const Chip(label: Text('Connected'))
                                : null,
                            onTap: isThisConnected
                                ? null
                                : () => _connectTo(device),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: isConnected && !_isPrinting ? _printLabel : null,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: Text(_isPrinting ? 'Printing...' : 'Print Label'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
