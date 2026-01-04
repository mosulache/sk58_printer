import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('Sk58Label', () {
    test('creates basic label with title only', () {
      final label = Sk58Label(title: 'Test Title');

      expect(label.title, 'Test Title');
      expect(label.subtitle, isNull);
      expect(label.qrData, isNull);
      expect(label.barcodeData, isNull);
    });

    test('creates label with all options', () {
      final label = Sk58Label(
        title: 'Main Title',
        subtitle: 'Subtitle',
        qrData: 'QR-DATA-123',
        titleStyle: Sk58TextStyle.boldStyle,
        qrSize: 8,
        feedAfter: 5,
      );

      expect(label.title, 'Main Title');
      expect(label.subtitle, 'Subtitle');
      expect(label.qrData, 'QR-DATA-123');
      expect(label.qrSize, 8);
      expect(label.feedAfter, 5);
    });

    test('toCommands generates valid commands', () {
      final label = Sk58Label(
        title: 'Test',
        subtitle: 'Sub',
        qrData: 'DATA',
      );

      final commands = label.toCommands();

      // Should not be empty
      expect(commands, isNotEmpty);

      // Should contain alignment commands
      expect(commands, contains(0x1B)); // ESC
      expect(commands, contains(0x61)); // 'a' alignment

      // Should contain text
      expect(commands, containsAllInOrder('Test'.codeUnits));
      expect(commands, containsAllInOrder('Sub'.codeUnits));
    });

    test('toCommands includes QR code when provided', () {
      final label = Sk58Label(
        title: 'Test',
        qrData: 'QR123',
      );

      final commands = label.toCommands();

      // Should contain QR code commands (GS ( k)
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x28)); // (
      expect(commands, contains(0x6B)); // k
    });

    test('toCommands includes barcode when QR not provided', () {
      final label = Sk58Label(
        title: 'Test',
        barcodeData: 'ABC123',
        barcodeType: BarcodeType.code128,
      );

      final commands = label.toCommands();

      // Should contain barcode commands
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x6B)); // k (barcode command)
    });

    test('QR takes priority over barcode', () {
      final label = Sk58Label(
        title: 'Test',
        qrData: 'QR123',
        barcodeData: 'BAR123', // Should be ignored
      );

      final commands = label.toCommands();

      // Should contain QR commands
      expect(commands, contains(0x28)); // ( (QR code marker)
    });

    test('feedAfter adds line feeds', () {
      final label = Sk58Label(title: 'Test', feedAfter: 5);
      final commands = label.toCommands();

      // Count line feeds (0x0A) - should have at least 5 at the end
      final feedCount = commands.where((c) => c == 0x0A).length;
      expect(feedCount, greaterThanOrEqualTo(5));
    });
  });

  group('Sk58TwoColumnLabel', () {
    test('creates label with rows', () {
      final label = Sk58TwoColumnLabel(
        title: 'Info',
        rows: [
          ('Key1', 'Value1'),
          ('Key2', 'Value2'),
        ],
      );

      expect(label.title, 'Info');
      expect(label.rows.length, 2);
      expect(label.rows[0], ('Key1', 'Value1'));
    });

    test('has correct defaults', () {
      final label = Sk58TwoColumnLabel(rows: [('K', 'V')]);

      expect(label.separator, ':');
      expect(label.keyWidth, 12);
      expect(label.lineWidth, 32);
      expect(label.feedAfter, 3);
      expect(label.showTitleSeparator, true);
    });

    test('toCommands generates valid commands', () {
      final label = Sk58TwoColumnLabel(
        title: 'Product',
        rows: [
          ('Type', 'Widget'),
          ('Size', 'Large'),
        ],
      );

      final commands = label.toCommands();

      expect(commands, isNotEmpty);
      // Should contain title
      expect(commands, containsAllInOrder('Product'.codeUnits));
    });

    test('toCommands includes separator line when enabled', () {
      final label = Sk58TwoColumnLabel(
        title: 'Title',
        rows: [('K', 'V')],
        showTitleSeparator: true,
      );

      final commands = label.toCommands();

      // Should contain dashes for separator
      expect(commands, contains(0x2D)); // '-' character
    });

    test('toCommands includes QR when provided', () {
      final label = Sk58TwoColumnLabel(
        rows: [('K', 'V')],
        qrData: 'QR123',
      );

      final commands = label.toCommands();

      // Should contain QR commands
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x28)); // (
      expect(commands, contains(0x6B)); // k
    });

    test('toCommands includes barcode when provided', () {
      final label = Sk58TwoColumnLabel(
        rows: [('K', 'V')],
        barcodeData: 'BAR123',
      );

      final commands = label.toCommands();

      // Should contain barcode commands
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x6B)); // k
    });

    test('formats rows correctly with separator', () {
      final label = Sk58TwoColumnLabel(
        rows: [('Name', 'John')],
        separator: ':',
        keyWidth: 10,
      );

      final commands = label.toCommands();

      // Should contain formatted key with separator and padding
      final nameBytes = 'Name:'.codeUnits;
      expect(commands, containsAllInOrder(nameBytes));
    });

    test('handles empty title', () {
      final label = Sk58TwoColumnLabel(
        title: null,
        rows: [('K', 'V')],
      );

      final commands = label.toCommands();
      expect(commands, isNotEmpty);
    });
  });

  group('Sk58Template', () {
    test('Sk58Label implements Sk58Template', () {
      final label = Sk58Label(title: 'Test');
      expect(label, isA<Sk58Template>());
    });

    test('Sk58TwoColumnLabel implements Sk58Template', () {
      final label = Sk58TwoColumnLabel(rows: [('K', 'V')]);
      expect(label, isA<Sk58Template>());
    });
  });
}
