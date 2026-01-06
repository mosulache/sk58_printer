# Changelog

## 0.2.2

### Added
- **Realistic Label Preview**: Image demo now shows a realistic label preview with:
  - Dead zone visualization (grey "NO PRINT" area at top)
  - Printable area (white)
  - Top margin indicator (blue)
  - Label size presets (40x15, 50x25, 50x30, 40x30mm)
  - Adjustable dead zone slider (0-8mm)
  - Fit warning showing exact printable dimensions
- **feedAfter parameter**: New `feedAfter` parameter in `printImage()` to control line feed after image
  - Default `false` for labels (no extra whitespace)
  - Set `true` for continuous paper
- **Documentation**: Added printer specifications and dead zone info to README

### Changed
- Image preview now scales correctly with label size
- Improved label printing workflow in example app

## 0.2.1

### Added
- **Label Feed Offset**: New `extraFeedDots` parameter for fine-tuning label positioning
- **New label commands**: 
  - `formFeed()` - Simple FF (0x0C) command
  - `printAndPeel()` - GS FF (0x1D 0x0C) - **recommended for SK58**
  - `feedDots(int)` - ESC J n for precise dot feeding
  - `feedLines(int)` - ESC d n for line feeding
  - `feedToStartPosition` - FS ( L fn=67 alternative command
- **Label Mode in Image Demo**: Option to use label paper mode with feed offset adjustment
- **Feed Test Buttons**: New test card in Labels demo to try different feed methods

### Fixed
- **Label alignment fix**: `feedToNextLabel()` now uses **GS FF** (0x1D 0x0C) command
  - Tested and confirmed working on SK58 printers
  - Fixes issue where 3 labels were printed on 2 physical labels
  - Labels now correctly advance to the next label gap

### Changed
- `LabelCommands.feedToNextLabel` now uses GS FF (0x1D 0x0C) instead of FF for reliable label feeding
- `printAndPeel()` is now an alias for `feedToNextLabel()` (same GS FF command)

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
