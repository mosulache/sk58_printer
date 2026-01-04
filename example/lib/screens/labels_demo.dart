import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Labels/Templates printing demo screen.
class LabelsDemoScreen extends StatefulWidget {
  /// Printer instance to use.
  final Sk58Printer? printer;

  /// Creates the labels demo screen.
  const LabelsDemoScreen({super.key, required this.printer});

  @override
  State<LabelsDemoScreen> createState() => _LabelsDemoScreenState();
}

class _LabelsDemoScreenState extends State<LabelsDemoScreen> {
  bool _isPrinting = false;

  // Simple label fields
  final _titleController = TextEditingController(text: 'TORX 4x50');
  final _subtitleController = TextEditingController(text: 'Cap T20 - Inox A2');
  final _qrDataController = TextEditingController(text: 'SKU-12345');
  bool _includeQr = true;

  // Two-column label fields
  final List<(TextEditingController key, TextEditingController value)> _rows = [
    (TextEditingController(text: 'Type'), TextEditingController(text: 'TORX')),
    (TextEditingController(text: 'Size'), TextEditingController(text: '4x50mm')),
    (TextEditingController(text: 'Head'), TextEditingController(text: 'T20')),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _qrDataController.dispose();
    for (final row in _rows) {
      row.$1.dispose();
      row.$2.dispose();
    }
    super.dispose();
  }

  Future<void> _printSimpleLabel() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final label = Sk58Label(
        title: _titleController.text,
        subtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        qrData: _includeQr && _qrDataController.text.isNotEmpty
            ? _qrDataController.text
            : null,
      );

      await widget.printer!.printTemplate(label);
      _showMessage('Label printed!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _printTwoColumnLabel() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final rows = _rows
          .where((r) => r.$1.text.isNotEmpty)
          .map((r) => (r.$1.text, r.$2.text))
          .toList();

      final label = Sk58TwoColumnLabel(
        title: 'Product Info',
        rows: rows,
        qrData: _includeQr && _qrDataController.text.isNotEmpty
            ? _qrDataController.text
            : null,
      );

      await widget.printer!.printTemplate(label);
      _showMessage('Two-column label printed!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  void _addRow() {
    setState(() {
      _rows.add((TextEditingController(), TextEditingController()));
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index].$1.dispose();
        _rows[index].$2.dispose();
        _rows.removeAt(index);
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
    final isConnected = widget.printer?.isConnected == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simple Label Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Simple Label (Sk58Label)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isConnected && !_isPrinting
                        ? _printSimpleLabel
                        : null,
                    icon: const Icon(Icons.print),
                    label: const Text('Print Simple Label'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Two-Column Label Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Two-Column Label',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addRow,
                        tooltip: 'Add row',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_rows.length, (index) {
                    final row = _rows[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.$1,
                              decoration: const InputDecoration(
                                labelText: 'Key',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: row.$2,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _rows.length > 1
                                ? () => _removeRow(index)
                                : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: isConnected && !_isPrinting
                        ? _printTwoColumnLabel
                        : null,
                    icon: const Icon(Icons.print),
                    label: const Text('Print Two-Column'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // QR Code Option
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QR Code (shared)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _includeQr,
                        onChanged: (v) => setState(() => _includeQr = v!),
                      ),
                      const Text('Include QR Code'),
                    ],
                  ),
                  if (_includeQr)
                    TextField(
                      controller: _qrDataController,
                      decoration: const InputDecoration(
                        labelText: 'QR Data',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isPrinting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
