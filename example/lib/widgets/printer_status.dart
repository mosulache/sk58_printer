import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Widget that displays printer connection status and provides scan/connect controls.
class PrinterStatus extends StatelessWidget {
  /// Current status message.
  final String status;

  /// Connected printer instance, if any.
  final Sk58Printer? printer;

  /// Whether currently scanning for devices.
  final bool isScanning;

  /// List of discovered devices.
  final List<BleDevice> devices;

  /// Callback when user taps scan button.
  final VoidCallback onScan;

  /// Callback when user selects a device to connect.
  final void Function(BleDevice device) onConnect;

  /// Callback when user taps disconnect.
  final VoidCallback onDisconnect;

  /// Creates a printer status widget.
  const PrinterStatus({
    super.key,
    required this.status,
    required this.printer,
    required this.isScanning,
    required this.devices,
    required this.onScan,
    required this.onConnect,
    required this.onDisconnect,
  });

  bool get isConnected => printer?.isConnected == true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                    status,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (isConnected)
                  IconButton(
                    icon: const Icon(Icons.bluetooth_disabled),
                    tooltip: 'Disconnect',
                    onPressed: onDisconnect,
                  )
                else if (isScanning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Scan',
                    onPressed: onScan,
                  ),
              ],
            ),
          ),
        ),

        // Device list when scanning or devices found
        if (!isConnected && devices.isNotEmpty)
          Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final name = device.name?.isNotEmpty == true
                      ? device.name!
                      : 'Unknown Device';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.bluetooth, size: 20),
                    title: Text(name),
                    subtitle: Text(
                      device.deviceId,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => onConnect(device),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
