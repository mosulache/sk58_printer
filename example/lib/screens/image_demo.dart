import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sk58_printer/sk58_printer.dart';

/// Image printing demo screen.
class ImageDemoScreen extends StatefulWidget {
  /// Printer instance to use.
  final Sk58Printer? printer;

  /// Creates the image demo screen.
  const ImageDemoScreen({super.key, required this.printer});

  @override
  State<ImageDemoScreen> createState() => _ImageDemoScreenState();
}

class _ImageDemoScreenState extends State<ImageDemoScreen> {
  bool _isPrinting = false;
  bool _dithering = true;
  bool _bandMode = true; // Send image in bands (better for mobile printers)
  int _threshold = 128;
  int _maxWidth = 384; // Full width (48mm effective print area)
  int _chunkSize = 20; // BLE chunk size in bytes (must be 20 for most printers)
  int _chunkDelayMs = 10; // Delay between chunks in ms
  Uint8List? _previewImage;
  final String _selectedAsset = 'assets/demo_logo.png';

  // Label mode settings
  bool _labelMode = false; // If true, feed to next label after print
  int _topMarginDots = 0; // Dots to feed before printing (8 dots = 1mm)

  // Label dimensions for preview (in dots at 8 dots/mm)
  // Default: 40x15mm label = 320x120 dots
  int _labelWidthDots = 320;
  int _labelHeightDots = 120;
  // Dead zone at top where printer can't print (typically ~4mm = 32 dots)
  int _deadZoneDots = 32;

