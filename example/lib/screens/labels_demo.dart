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

  // Label configuration
  Sk58LabelSize _selectedSize = Sk58LabelSize.label50x30;
  Sk58PaperType _paperType = Sk58PaperType.labelWithGap;
  int _density = 3;
  int _speed = 2;
  bool _useAdvancedCommands =
      false; // Off by default - many printers don't support


  // Simple label fields
  final _titleController = TextEditingController(text: 'TORX 4x50');
  final _subtitleController = TextEditingController(text: 'Cap T20 - Inox A2');
  final _qrDataController = TextEditingController(text: 'SKU-12345');
  bool _includeQr = true;
  int _qrSize = 5;

  // Two-column label fields
  final List<(TextEditingController key, TextEditingController value)> _rows = [
    (TextEditingController(text: 'Type'), TextEditingController(text: 'TORX')),
    (
      TextEditingController(text: 'Size'),
      TextEditingController(text: '4x50mm')
    ),
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

  Future<void> _configureAndPrint(Future<void> Function() printAction) async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      // Only send config commands if advanced mode is enabled
      if (_useAdvancedCommands) {
        // WARNING: Many SK58 printers don't support these commands!
        final config = LabelPrintConfig(
          paperType: _paperType,
          widthMm: _selectedSize.widthMm.toDouble(),
          heightMm: _selectedSize.heightMm.toDouble(),
          density: _density,
          speed: _speed,
          useAdvancedCommands: true,
        );
        await widget.printer!.printRaw(config.toCommands());
      }

      // Execute print action
      await printAction();

      // Feed to next label using GS FF (print and peel) - works best on SK58!
      await widget.printer!.printAndPeel();

      _showMessage('Label printed on ${_selectedSize.displayName}!');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _printSimpleLabel() async {
    await _configureAndPrint(() async {
      final label = Sk58Label(
        title: _titleController.text,
        subtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        qrData: _includeQr && _qrDataController.text.isNotEmpty
            ? _qrDataController.text
            : null,
        qrSize: _qrSize,
        feedAfter: 0, // We'll feed manually
      );

      await widget.printer!.printTemplate(label);
    });
  }

  Future<void> _printTwoColumnLabel() async {
    await _configureAndPrint(() async {
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
        qrSize: _qrSize,
        lineWidth: _selectedSize.charsPerLine,
        feedAfter: 0,
      );

      await widget.printer!.printTemplate(label);
    });
  }

  Future<void> _calibrateLabels() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await widget.printer!.calibrateLabels();
      _showMessage('Label calibration started');
    } catch (e) {
      _showMessage('Calibration failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  // ============================================================
  // TEST FEED METHODS - to find which one works best
  // ============================================================

  /// Print label and test with FS ( L fn=67
  Future<void> _printWithFsL() async {
    await _printLabelWithFeedMethod('FS(L) fn=67', () async {
      await widget.printer!.printRaw([0x1C, 0x28, 0x4C, 0x02, 0x00, 0x43, 0x32]);
    });
  }

  /// Print label and test with simple FF (0x0C)
  Future<void> _printWithFormFeed() async {
    await _printLabelWithFeedMethod('FF (0x0C)', () async {
      await widget.printer!.formFeed();
    });
  }

  /// Print label and test with GS FF (print and peel)
  Future<void> _printWithGsFF() async {
    await _printLabelWithFeedMethod('GS FF (peel)', () async {
      await widget.printer!.printAndPeel();
    });
  }

  /// Print label and test with just line feeds (no gap detection)
  Future<void> _printWithLineFeed() async {
    // Calculate lines based on label height (approx 8 dots per line)
    final lines = (_selectedSize.heightMm * 8 / 24).ceil() + 2; // +2 for gap
    await _printLabelWithFeedMethod('ESC d $lines lines', () async {
      await widget.printer!.printRaw([0x1B, 0x64, lines]);
    });
  }

  /// Helper to print a label with a specific feed method
  Future<void> _printLabelWithFeedMethod(
      String methodName, Future<void> Function() feedMethod) async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      // Print a simple test label
      final label = Sk58Label(
        title: _titleController.text,
        subtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        qrData: null, // No QR for quick test
        feedAfter: 0,
      );
      await widget.printer!.printTemplate(label);

      // Apply the feed method being tested
      await feedMethod();

      _showMessage('Printed with $methodName');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label Size Selector Card
          _buildLabelSizeCard(theme, colorScheme),
          const SizedBox(height: 16),

          // Printer Settings Card
          _buildPrinterSettingsCard(theme, colorScheme, isConnected),
          const SizedBox(height: 16),

          // Feed Test Card - TEST DIFFERENT FEED METHODS
          _buildFeedTestCard(theme, colorScheme, isConnected),
          const SizedBox(height: 16),

          // Simple Label Card
          _buildSimpleLabelCard(theme, isConnected),
          const SizedBox(height: 16),

          // Two-Column Label Card
          _buildTwoColumnLabelCard(theme, isConnected),
          const SizedBox(height: 16),

          // QR Code Option Card
          _buildQrCodeCard(theme),

          if (_isPrinting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedTestCard(
      ThemeData theme, ColorScheme colorScheme, bool isConnected) {
    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('🧪 Test Feed Methods',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.tertiary,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Print same label with different feed commands to find which works best for your printer.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            // Feed method buttons in a grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // FS ( L - recommended
                _buildFeedTestButton(
                  'FS(L) fn=67',
                  '1C 28 4C...',
                  Icons.star,
                  isConnected,
                  _printWithFsL,
                  colorScheme,
                  isRecommended: true,
                ),

                // Simple FF
                _buildFeedTestButton(
                  'Form Feed',
                  '0C',
                  Icons.arrow_downward,
                  isConnected,
                  _printWithFormFeed,
                  colorScheme,
                ),

                // GS FF (peel mode)
                _buildFeedTestButton(
                  'GS FF (peel)',
                  '1D 0C',
                  Icons.content_cut,
                  isConnected,
                  _printWithGsFF,
                  colorScheme,
                ),

                // Line feed based on label height
                _buildFeedTestButton(
                  'Line Feed',
                  'ESC d n',
                  Icons.format_line_spacing,
                  isConnected,
                  _printWithLineFeed,
                  colorScheme,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Each button prints "${_titleController.text}" then applies that feed method. '
                      'Check which one correctly advances to the next label!',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTestButton(
    String label,
    String hex,
    IconData icon,
    bool isConnected,
    VoidCallback onPressed,
    ColorScheme colorScheme, {
    bool isRecommended = false,
  }) {
    return OutlinedButton(
      onPressed: isConnected && !_isPrinting ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isRecommended ? colorScheme.primary : colorScheme.outline,
          width: isRecommended ? 2 : 1,
        ),
        backgroundColor:
            isRecommended ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
              if (isRecommended) ...[
                const SizedBox(width: 4),
                Icon(Icons.thumb_up, size: 12, color: colorScheme.primary),
              ],
            ],
          ),
          Text(
            hex,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelSizeCard(ThemeData theme, ColorScheme colorScheme) {
    // Group sizes by width
    final sizes50 = Sk58LabelSize.forPaperWidth(50);
    final sizes40 = Sk58LabelSize.forPaperWidth(40);
    final sizes30 = Sk58LabelSize.forPaperWidth(30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Label Size', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Visual preview of selected label
            _buildLabelPreview(colorScheme),
            const SizedBox(height: 16),

            // Size selector grouped by paper width
            Text('50mm Paper', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes50
                  .map((size) => _buildSizeChip(size, colorScheme))
                  .toList(),
            ),

            const SizedBox(height: 12),
            Text('40mm Paper', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes40
                  .map((size) => _buildSizeChip(size, colorScheme))
                  .toList(),
            ),

            const SizedBox(height: 12),
            Text('30mm Paper', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes30
                  .map((size) => _buildSizeChip(size, colorScheme))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelPreview(ColorScheme colorScheme) {
    // Scale factor to fit preview in card (max ~200px width)
    const maxPreviewWidth = 200.0;
    final scale = maxPreviewWidth / 50; // Scale based on widest label (50mm)

    final previewWidth = _selectedSize.widthMm * scale;
    final previewHeight = (_selectedSize.heightMm * scale).clamp(30.0, 150.0);

    return Center(
      child: Container(
        width: previewWidth,
        height: previewHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Size label
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: Text(
                _selectedSize.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Specs at bottom
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedSize.widthDots}×${_selectedSize.heightDots} dots',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${_selectedSize.charsPerLine} chars/line',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Print area indicator (48mm max)
            if (_selectedSize.widthMm > 48)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: ((_selectedSize.widthMm - 48) * scale),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.error,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  child: const Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'margin',
                        style: TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip(Sk58LabelSize size, ColorScheme colorScheme) {
    final isSelected = _selectedSize == size;

    return FilterChip(
      label: Text(size.displayName),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSize = size);
        }
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      avatar: isSelected
          ? null
          : Icon(
              Icons.label_outline,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
    );
  }

  Widget _buildPrinterSettingsCard(
      ThemeData theme, ColorScheme colorScheme, bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Printer Settings', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      isConnected && !_isPrinting ? _calibrateLabels : null,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Calibrate'),
                ),
              ],
            ),
            // Paper Type (only in advanced mode)
            if (_useAdvancedCommands) ...[
              const SizedBox(height: 16),
              Text('Paper Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Sk58PaperType>(
                segments: const [
                  ButtonSegment(
                    value: Sk58PaperType.labelWithGap,
                    label: Text('Gap'),
                    icon: Icon(Icons.space_bar),
                  ),
                  ButtonSegment(
                    value: Sk58PaperType.labelWithBlackMark,
                    label: Text('Black Mark'),
                    icon: Icon(Icons.contrast),
                  ),
                  ButtonSegment(
                    value: Sk58PaperType.continuous,
                    label: Text('Continuous'),
                    icon: Icon(Icons.receipt_long),
                  ),
                ],
                selected: {_paperType},
                onSelectionChanged: (selected) {
                  setState(() => _paperType = selected.first);
                },
              ),
            ],

            // Density & Speed sliders (only in advanced mode)
            // Note: SK58 sets density via physical buttons (3x press = +1 level)
            if (_useAdvancedCommands) ...[
              const SizedBox(height: 16),

              // Density slider
              Row(
                children: [
                  Text('Density: $_density', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  Text(
                    _density <= 2
                        ? '(light)'
                        : _density >= 4
                            ? '(dark)'
                            : '(normal)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Slider(
                value: _density.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _density.toString(),
                onChanged: (value) => setState(() => _density = value.round()),
              ),
            ],

            // Speed slider (only visible in advanced mode)
            if (_useAdvancedCommands) ...[
              Row(
                children: [
                  Text('Speed: $_speed', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  Text(
                    _speed == 1
                        ? '(best quality)'
                        : _speed == 3
                            ? '(fastest)'
                            : '(balanced)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Slider(
                value: _speed.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                label: _speed.toString(),
                onChanged: (value) => setState(() => _speed = value.round()),
              ),
            ],

            const Divider(),

            // Advanced commands toggle
            SwitchListTile(
              title: const Text('Advanced Commands'),
              subtitle: Text(
                _useAdvancedCommands
                    ? '⚠️ May cause garbage output!'
                    : '✓ Safe mode (recommended)',
                style: TextStyle(
                  color: _useAdvancedCommands
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
              value: _useAdvancedCommands,
              onChanged: (v) => setState(() => _useAdvancedCommands = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLabelCard(ThemeData theme, bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label),
                const SizedBox(width: 8),
                Text('Simple Label', style: theme.textTheme.titleMedium),
              ],
            ),
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
            FilledButton.icon(
              onPressed: isConnected && !_isPrinting ? _printSimpleLabel : null,
              icon: const Icon(Icons.print),
              label: Text('Print on ${_selectedSize.displayName}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLabelCard(ThemeData theme, bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_rows),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Two-Column Label',
                      style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
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
                      onPressed:
                          _rows.length > 1 ? () => _removeRow(index) : null,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed:
                  isConnected && !_isPrinting ? _printTwoColumnLabel : null,
              icon: const Icon(Icons.print),
              label: Text('Print on ${_selectedSize.displayName}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code),
                const SizedBox(width: 8),
                Text('QR Code (shared)', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Include QR Code'),
              subtitle: Text('Size: $_qrSize (1-16 modules)'),
              value: _includeQr,
              onChanged: (v) => setState(() => _includeQr = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_includeQr) ...[
              TextField(
                controller: _qrDataController,
                decoration: const InputDecoration(
                  labelText: 'QR Data',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'URL, SKU, or any text',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('QR Size:'),
                  Expanded(
                    child: Slider(
                      value: _qrSize.toDouble(),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: _qrSize.toString(),
                      onChanged: (v) => setState(() => _qrSize = v.round()),
                    ),
                  ),
                ],
              ),
              // Size recommendation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended QR size for ${_selectedSize.displayName}: '
                        '${_getRecommendedQrSize()}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRecommendedQrSize() {
    // Smaller labels need smaller QR codes
    if (_selectedSize.heightMm <= 20) return '3-4';
    if (_selectedSize.heightMm <= 30) return '4-5';
    if (_selectedSize.heightMm <= 50) return '5-6';
    return '6-8';
  }
}
