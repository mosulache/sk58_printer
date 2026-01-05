import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('Sk58Specs', () {
    test('DPI is 203', () {
      expect(Sk58Specs.dpi, 203);
    });

    test('dots per mm is approximately 8', () {
      expect(Sk58Specs.dotsPerMm, 8.0);
    });

    test('effective print width is 48mm / 384 dots', () {
      expect(Sk58Specs.effectivePrintWidthMm, 48.0);
      expect(Sk58Specs.maxPrintWidthDots, 384);
    });

    test('mmToDots converts correctly', () {
      expect(Sk58Specs.mmToDots(1), 8); // 1mm = 8 dots
      expect(Sk58Specs.mmToDots(48), 384); // 48mm = 384 dots
      expect(Sk58Specs.mmToDots(50), 400); // 50mm = 400 dots
      expect(Sk58Specs.mmToDots(40), 320); // 40mm = 320 dots
      expect(Sk58Specs.mmToDots(30), 240); // 30mm = 240 dots
    });

    test('dotsToMm converts correctly', () {
      expect(Sk58Specs.dotsToMm(8), 1.0); // 8 dots = 1mm
      expect(Sk58Specs.dotsToMm(384), 48.0); // 384 dots = 48mm
    });

    test('charsPerLine calculates correctly', () {
      // At 12 dots per char
      expect(Sk58Specs.charsPerLine(48), 32); // 48mm = 384 dots / 12 = 32 chars
      expect(Sk58Specs.charsPerLine(40), 26); // 40mm = 320 dots / 12 = 26 chars
      expect(Sk58Specs.charsPerLine(30), 20); // 30mm = 240 dots / 12 = 20 chars
    });

    test('charsPerLine is limited by effective print width', () {
      // Even 50mm paper is limited to 48mm effective width
      expect(Sk58Specs.charsPerLine(50), 32); // Still 32 chars
      expect(Sk58Specs.charsPerLine(58), 32); // Still 32 chars
    });

    test('supported paper widths are correct', () {
      expect(Sk58Specs.supportedPaperWidths, [58, 50, 40, 30]);
    });
  });

  group('Sk58LabelSize', () {
    test('all label sizes are defined', () {
      expect(Sk58LabelSize.values.length, 10);
    });

    test('50mm width labels have correct dimensions', () {
      expect(Sk58LabelSize.label50x80.widthMm, 50);
      expect(Sk58LabelSize.label50x80.heightMm, 80);

      expect(Sk58LabelSize.label50x50.widthMm, 50);
      expect(Sk58LabelSize.label50x50.heightMm, 50);

      expect(Sk58LabelSize.label50x40.widthMm, 50);
      expect(Sk58LabelSize.label50x40.heightMm, 40);

      expect(Sk58LabelSize.label50x30.widthMm, 50);
      expect(Sk58LabelSize.label50x30.heightMm, 30);
    });

    test('40mm width labels have correct dimensions', () {
      expect(Sk58LabelSize.label40x60.widthMm, 40);
      expect(Sk58LabelSize.label40x60.heightMm, 60);

      expect(Sk58LabelSize.label40x30.widthMm, 40);
      expect(Sk58LabelSize.label40x30.heightMm, 30);

      expect(Sk58LabelSize.label40x20.widthMm, 40);
      expect(Sk58LabelSize.label40x20.heightMm, 20);

      expect(Sk58LabelSize.label40x15.widthMm, 40);
      expect(Sk58LabelSize.label40x15.heightMm, 15);
    });

    test('30mm width labels have correct dimensions', () {
      expect(Sk58LabelSize.label30x30.widthMm, 30);
      expect(Sk58LabelSize.label30x30.heightMm, 30);

      expect(Sk58LabelSize.label30x20.widthMm, 30);
      expect(Sk58LabelSize.label30x20.heightMm, 20);
    });

    test('widthDots and heightDots are calculated correctly', () {
      // 50x80mm
      expect(Sk58LabelSize.label50x80.widthDots, 400); // 50 * 8
      expect(Sk58LabelSize.label50x80.heightDots, 640); // 80 * 8

      // 40x30mm
      expect(Sk58LabelSize.label40x30.widthDots, 320); // 40 * 8
      expect(Sk58LabelSize.label40x30.heightDots, 240); // 30 * 8

      // 30x20mm
      expect(Sk58LabelSize.label30x20.widthDots, 240); // 30 * 8
      expect(Sk58LabelSize.label30x20.heightDots, 160); // 20 * 8
    });

    test('printableWidthDots is limited to 384', () {
      // 50mm label = 400 dots, but limited to 384
      expect(Sk58LabelSize.label50x80.printableWidthDots, 384);

      // 40mm label = 320 dots, not limited
      expect(Sk58LabelSize.label40x30.printableWidthDots, 320);

      // 30mm label = 240 dots, not limited
      expect(Sk58LabelSize.label30x30.printableWidthDots, 240);
    });

    test('charsPerLine is calculated correctly', () {
      // 50mm -> 384 dots / 12 = 32 chars
      expect(Sk58LabelSize.label50x80.charsPerLine, 32);

      // 40mm -> 320 dots / 12 = 26 chars
      expect(Sk58LabelSize.label40x30.charsPerLine, 26);

      // 30mm -> 240 dots / 12 = 20 chars
      expect(Sk58LabelSize.label30x30.charsPerLine, 20);
    });

    test('displayName formats correctly', () {
      expect(Sk58LabelSize.label50x80.displayName, '50×80mm');
      expect(Sk58LabelSize.label40x15.displayName, '40×15mm');
      expect(Sk58LabelSize.label30x20.displayName, '30×20mm');
    });

    test('fromDimensions finds correct label', () {
      expect(Sk58LabelSize.fromDimensions(50, 80), Sk58LabelSize.label50x80);
      expect(Sk58LabelSize.fromDimensions(40, 15), Sk58LabelSize.label40x15);
      expect(Sk58LabelSize.fromDimensions(30, 30), Sk58LabelSize.label30x30);
      expect(Sk58LabelSize.fromDimensions(99, 99), isNull);
    });

    test('forPaperWidth returns correct labels', () {
      final labels50 = Sk58LabelSize.forPaperWidth(50);
      expect(labels50.length, 4);
      expect(labels50.every((l) => l.widthMm == 50), isTrue);

      final labels40 = Sk58LabelSize.forPaperWidth(40);
      expect(labels40.length, 4);
      expect(labels40.every((l) => l.widthMm == 40), isTrue);

      final labels30 = Sk58LabelSize.forPaperWidth(30);
      expect(labels30.length, 2);
      expect(labels30.every((l) => l.widthMm == 30), isTrue);
    });
  });

  group('Sk58CustomLabel', () {
    test('creates custom label with valid dimensions', () {
      final label = Sk58CustomLabel(widthMm: 45, heightMm: 35);
      expect(label.widthMm, 45);
      expect(label.heightMm, 35);
      expect(label.gapMm, 2.0); // default
    });

    test('calculates dots correctly', () {
      final label = Sk58CustomLabel(widthMm: 45, heightMm: 35);
      expect(label.widthDots, 360); // 45 * 8
      expect(label.heightDots, 280); // 35 * 8
    });

    test('printableWidthDots is limited to 384', () {
      final labelWide = Sk58CustomLabel(widthMm: 55, heightMm: 30);
      expect(labelWide.printableWidthDots, 384); // Limited

      final labelNarrow = Sk58CustomLabel(widthMm: 35, heightMm: 30);
      expect(labelNarrow.printableWidthDots, 280); // Not limited
    });

    test('charsPerLine is calculated correctly', () {
      final label45 = Sk58CustomLabel(widthMm: 45, heightMm: 30);
      expect(label45.charsPerLine, 30); // 360 / 12

      final label35 = Sk58CustomLabel(widthMm: 35, heightMm: 30);
      expect(label35.charsPerLine, 23); // 280 / 12
    });

    test('gapDots is calculated correctly', () {
      final label = Sk58CustomLabel(widthMm: 40, heightMm: 30, gapMm: 3.0);
      expect(label.gapDots, 24); // 3 * 8
    });
  });

  group('BlackMarkPositions', () {
    test('position A values are correct from manual', () {
      expect(BlackMarkPositions.getPositionA(30), 9.5);
      expect(BlackMarkPositions.getPositionA(40), 14.5);
      expect(BlackMarkPositions.getPositionA(50), 19.5);
      expect(BlackMarkPositions.getPositionA(58), 22.0);
    });

    test('position B is half paper width', () {
      expect(BlackMarkPositions.getPositionB(30), 15.0);
      expect(BlackMarkPositions.getPositionB(40), 20.0);
      expect(BlackMarkPositions.getPositionB(50), 25.0);
      expect(BlackMarkPositions.getPositionB(58), 29.0);
    });
  });
}
