import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('Sk58PaperType', () {
    test('has correct values', () {
      expect(Sk58PaperType.values.length, 3);
      expect(Sk58PaperType.continuous, isNotNull);
      expect(Sk58PaperType.labelWithGap, isNotNull);
      expect(Sk58PaperType.labelWithBlackMark, isNotNull);
    });
  });

  group('LabelCommands', () {
    test('setContinuousMode returns correct bytes', () {
      final commands = LabelCommands.setContinuousMode();
      expect(commands, [0x1B, 0x63, 0x36, 0x00]);
    });

    test('setLabelGapMode returns correct bytes', () {
      final commands = LabelCommands.setLabelGapMode();
      expect(commands, [0x1B, 0x63, 0x36, 0x01]);
    });

    test('setBlackMarkMode returns correct bytes', () {
      final commands = LabelCommands.setBlackMarkMode();
      expect(commands, [0x1B, 0x63, 0x36, 0x02]);
    });

    test('setPaperType returns correct bytes for each type', () {
      expect(
        LabelCommands.setPaperType(Sk58PaperType.continuous),
        [0x1B, 0x63, 0x36, 0x00],
      );
      expect(
        LabelCommands.setPaperType(Sk58PaperType.labelWithGap),
        [0x1B, 0x63, 0x36, 0x01],
      );
      expect(
        LabelCommands.setPaperType(Sk58PaperType.labelWithBlackMark),
        [0x1B, 0x63, 0x36, 0x02],
      );
    });

    test('feedToNextLabel returns GS FF command', () {
      // GS FF - The best command for SK58 label feeding
      // Hex: 1D 0C
      expect(LabelCommands.feedToNextLabel, [0x1D, 0x0C]);
    });

    test('printAndPeel is alias for feedToNextLabel (GS FF)', () {
      expect(LabelCommands.printAndPeel, [0x1D, 0x0C]);
      expect(LabelCommands.printAndPeel, LabelCommands.feedToNextLabel);
    });

    test('formFeed returns simple form feed (FF)', () {
      expect(LabelCommands.formFeed, [0x0C]);
    });

    test('feedToStartPosition returns FS ( L fn=67 command', () {
      // FS ( L pL pH fn m - Alternative feed command
      // Hex: 1C 28 4C 02 00 43 32
      expect(LabelCommands.feedToStartPosition,
          [0x1C, 0x28, 0x4C, 0x02, 0x00, 0x43, 0x32]);
    });

    test('feedDots returns ESC J n command', () {
      expect(LabelCommands.feedDots(24), [0x1B, 0x4A, 24]);
      expect(LabelCommands.feedDots(0), [0x1B, 0x4A, 0]);
      expect(LabelCommands.feedDots(300), [0x1B, 0x4A, 255]); // Clamped
    });

    test('feedLines returns ESC d n command', () {
      expect(LabelCommands.feedLines(5), [0x1B, 0x64, 5]);
    });

    test('calibrateLabels returns GS ( F command', () {
      final commands = LabelCommands.calibrateLabels;
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x28); // (
      expect(commands[2], 0x46); // F
    });

    test('setLabelHeight generates correct command', () {
      // 400 dots = 50mm height
      final commands = LabelCommands.setLabelHeight(400);
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x28); // (
      expect(commands[2], 0x46); // F
      expect(commands[5], 0x01); // function: set page length
      // 400 in little-endian: 0x90, 0x01
      expect(commands[7], 0x90); // nL
      expect(commands[8], 0x01); // nH
    });

    test('setLabelWidth generates correct command', () {
      // 320 dots = 40mm width
      final commands = LabelCommands.setLabelWidth(320);
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x57); // W
      // 320 in little-endian: 0x40, 0x01
      expect(commands[2], 0x40); // nL
      expect(commands[3], 0x01); // nH
    });

    test('setLabelWidth clamps to max 384', () {
      final commands = LabelCommands.setLabelWidth(500); // Over max
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x57); // W
      // Should be clamped to 384: 0x80, 0x01
      expect(commands[2], 0x80); // nL
      expect(commands[3], 0x01); // nH
    });

    test('setLeftMargin generates correct command', () {
      final commands = LabelCommands.setLeftMargin(24); // 3mm margin
      expect(commands[0], 0x1D); // GS
      expect(commands[1], 0x4C); // L
      expect(commands[2], 24); // nL
      expect(commands[3], 0); // nH
    });

    test('setPrintDensity generates correct command', () {
      for (int level = 1; level <= 5; level++) {
        final commands = LabelCommands.setPrintDensity(level);
        expect(commands[0], 0x1B); // ESC
        expect(commands[1], 0x37); // 7
      }
    });

    test('setPrintDensity clamps to 1-5', () {
      // Test values outside range are clamped
      final low = LabelCommands.setPrintDensity(0);
      final high = LabelCommands.setPrintDensity(10);

      // Both should produce valid commands
      expect(low.length, 5);
      expect(high.length, 5);
    });

    test('setPrintSpeed generates correct command', () {
      for (int level = 1; level <= 3; level++) {
        final commands = LabelCommands.setPrintSpeed(level);
        expect(commands[0], 0x1B); // ESC
        expect(commands[1], 0x73); // s
        expect(commands[2], level);
      }
    });

    test('setRotation generates correct commands', () {
      expect(LabelCommands.setRotation(0), [0x1B, 0x56, 0x00]);
      expect(LabelCommands.setRotation(90), [0x1B, 0x56, 0x01]);
      expect(LabelCommands.setRotation(180), [0x1B, 0x56, 0x02]);
      expect(LabelCommands.setRotation(270), [0x1B, 0x56, 0x03]);
      expect(LabelCommands.setRotation(45), [0x1B, 0x56, 0x00]); // Invalid -> 0
    });

    test('requestStatus returns DLE EOT command', () {
      expect(LabelCommands.requestStatus, [0x10, 0x04, 0x01]);
    });

    test('requestPaperStatus returns correct command', () {
      expect(LabelCommands.requestPaperStatus, [0x10, 0x04, 0x04]);
    });
  });

  group('LabelPrintConfig', () {
    test('creates config with default values', () {
      const config = LabelPrintConfig(widthMm: 50, heightMm: 80);

      expect(config.widthMm, 50);
      expect(config.heightMm, 80);
      expect(config.paperType, Sk58PaperType.labelWithGap);
      expect(config.density, 3);
      expect(config.speed, 2);
      expect(config.rotation, 0);
      expect(config.leftMarginMm, 0);
    });

    test('toCommands returns empty by default (safe mode)', () {
      const config = LabelPrintConfig(
        widthMm: 40,
        heightMm: 30,
        paperType: Sk58PaperType.labelWithGap,
        density: 4,
        speed: 1,
      );

      final commands = config.toCommands();

      // Should be empty by default (safe mode)
      expect(commands.isEmpty, isTrue);
    });

    test('toCommands generates valid command sequence with advanced mode', () {
      const config = LabelPrintConfig(
        widthMm: 40,
        heightMm: 30,
        paperType: Sk58PaperType.labelWithGap,
        density: 4,
        speed: 1,
        useAdvancedCommands: true, // Enable advanced commands
      );

      final commands = config.toCommands();

      // Should not be empty in advanced mode
      expect(commands.isNotEmpty, isTrue);

      // Should start with paper type command
      expect(commands.sublist(0, 4), [0x1B, 0x63, 0x36, 0x01]);
    });

    test('toCommands includes rotation when specified (advanced mode)', () {
      const config = LabelPrintConfig(
        widthMm: 40,
        heightMm: 30,
        rotation: 90,
        useAdvancedCommands: true, // Enable advanced commands
      );

      final commands = config.toCommands();

      // Should contain rotation command
      expect(commands.contains(0x56), isTrue); // V in ESC V n
    });

    test('toCommands includes margin when specified (advanced mode)', () {
      const config = LabelPrintConfig(
        widthMm: 40,
        heightMm: 30,
        leftMarginMm: 2,
        useAdvancedCommands: true, // Enable advanced commands
      );

      final commands = config.toCommands();

      // Should contain margin command GS L
      expect(commands.contains(0x4C), isTrue); // L in GS L
    });
  });
}
