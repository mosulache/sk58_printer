/// Configuration constants for SK58 thermal label printer.
///
/// Based on SK58 User Manual specifications.
/// Reference: SK58 Product Specification & Development Manual
library;

/// Hardware specifications for SK58 printer.
///
/// These values are from the official SK58 User Manual.
class Sk58Specs {
  Sk58Specs._();

  /// Printer resolution in DPI.
  static const int dpi = 203;

  /// Dot pitch in mm (0.125mm = 8 dots per mm).
  static const double dotPitchMm = 0.125;

  /// Dots per millimeter (calculated from DPI).
  static const double dotsPerMm = 8.0; // 203 DPI ≈ 8 dots/mm

  /// Effective printing width in mm.
  ///
  /// This is the actual printable area, not the paper width.
  static const double effectivePrintWidthMm = 48.0;

  /// Maximum print width in dots.
  ///
  /// 48mm × 8 dots/mm = 384 dots
  static const int maxPrintWidthDots = 384;

  /// Maximum print speed in mm/s.
  static const int maxPrintSpeedMmPerSec = 50;

  /// Supported paper widths in mm.
  static const List<int> supportedPaperWidths = [58, 50, 40, 30];

  /// Minimum label gap in mm (for gap detection).
  static const double minLabelGapMm = 2.0;

  /// Default character width in dots (Font A, normal size).
  static const int charWidthDots = 12;

  /// Default character height in dots (Font A, normal size).
  static const int charHeightDots = 24;

  /// Convert mm to dots.
  static int mmToDots(double mm) => (mm * dotsPerMm).round();

  /// Convert dots to mm.
  static double dotsToMm(int dots) => dots / dotsPerMm;

  /// Calculate characters per line for a given width in mm.
  ///
  /// Limited by effective print width (48mm).
  static int charsPerLine(double widthMm) {
    final effectiveWidth =
        widthMm > effectivePrintWidthMm ? effectivePrintWidthMm : widthMm;
    return (effectiveWidth * dotsPerMm / charWidthDots).floor();
  }
}

/// Predefined label sizes for SK58 printer.
///
/// All dimensions are in millimeters (width × height).
/// Available paper widths: 50mm, 40mm, 30mm
enum Sk58LabelSize {
  // 50mm width labels
  /// 50mm × 80mm label
  label50x80(50, 80),

  /// 50mm × 50mm label
  label50x50(50, 50),

  /// 50mm × 40mm label
  label50x40(50, 40),

  /// 50mm × 30mm label
  label50x30(50, 30),

  // 40mm width labels
  /// 40mm × 60mm label
  label40x60(40, 60),

  /// 40mm × 30mm label
  label40x30(40, 30),

  /// 40mm × 20mm label
  label40x20(40, 20),

  /// 40mm × 15mm label
  label40x15(40, 15),

  // 30mm width labels
  /// 30mm × 30mm label
  label30x30(30, 30),

  /// 30mm × 20mm label
  label30x20(30, 20);

  /// Label width in mm.
  final int widthMm;

  /// Label height in mm.
  final int heightMm;

  const Sk58LabelSize(this.widthMm, this.heightMm);

  /// Label width in dots (at 203 DPI).
  int get widthDots => Sk58Specs.mmToDots(widthMm.toDouble());

  /// Label height in dots (at 203 DPI).
  int get heightDots => Sk58Specs.mmToDots(heightMm.toDouble());

  /// Printable width in dots (limited by 48mm effective print width).
  int get printableWidthDots => widthDots > Sk58Specs.maxPrintWidthDots
      ? Sk58Specs.maxPrintWidthDots
      : widthDots;

  /// Printable height in dots.
  int get printableHeightDots => heightDots;

  /// Characters per line (with standard Font A, 12 dots/char).
  int get charsPerLine =>
      (printableWidthDots / Sk58Specs.charWidthDots).floor();

  /// Human-readable name (e.g., "50×80mm").
  String get displayName => '${widthMm}×${heightMm}mm';

  /// Get label size by dimensions.
  ///
  /// Returns null if no matching predefined size exists.
  static Sk58LabelSize? fromDimensions(int widthMm, int heightMm) {
    for (final size in values) {
      if (size.widthMm == widthMm && size.heightMm == heightMm) {
        return size;
      }
    }
    return null;
  }

  /// Get all label sizes for a specific paper width.
  static List<Sk58LabelSize> forPaperWidth(int widthMm) {
    return values.where((size) => size.widthMm == widthMm).toList();
  }
}

/// Custom label configuration for non-standard sizes.
class Sk58CustomLabel {
  /// Label width in mm.
  final double widthMm;

  /// Label height in mm.
  final double heightMm;

  /// Gap between labels in mm (default: 2mm minimum).
  final double gapMm;

  /// Creates a custom label configuration.
  ///
  /// [widthMm] must be ≤ 58mm (max paper width).
  /// [heightMm] should be reasonable for the paper roll diameter.
  /// [gapMm] must be ≥ 2mm for gap detection to work.
  Sk58CustomLabel({
    required this.widthMm,
    required this.heightMm,
    this.gapMm = 2.0,
  })  : assert(widthMm > 0 && widthMm <= 58, 'Width must be 0-58mm'),
        assert(heightMm > 0, 'Height must be positive'),
        assert(gapMm >= 2.0, 'Gap must be ≥ 2mm for detection');

  /// Label width in dots.
  int get widthDots => Sk58Specs.mmToDots(widthMm);

  /// Label height in dots.
  int get heightDots => Sk58Specs.mmToDots(heightMm);

  /// Printable width in dots (limited by effective print width).
  int get printableWidthDots => widthDots > Sk58Specs.maxPrintWidthDots
      ? Sk58Specs.maxPrintWidthDots
      : widthDots;

  /// Characters per line.
  int get charsPerLine =>
      (printableWidthDots / Sk58Specs.charWidthDots).floor();

  /// Gap in dots.
  int get gapDots => Sk58Specs.mmToDots(gapMm);
}

/// Black mark detection positions from SK58 manual.
///
/// These are the reference positions (A, B) for black mark detection
/// based on paper width.
class BlackMarkPositions {
  BlackMarkPositions._();

  /// Get black mark position A (center offset) for paper width.
  static double getPositionA(int paperWidthMm) {
    switch (paperWidthMm) {
      case 30:
        return 9.5;
      case 40:
        return 14.5;
      case 50:
        return 19.5;
      case 58:
        return 22.0;
      default:
        return 0;
    }
  }

  /// Get black mark position B for paper width.
  /// Position B is typically half the paper width.
  static double getPositionB(int paperWidthMm) {
    return paperWidthMm / 2.0;
  }
}
