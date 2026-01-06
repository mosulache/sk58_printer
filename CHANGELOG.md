# Changelog

## 0.2.0

### Added
- **Band Mode for Image Printing**: New `bandMode` parameter in `printImage()` for reliable image printing on mobile printers and small labels
  - Uses ESC * 33 (24-dot double density) command
  - Sends image in 24-line bands instead of all at once
  - Recommended for printers with limited buffers

### Fixed
- Image printing on mobile thermal printers now works correctly
- Images no longer appear stretched or corrupted on small labels (e.g., 40x15mm)

### Changed
- `toLineByLineCommands()` in `ProcessedImage` now uses ESC * 33 instead of GS v 0 bands
- Default `maxWidth` in example app reduced to 280px for better label compatibility

## 0.1.0

- Initial release
- Bluetooth scanning for SK58 printers
- Connect/disconnect functionality
- Print text with alignment and styles (bold, underline, sizes)
- Print QR codes
- Print barcodes (Code128, EAN-13, UPC-A, Code39)
- Print images with Floyd-Steinberg dithering
- Label templates (Sk58Label, Sk58TwoColumnLabel)
- Fluent builder pattern for complex prints
- Support for Android and Linux platforms