  Future<void> _loadDemoImage() async {
    try {
      final data = await rootBundle.load(_selectedAsset);
      setState(() {
        _previewImage = data.buffer.asUint8List();
      });
    } catch (e) {
      // Asset not found - will show placeholder
      setState(() {
        _previewImage = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDemoImage();
  }

  Future<void> _printImage() async {
    if (widget.printer == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      Uint8List imageData;

      if (_previewImage != null) {
        imageData = _previewImage!;
      } else {
        // Create a simple test pattern if no image
        _showMessage('No image loaded, using test pattern');
        imageData = _createSimpleTestImage();
      }

      // Feed top margin if set (for fine-tuning label position)
      if (_topMarginDots > 0) {
        await widget.printer!.feedDots(_topMarginDots);
      }

      await widget.printer!.printImage(
        imageData,
        maxWidth: _maxWidth,
        dithering: _dithering,
        threshold: _threshold,
        bandMode: _bandMode,
        feedAfter: !_labelMode, // Don't add extra feed for labels
      );

      if (_labelMode) {
        // For labels: use GS FF (print and peel) - works best on SK58!
        await widget.printer!.printAndPeel();
      } else {
        // For continuous paper: just feed some lines
        await widget.printer!.feedLines(3);
      }

      _showMessage('Image printed!');
    } on ImageProcessingException catch (e) {
      _showMessage('Image error: ${e.message}');
    } catch (e) {
      _showMessage('Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  // Creates a simple 32x32 black and white checkerboard pattern
  Uint8List _createSimpleTestImage() {
    // BMP format is simpler for testing
    const width = 32;
    const height = 32;

    // Create raw grayscale pixel data
    final pixels = <int>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Checkerboard pattern
        final isWhite = (x ~/ 4 + y ~/ 4) % 2 == 0;
        pixels.add(isWhite ? 255 : 0);
      }
    }

    // Simple BMP header for 32x32 8-bit grayscale
    final bmpHeader = <int>[
      // BMP Header
      0x42, 0x4D, // "BM"
      0x36, 0x14, 0x00, 0x00, // File size
      0x00, 0x00, 0x00, 0x00, // Reserved
      0x36, 0x04, 0x00, 0x00, // Pixel data offset

      // DIB Header (BITMAPINFOHEADER)
      0x28, 0x00, 0x00, 0x00, // Header size (40)
      0x20, 0x00, 0x00, 0x00, // Width (32)
      0x20, 0x00, 0x00, 0x00, // Height (32)
      0x01, 0x00, // Planes (1)
      0x08, 0x00, // Bits per pixel (8)
      0x00, 0x00, 0x00, 0x00, // Compression (none)
      0x00, 0x10, 0x00, 0x00, // Image size
      0x13, 0x0B, 0x00, 0x00, // X pixels per meter
      0x13, 0x0B, 0x00, 0x00, // Y pixels per meter
      0x00, 0x01, 0x00, 0x00, // Colors used (256)
      0x00, 0x00, 0x00, 0x00, // Important colors
    ];

    // Grayscale palette (256 entries)
    final palette = <int>[];
    for (int i = 0; i < 256; i++) {
      palette.addAll([i, i, i, 0]); // B, G, R, reserved
    }

    // BMP stores rows bottom-to-top
    final reversedPixels = <int>[];
    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        reversedPixels.add(pixels[y * width + x]);
      }
    }

    return Uint8List.fromList([...bmpHeader, ...palette, ...reversedPixels]);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Builds the realistic label preview widget
  Widget _buildLabelPreview() {
    // Calculate printable area (label height minus dead zone)
    final printableHeight = _labelHeightDots - _deadZoneDots;
    final topMarginInPreview = _topMarginDots.clamp(0, printableHeight);

    // Scale factor to fit in screen (max 350px width for display)
    final maxDisplayWidth = 350.0;
    final scale = _labelWidthDots > maxDisplayWidth
        ? maxDisplayWidth / _labelWidthDots
        : 1.0;

    final displayWidth = _labelWidthDots * scale;
    final displayDeadZone = _deadZoneDots * scale;
    final displayPrintableHeight = printableHeight * scale;
    final displayTopMargin = topMarginInPreview * scale;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade600, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dead zone (grey - can't print here)
            if (_deadZoneDots > 0)
              Container(
                width: displayWidth,
                height: displayDeadZone,
                color: Colors.grey.shade300,
                child: displayDeadZone >= 20
                    ? Center(
                        child: Text(
                          '⛔ NO PRINT',
                          style: TextStyle(
                            fontSize: 10 * scale.clamp(0.7, 1.0),
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),

            // Printable area (white background with image overlay)
            ClipRect(
              child: Container(
                width: displayWidth,
                height: displayPrintableHeight.clamp(20, 500),
                color: Colors.white,
                child: Stack(
                  clipBehavior: Clip.hardEdge, // Clip image to label bounds
                  children: [
                    // Top margin indicator (if set)
                    if (displayTopMargin > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: displayTopMargin,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.blue.shade300,
                                width: 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                          child: displayTopMargin >= 12
                              ? Center(
                                  child: Text(
                                    'margin ${(_topMarginDots / 8).toStringAsFixed(1)}mm',
                                    style: TextStyle(
                                      fontSize: 8 * scale.clamp(0.7, 1.0),
                                      color: Colors.blue.shade400,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),

                    // Image preview - scaled to match label scale
                    // Image fills the available width, scaled proportionally
                    if (_previewImage != null)
                      Positioned(
                        top: displayTopMargin,
                        left: 0,
                        right: 0, // Fill width
                        child: Image.memory(
                          _previewImage!,
                          fit: BoxFit.fitWidth, // Scale to fit label width
                          alignment: Alignment.topLeft,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.red,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 32 * scale, color: Colors.grey.shade400),
                            const SizedBox(height: 4),
                            Text(
                              'No image',
                              style: TextStyle(
                                fontSize: 10 * scale.clamp(0.7, 1.0),
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a legend item for the preview
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  /// Builds a label size preset button
  Widget _buildLabelPreset(String label, int widthDots, int heightDots) {
    final isSelected = _labelWidthDots == widthDots && _labelHeightDots == heightDots;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _labelWidthDots = widthDots;
        _labelHeightDots = heightDots;
      }),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Builds a warning widget if image doesn't fit in printable area
  Widget _buildFitWarning() {
    // We don't know actual image dimensions without decoding,
    // but we can show the printable area info
    final printableHeight = _labelHeightDots - _deadZoneDots - _topMarginDots;
    final printableWidth = _labelWidthDots.clamp(0, _maxWidth);

    // For 40x15mm label with 4mm dead zone:
    // Printable area = 40x11mm = 320x88 dots
    final printableHeightMm = (printableHeight / 8).toStringAsFixed(1);
    final printableWidthMm = (printableWidth / 8).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Printable area: ${printableWidthMm}x${printableHeightMm}mm ($printableWidth x $printableHeight dots)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your image should be max $printableWidth x $printableHeight pixels to fit perfectly!',
            style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
          ),
        ],
      ),
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
          // Preview card - realistic label simulation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Label Preview (Realistic)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Label: ${(_labelWidthDots / 8).round()}x${(_labelHeightDots / 8).round()}mm • Dead zone: ${(_deadZoneDots / 8).toStringAsFixed(1)}mm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Realistic label preview with dead zone
                  _buildLabelPreview(),

                  const SizedBox(height: 12),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.grey.shade300, 'Dead zone (no print)'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.white, 'Printable area'),
                    ],
                  ),

                  // Warning if image doesn't fit
                  if (_previewImage != null) ...[
                    const SizedBox(height: 8),
                    _buildFitWarning(),
                  ],

                  const SizedBox(height: 12),

                  // Label size presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildLabelPreset('40x15', 320, 120),
                      _buildLabelPreset('50x25', 400, 200),
                      _buildLabelPreset('50x30', 400, 240),
                      _buildLabelPreset('40x30', 320, 240),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Dead zone slider
                  Row(
                    children: [
                      const Text('Dead zone: ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _deadZoneDots.toDouble(),
                          min: 0,
                          max: 64, // Max 8mm
                          divisions: 64,
                          onChanged: (v) => setState(() => _deadZoneDots = v.round()),
                        ),
                      ),
                      Text('${(_deadZoneDots / 8).toStringAsFixed(1)}mm',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
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
                  Text('Processing Options',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Dithering toggle
                  SwitchListTile(
                    title: const Text('Floyd-Steinberg Dithering'),
                    subtitle: const Text('Better grayscale quality'),
                    value: _dithering,
                    onChanged: (v) => setState(() => _dithering = v),
                  ),

                  // Band mode toggle (for mobile printers)
                  SwitchListTile(
                    title: const Text('Band Mode'),
                    subtitle: const Text('Send image in bands (better for mobile printers)'),
                    value: _bandMode,
                    onChanged: (v) => setState(() => _bandMode = v),
                  ),

                  // Threshold slider
                  if (!_dithering) ...[
                    const SizedBox(height: 8),
                    Text('Threshold: $_threshold'),
                    Slider(
                      value: _threshold.toDouble(),
                      min: 0,
                      max: 255,
                      divisions: 255,
                      onChanged: (v) => setState(() => _threshold = v.round()),
                    ),
                  ],

                  // Width slider
                  const SizedBox(height: 8),
                  Text('Max Width: $_maxWidth px'),
                  Slider(
                    value: _maxWidth.toDouble(),
                    min: 100,
                    max: 384,
                    divisions: 28,
                    onChanged: (v) => setState(() => _maxWidth = v.round()),
                  ),

                  const Divider(),

                  // Label mode toggle
                  SwitchListTile(
                    title: const Text('Label Paper Mode'),
                    subtitle: const Text('Use GS FF to feed to next label after print'),
                    value: _labelMode,
                    onChanged: (v) => setState(() => _labelMode = v),
                  ),

                  // Top margin control (for fine-tuning where print starts)
                  if (_labelMode) ...[
                    const SizedBox(height: 8),
                    Text('Top Margin: $_topMarginDots dots (${(_topMarginDots / 8).toStringAsFixed(1)}mm)'),
                    Slider(
                      value: _topMarginDots.toDouble(),
                      min: 0,
                      max: 80, // Max 10mm
                      divisions: 80,
                      onChanged: (v) => setState(() => _topMarginDots = v.round()),
                    ),
                    Text(
                      'Use to fine-tune vertical position on label',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // BLE Transmission Settings card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BLE Transmission (Speed Tuning)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Increase for speed, decrease if printing fails',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // Chunk size slider
                  Text('Chunk Size: $_chunkSize bytes'),
                  Slider(
                    value: _chunkSize.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    onChanged: (v) {
                      setState(() => _chunkSize = v.round());
                      widget.printer?.setTransmissionParams(chunkSize: _chunkSize);
                    },
                  ),

                  // Delay slider
                  Text('Chunk Delay: $_chunkDelayMs ms'),
                  Slider(
                    value: _chunkDelayMs.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    onChanged: (v) {
                      setState(() => _chunkDelayMs = v.round());
                      widget.printer?.setTransmissionParams(chunkDelayMs: _chunkDelayMs);
                    },
                  ),

                  // Quick presets
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Fast (20/10)'),
                        onPressed: () {
                          setState(() {
                            _chunkSize = 20;
                            _chunkDelayMs = 10;
                          });
                          widget.printer?.setTransmissionParams(
                            chunkSize: 20,
                            chunkDelayMs: 10,
                          );
                        },
                      ),
                      ActionChip(
                        label: const Text('Medium (20/50)'),
                        onPressed: () {
                          setState(() {
                            _chunkSize = 20;
                            _chunkDelayMs = 50;
                          });
                          widget.printer?.setTransmissionParams(
                            chunkSize: 20,
                            chunkDelayMs: 50,
                          );
                        },
                      ),
                      ActionChip(
                        label: const Text('Safe (20/100)'),
                        onPressed: () {
                          setState(() {
                            _chunkSize = 20;
                            _chunkDelayMs = 100;
                          });
                          widget.printer?.setTransmissionParams(
                            chunkSize: 20,
                            chunkDelayMs: 100,
                          );
                        },
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
            onPressed: isConnected && !_isPrinting ? _printImage : null,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: Text(_isPrinting ? 'Printing...' : 'Print Image'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 8),

          // Test pattern button
          OutlinedButton.icon(
            onPressed: isConnected && !_isPrinting
                ? () async {
                    setState(() => _isPrinting = true);
                    try {
                      await widget.printer!.printImage(
                        _createSimpleTestImage(),
                        maxWidth: _maxWidth,
                        dithering: false,
                      );
                      await widget.printer!.feedLines(3);
                      _showMessage('Test pattern printed!');
                    } catch (e) {
                      _showMessage('Print failed: $e');
                    } finally {
                      setState(() => _isPrinting = false);
                    }
                  }
                : null,
            icon: const Icon(Icons.grid_on),
            label: const Text('Print Test Pattern'),
          ),
        ],
      ),
    );
  }
}
