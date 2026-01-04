import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Barcode printing demo screen.
class BarcodeDemoScreen extends StatefulWidget {
  /// Printer instance to use.
  final Sk58Printer? printer;

  /// Creates the barcode demo screen.
  const BarcodeDemoScreen({super.key, required this.printer});

  @override
  State<BarcodeDemoScreen> createState() => _BarcodeDemoScreenState();
}

class _BarcodeDemoScreenState extends State<BarcodeDemoScreen> {
  final TextEditingController _dataController = TextEditingController();
  bool _isPrinting = false;
  BarcodeType _barcodeType = BarcodeType.code128;
  int _height = 80;
  int _width = 3;
  BarcodeHriPosition _hriPosition = BarcodeHriPosition.below;

  @override
  void initState() {
    super.initState();
    _updateDefaultData();
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _updateDefaultData() {
    switch (_barcodeType) {
      case BarcodeType.code128:
        _dataController.text = 'ABC-12345';
        break;
      case BarcodeType.ean13:
        _dataController.text = '5901234123457';
        break;
      case BarcodeType.upcA:
        _dataController.text = '012345678905';
        break;
      case BarcodeType.code39:
        _dataController.text = 'CODE39TEST';
        break;
    }
  }

  Future<void> _print() async {
    if (widget.printer == null || _isPrinting) return;

    final data = _dataController.text;
    if (data.isEmpty) {
      _showMessage('Please enter barcode data');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      // Print label with barcode type
      await widget.printer!.printText(
        _barcodeType.displayName,
        style: Sk58TextStyle.boldStyle,
        align: Sk58Align.center,
      );

      // Print barcode
      await widget.printer!.printBarcode(
        data,
        type: _barcodeType,
        height: _height,
        width: _width,
        hriPosition: _hriPosition,
      );

      await widget.printer!.feedLines(3);
      _showMessage('Barcode printed!');
    } on BarcodeException catch (e) {
      _showMessage('Invalid data: ${e.message}');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _printAllTypes() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await widget.printer!.printText(
        'BARCODE TYPES',
        style: const Sk58TextStyle(bold: true, size: Sk58FontSize.large),
        align: Sk58Align.center,
      );
      await widget.printer!.printLine();

      // Code 128
      await widget.printer!.printText('Code 128:', align: Sk58Align.center);
      await widget.printer!.printBarcode('ABC-12345', type: BarcodeType.code128);

      // EAN-13
      await widget.printer!.printText('EAN-13:', align: Sk58Align.center);
      await widget.printer!.printBarcode('5901234123457', type: BarcodeType.ean13);

      // UPC-A
      await widget.printer!.printText('UPC-A:', align: Sk58Align.center);
      await widget.printer!.printBarcode('012345678905', type: BarcodeType.upcA);

      // Code 39
      await widget.printer!.printText('Code 39:', align: Sk58Align.center);
      await widget.printer!.printBarcode('CODE39', type: BarcodeType.code39);

      await widget.printer!.feedLines(3);
      _showMessage('All barcodes printed!');
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
          // Barcode type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barcode Type',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BarcodeType.values.map((type) {
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: _barcodeType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _barcodeType = type;
                              _updateDefaultData();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data input
          TextField(
            controller: _dataController,
            decoration: InputDecoration(
              labelText: 'Barcode data',
              border: const OutlineInputBorder(),
              helperText: _getDataHint(),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Options',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Height slider
                  Row(
                    children: [
                      const Text('Height: '),
                      Expanded(
                        child: Slider(
                          value: _height.toDouble(),
                          min: 30,
                          max: 150,
                          divisions: 12,
                          label: '$_height',
                          onChanged: (v) => setState(() => _height = v.round()),
                        ),
                      ),
                      Text('$_height'),
                    ],
                  ),

                  // Width slider
                  Row(
                    children: [
                      const Text('Width: '),
                      Expanded(
                        child: Slider(
                          value: _width.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          label: '$_width',
                          onChanged: (v) => setState(() => _width = v.round()),
                        ),
                      ),
                      Text('$_width'),
                    ],
                  ),

                  // HRI position
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Text: '),
                      const SizedBox(width: 8),
                      DropdownButton<BarcodeHriPosition>(
                        value: _hriPosition,
                        items: BarcodeHriPosition.values.map((pos) {
                          return DropdownMenuItem(
                            value: pos,
                            child: Text(pos.name),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _hriPosition = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Print buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isConnected && !_isPrinting ? _print : null,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isConnected && !_isPrinting ? _printAllTypes : null,
                  icon: const Icon(Icons.list),
                  label: const Text('Print All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDataHint() {
    switch (_barcodeType) {
      case BarcodeType.code128:
        return 'ASCII characters (0-127)';
      case BarcodeType.ean13:
        return '12-13 digits';
      case BarcodeType.upcA:
        return '11-12 digits';
      case BarcodeType.code39:
        return '0-9, A-Z, space, - . \$ / + %';
    }
  }
}
