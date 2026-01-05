/// ESC/POS commands specific to label printing on SK58.
///
/// Based on SK58 User Manual - supports gap detection and black mark detection.
library;

/// Paper type modes for SK58 printer.
enum Sk58PaperType {
  /// Continuous paper (receipt mode) - no gap detection.
  continuous,

  /// Label paper with gaps - uses reflective label detection.
  labelWithGap,

  /// Label paper with black marks - uses black mark detection.
  labelWithBlackMark,
}

/// Label-specific ESC/POS commands for SK58 printer.
class LabelCommands {
  LabelCommands._();

  // ==========================================================================
  // PAPER TYPE COMMANDS
  // ==========================================================================

  /// Set paper type to continuous (receipt mode).
  ///
  /// No gap or black mark detection - paper feeds continuously.
  static List<int> setContinuousMode() {
    // ESC c 6 n - Select paper type
    // n = 0: Continuous paper
    return [0x1B, 0x63, 0x36, 0x00];
  }

  /// Set paper type to label with gap detection.
  ///
  /// Printer will detect gaps between labels and stop at label boundaries.
  /// Gap must be ≥ 2mm for reliable detection.
  static List<int> setLabelGapMode() {
    // ESC c 6 n - Select paper type
    // n = 1: Label paper with gap
    return [0x1B, 0x63, 0x36, 0x01];
  }

  /// Set paper type to label with black mark detection.
  ///
  /// Printer will detect black marks on paper for positioning.
  static List<int> setBlackMarkMode() {
    // ESC c 6 n - Select paper type
    // n = 2: Label paper with black mark
    return [0x1B, 0x63, 0x36, 0x02];
  }

  /// Set paper type by enum.
  static List<int> setPaperType(Sk58PaperType type) {
    switch (type) {
      case Sk58PaperType.continuous:
        return setContinuousMode();
      case Sk58PaperType.labelWithGap:
        return setLabelGapMode();
      case Sk58PaperType.labelWithBlackMark:
        return setBlackMarkMode();
    }
  }

  // ==========================================================================
  // LABEL POSITIONING COMMANDS
  // ==========================================================================

  /// Feed paper to next label (form feed).
  ///
  /// In label mode, this advances paper to the next label gap/mark.
  /// In continuous mode, this acts as a page break.
  static List<int> get feedToNextLabel => [0x0C]; // FF (Form Feed)

  /// Calibrate label detection.
  ///
  /// Printer will feed paper to detect label size and gap position.
  /// Should be called after loading new paper.
  static List<int> get calibrateLabels {
    // GS ( F pL pH a m nL nH - Paper layout setting
    // This tells printer to learn the label layout
    return [
      0x1D, 0x28, 0x46, // GS ( F
      0x02, 0x00, // pL pH (2 bytes follow)
      0x00, // a (function: auto calibrate)
      0x00, // Reserved
    ];
  }

  /// Set label height in dots.
  ///
  /// [heightDots] - Label height in dots (at 203 DPI, 8 dots = 1mm).
  static List<int> setLabelHeight(int heightDots) {
    final nL = heightDots & 0xFF;
    final nH = (heightDots >> 8) & 0xFF;

    // GS ( F pL pH a m nL nH - Set page length
    return [
      0x1D, 0x28, 0x46, // GS ( F
      0x04, 0x00, // pL pH (4 bytes follow)
      0x01, // a (function: set page length)
      0x00, // m (unit: dots)
      nL, nH, // nL nH (length in dots, little-endian)
    ];
  }

  /// Set label width in dots.
  ///
  /// [widthDots] - Label width in dots. Max 384 (48mm effective width).
  static List<int> setLabelWidth(int widthDots) {
    // Clamp to max effective print width
    final effectiveWidth = widthDots.clamp(0, 384);
    final nL = effectiveWidth & 0xFF;
    final nH = (effectiveWidth >> 8) & 0xFF;

    // GS W nL nH - Set printing area width
    return [0x1D, 0x57, nL, nH];
  }

  /// Set print area margins.
  ///
  /// [leftMarginDots] - Left margin in dots.
  static List<int> setLeftMargin(int leftMarginDots) {
    final nL = leftMarginDots & 0xFF;
    final nH = (leftMarginDots >> 8) & 0xFF;

    // GS L nL nH - Set left margin
    return [0x1D, 0x4C, nL, nH];
  }

  // ==========================================================================
  // PRINT DENSITY & SPEED
  // ==========================================================================

  /// Set print density (darkness).
  ///
  /// [level] - Density level 1-5 (1=lightest, 5=darkest).
  /// From manual: "Short-press feed button 3 times to increase by 1 level"
  static List<int> setPrintDensity(int level) {
    final n = level.clamp(1, 5);
    // ESC 7 n1 n2 n3 - Set control parameters
    // n1 = max heating dots, n2 = heating time, n3 = heating interval
    // Higher values = darker print
    final heatingTime = 60 + (n - 1) * 20; // 60-140
    return [0x1B, 0x37, 0x07, heatingTime, 0x02];
  }

