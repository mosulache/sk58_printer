import 'package:flutter/material.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Builder pattern demo screen.
class BuilderDemoScreen extends StatefulWidget {
  /// Printer instance to use.
  final Sk58Printer? printer;

  /// Creates the builder demo screen.
  const BuilderDemoScreen({super.key, required this.printer});

  @override
  State<BuilderDemoScreen> createState() => _BuilderDemoScreenState();
}

class _BuilderDemoScreenState extends State<BuilderDemoScreen> {
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await widget.printer!
          .build()
          .header('DEMO STORE')
          .text('123 Main Street', align: Sk58Align.center)
          .text('Tel: 555-1234', align: Sk58Align.center)
          .doubleLine()
          .text('RECEIPT',
              style: Sk58TextStyle.boldStyle, align: Sk58Align.center)
          .line()
          .row('Coffee', '\$3.50')
          .row('Sandwich', '\$8.00')
          .row('Cookie', '\$2.50')
          .line()
          .row('Subtotal', '\$14.00')
          .row('Tax (10%)', '\$1.40')
          .doubleLine()
          .bold('TOTAL')
          .text('\$15.40',
              style: const Sk58TextStyle(size: Sk58FontSize.large),
              align: Sk58Align.right)
          .feed(1)
          .text('Thank you!', align: Sk58Align.center)
          .qrCode('https://demo-store.example.com/receipt/12345')
          .feed(3)
          .execute();

      _showMessage('Receipt printed!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _printLabel() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await widget.printer!
          .build()
          .header('WAREHOUSE')
          .line()
          .text('Product: Widget Pro X')
          .text('SKU: WPX-2024-001')
          .text('Location: A-15-3')
          .newLine()
          .barcode('WPX2024001', type: BarcodeType.code128, height: 60)
          .feed(3)
          .execute();

      _showMessage('Label printed!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _printCustom() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      // Build commands step by step
      final builder = widget.printer!.build();

      // Header section
      builder.text('=' * 32).header('CUSTOM PRINT').text('=' * 32);

      // Different alignments
      builder
          .feed(1)
          .text('Left aligned')
          .text('Center aligned', align: Sk58Align.center)
          .text('Right aligned', align: Sk58Align.right);

      // Different sizes
      builder
          .feed(1)
          .text('Normal size')
          .text('Wide', style: const Sk58TextStyle(size: Sk58FontSize.wide))
          .text('Tall', style: const Sk58TextStyle(size: Sk58FontSize.tall))
          .text('Large', style: const Sk58TextStyle(size: Sk58FontSize.large));

      // Styles
      builder
          .feed(1)
          .bold('Bold text')
          .text('Underlined', style: const Sk58TextStyle(underline: true))
          .text('Bold + Underline',
              style: const Sk58TextStyle(bold: true, underline: true));

      // Two-column rows
      builder
          .feed(1)
          .line()
          .row('Item', 'Price')
          .line(char: '.')
          .row('Apple', '\$1.00')
          .row('Orange', '\$1.50')
          .row('Banana', '\$0.75')
          .line();

      // QR at the end
      builder.feed(1).qrCode('Builder Pattern Demo', size: 6).feed(3);

      await builder.execute();
      _showMessage('Custom print complete!');
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
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print Builder Pattern',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'The builder pattern allows chaining multiple print '
                    'operations into a single fluent API call.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'await printer.build()\n'
                      '  .header("TITLE")\n'
                      '  .text("Some text")\n'
                      '  .row("Key", "Value")\n'
                      '  .qrCode("data")\n'
                      '  .feed(3)\n'
                      '  .execute();',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Demo buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Demo Prints',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Receipt demo
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Receipt'),
                    subtitle: const Text('Store receipt with items and total'),
                    trailing: ElevatedButton(
                      onPressed:
                          isConnected && !_isPrinting ? _printReceipt : null,
                      child: const Text('Print'),
                    ),
                  ),

                  const Divider(),

                  // Label demo
                  ListTile(
                    leading: const Icon(Icons.label),
                    title: const Text('Warehouse Label'),
                    subtitle: const Text('Product label with barcode'),
                    trailing: ElevatedButton(
                      onPressed:
                          isConnected && !_isPrinting ? _printLabel : null,
                      child: const Text('Print'),
                    ),
                  ),

                  const Divider(),

                  // Custom demo
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Feature Showcase'),
                    subtitle: const Text('All text styles and options'),
                    trailing: ElevatedButton(
                      onPressed:
                          isConnected && !_isPrinting ? _printCustom : null,
                      child: const Text('Print'),
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
