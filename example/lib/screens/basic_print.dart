import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Basic text and QR code printing demo screen.
class BasicPrintScreen extends StatefulWidget {
  /// Printer instance to use.
  final Sk58Printer? printer;

  /// Creates the basic print screen.
  const BasicPrintScreen({super.key, required this.printer});

  @override
  State<BasicPrintScreen> createState() => _BasicPrintScreenState();
}

class _BasicPrintScreenState extends State<BasicPrintScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isPrinting = false;
  Sk58Align _alignment = Sk58Align.center;
  bool _bold = false;
  bool _underline = false;
  Sk58FontSize _fontSize = Sk58FontSize.normal;
  bool _includeQr = true;

  @override
  void initState() {
    super.initState();
    _textController.text = 'SK58 Printer Test';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    if (widget.printer == null || _isPrinting) return;

    final text = _textController.text;
    if (text.isEmpty) {
      _showMessage('Please enter some text');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final style = Sk58TextStyle(
        bold: _bold,
        underline: _underline,
        size: _fontSize,
      );

      if (_includeQr) {
        await widget.printer!.printQrCode(text);
      }

      await widget.printer!.printText(text, style: style, align: _alignment);
      await widget.printer!.feedLines(3);

      _showMessage('Print successful!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
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
          // Text input
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text to print',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Options card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Options',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Alignment
                  Row(
                    children: [
                      const Text('Align: '),
                      const SizedBox(width: 8),
                      SegmentedButton<Sk58Align>(
                        segments: const [
                          ButtonSegment(
                              value: Sk58Align.left,
                              icon: Icon(Icons.format_align_left)),
                          ButtonSegment(
                              value: Sk58Align.center,
                              icon: Icon(Icons.format_align_center)),
                          ButtonSegment(
                              value: Sk58Align.right,
                              icon: Icon(Icons.format_align_right)),
                        ],
                        selected: {_alignment},
                        onSelectionChanged: (v) =>
                            setState(() => _alignment = v.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Font size
                  Row(
                    children: [
                      const Text('Size: '),
                      const SizedBox(width: 8),
                      DropdownButton<Sk58FontSize>(
                        value: _fontSize,
                        items: const [
                          DropdownMenuItem(
                              value: Sk58FontSize.normal,
                              child: Text('Normal')),
                          DropdownMenuItem(
                              value: Sk58FontSize.wide, child: Text('Wide')),
                          DropdownMenuItem(
                              value: Sk58FontSize.tall, child: Text('Tall')),
                          DropdownMenuItem(
                              value: Sk58FontSize.large, child: Text('Large')),
                        ],
                        onChanged: (v) => setState(() => _fontSize = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Style toggles
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Bold'),
                        selected: _bold,
                        onSelected: (v) => setState(() => _bold = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Underline'),
                        selected: _underline,
                        onSelected: (v) => setState(() => _underline = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('QR Code'),
                        selected: _includeQr,
                        onSelected: (v) => setState(() => _includeQr = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Print button
          ElevatedButton.icon(
            onPressed: isConnected && !_isPrinting ? _print : null,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: Text(_isPrinting ? 'Printing...' : 'Print'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