  /// Set print speed.
  ///
  /// [level] - Speed level 1-3 (1=slowest/best quality, 3=fastest).
  /// From manual: "Press feed button 5 times to increase quality by 1 level"
  static List<int> setPrintSpeed(int level) {
    final n = level.clamp(1, 3);
    // ESC s n - Set print speed
    return [0x1B, 0x73, n];
  }

  // ==========================================================================
  // ROTATION COMMANDS
  // ==========================================================================

  /// Rotation options for printing.
  static List<int> setRotation(int degrees) {
    // ESC V n - Turn 90° clockwise rotation on/off
    // Supported: 0°, 90°, 180°, 270°
    switch (degrees) {
      case 0:
        return [0x1B, 0x56, 0x00];
      case 90:
        return [0x1B, 0x56, 0x01];
      case 180:
        return [0x1B, 0x56, 0x02];
      case 270:
        return [0x1B, 0x56, 0x03];
      default:
        return [0x1B, 0x56, 0x00]; // Default to 0°
    }
  }

  // ==========================================================================
  // STATUS COMMANDS
  // ==========================================================================

  /// Request printer status.
  ///
  /// Returns command to query current printer state.
  /// Response indicates: paper status, cover status, temperature, etc.
  static List<int> get requestStatus {
    // DLE EOT n - Real-time status transmission
    return [0x10, 0x04, 0x01];
  }

  /// Request paper sensor status.
  static List<int> get requestPaperStatus {
    return [0x10, 0x04, 0x04];
  }
}

/// Convenience class for configuring label printing session.
class LabelPrintConfig {
  /// Paper type (continuous, gap, or black mark).
  final Sk58PaperType paperType;

  /// Label width in mm.
  final double widthMm;

  /// Label height in mm.
  final double heightMm;

  /// Left margin in mm (default 0).
  final double leftMarginMm;

  /// Print density level 1-5 (default 3).
  final int density;

  /// Print speed level 1-3 (default 2).
  final int speed;

  /// Rotation in degrees (0, 90, 180, 270).
  final int rotation;

  /// Whether to send advanced ESC/POS commands.
  ///
  /// **WARNING**: Many SK58 printers do NOT support these commands!
  /// If you see garbage characters printed, set this to `false`.
  ///
  /// Advanced commands include:
  /// - ESC c 6 (paper type selection)
  /// - GS W (print area width)
  /// - GS ( F (page layout)
  /// - ESC s (print speed)
  ///
  /// Default is `false` for maximum compatibility.
  final bool useAdvancedCommands;

  /// Creates a label print configuration.
  const LabelPrintConfig({
    this.paperType = Sk58PaperType.labelWithGap,
    required this.widthMm,
    required this.heightMm,
    this.leftMarginMm = 0,
    this.density = 3,
    this.speed = 2,
    this.rotation = 0,
    this.useAdvancedCommands = false,
  });

  /// Generate ESC/POS commands to configure printer for this label.
  ///
  /// **By default, returns empty list** for maximum compatibility.
  ///
  /// Set [useAdvancedCommands] to `true` to enable advanced commands
  /// (may cause garbage output on printers that don't support them).
  ///
  /// Most SK58 printers handle labels automatically via gap detection
  /// hardware - no special commands needed!
  List<int> toCommands() {
    // By default, don't send any special commands
    // SK58 handles label detection in hardware
    if (!useAdvancedCommands) {
      return [];
    }

    final List<int> commands = [];

    // WARNING: These commands are NOT supported by all SK58 printers!
    // They may print as garbage characters instead of being executed.

    // Set paper type (ESC c 6) - often NOT supported
    commands.addAll(LabelCommands.setPaperType(paperType));

    // Set dimensions (convert mm to dots at 8 dots/mm)
    final widthDots = (widthMm * 8).round().clamp(0, 384);
    final heightDots = (heightMm * 8).round();

    // GS W - set print area width - often NOT supported
    commands.addAll(LabelCommands.setLabelWidth(widthDots));

    // GS ( F - page layout - often NOT supported
    commands.addAll(LabelCommands.setLabelHeight(heightDots));

    // Set margin if specified
    if (leftMarginMm > 0) {
      final marginDots = (leftMarginMm * 8).round();
      commands.addAll(LabelCommands.setLeftMargin(marginDots));
    }

    // ESC 7 - density (heating time)
    commands.addAll(LabelCommands.setPrintDensity(density));

    // ESC s - speed
    commands.addAll(LabelCommands.setPrintSpeed(speed));

    // Set rotation if needed
    if (rotation != 0) {
      commands.addAll(LabelCommands.setRotation(rotation));
    }

    return commands;
  }
}
