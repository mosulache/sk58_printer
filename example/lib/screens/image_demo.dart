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
  Uint8List? _previewImage;
  final String _selectedAsset = 'assets/demo_logo.png';

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

      await widget.printer!.printImage(
        imageData,
        maxWidth: _maxWidth,
        dithering: _dithering,
        threshold: _threshold,
        bandMode: _bandMode,
      );
      await widget.printer!.feedLines(3);

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

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.printer?.isConnected == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Image Preview',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey[100],
                    ),
                    child: _previewImage != null
                        ? Image.memory(
                            _previewImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 64),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No image\n(will use test pattern)',
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add assets/demo_logo.png to test\nor use test pattern',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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
