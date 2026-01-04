/// Text styling options for SK58 printer.
library;

/// Text alignment options for printing.
enum Sk58Align {
  /// Align text to the left.
  left(0),

  /// Center text.
  center(1),

  /// Align text to the right.
  right(2);

  /// The ESC/POS command value for this alignment.
  final int value;

  const Sk58Align(this.value);
}

/// Font size options for printing.
enum Sk58FontSize {
  /// Normal size (1x1).
  normal(1, 1),

  /// Double width (2x1).
  wide(2, 1),

  /// Double height (1x2).
  tall(1, 2),

  /// Large size (2x2).
  large(2, 2),

  /// Extra large size (3x3).
  extraLarge(3, 3);

  /// Width multiplier (1-8).
  final int widthMultiplier;

  /// Height multiplier (1-8).
  final int heightMultiplier;

  const Sk58FontSize(this.widthMultiplier, this.heightMultiplier);
}

/// Text style configuration for printing.
///
/// Combines font size, bold, and underline options.
class Sk58TextStyle {
  /// Whether text should be bold.
  final bool bold;

  /// Whether text should be underlined.
  final bool underline;

  /// Font size for the text.
  final Sk58FontSize size;

  /// Creates a text style with the specified options.
  const Sk58TextStyle({
    this.bold = false,
    this.underline = false,
    this.size = Sk58FontSize.normal,
  });

  /// Normal text style (no modifications).
  static const normal = Sk58TextStyle();

  /// Bold text style.
  static const boldStyle = Sk58TextStyle(bold: true);

  /// Underlined text style.
  static const underlineStyle = Sk58TextStyle(underline: true);

  /// Large text style (2x2).
  static const largeStyle = Sk58TextStyle(size: Sk58FontSize.large);

  /// Bold and large text style.
  static const boldLarge = Sk58TextStyle(bold: true, size: Sk58FontSize.large);

  /// Creates a copy of this style with the specified modifications.
  Sk58TextStyle copyWith({
    bool? bold,
    bool? underline,
    Sk58FontSize? size,
  }) {
    return Sk58TextStyle(
      bold: bold ?? this.bold,
      underline: underline ?? this.underline,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sk58TextStyle &&
        other.bold == bold &&
        other.underline == underline &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(bold, underline, size);
}
